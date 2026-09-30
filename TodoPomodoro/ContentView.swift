import SwiftUI

struct ContentView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var pomodoroVM: PomodoroViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            PomodoroView()
                .tabItem {
                    Label("番茄钟", systemImage: selectedTab == 0 ? "timer.circle.fill" : "timer.circle")
                }
                .tag(0)
            
            TodoListView(selectedTab: $selectedTab)
                .tabItem {
                    Label("待办", systemImage: selectedTab == 1 ? "checklist.checked" : "checklist")
                }
                .tag(1)
        }
        .tint(.white)
        .preferredColorScheme(.dark)
        .onChange(of: pomodoroVM.focusRequestedFromDetail) { requested in
            if requested {
                selectedTab = 0
                pomodoroVM.focusRequestedFromDetail = false
            }
        }
    }
}

// MARK: - 背景组件
/// 纯色 / 渐变 / 图片，由每个 Tab 各自在底层统一渲染
///
/// 三层结构（豆包审计建议）：
///   ⬛ 最底层：固定黑色（兜底，防止闪白）
///   🖼️ 中间层：图片 / 纯色 / 渐变（所有切换在此发生，交叉淡入）
///   🌫️ 最上层：固定半透明遮罩（alpha=0.5，永远不动，防止遮罩不同步）
///
/// 图片切换使用交叉淡入（cross-fade），根治闪白 / 闪黑 / 旧图残留
/// 图片解码在子线程进行，并缓存最近 5 张解码后的图片
/// 切换时有 400ms 防抖锁，防止快速点击导致混乱
struct BackgroundView: View {
    @ObservedObject var settings: SettingsViewModel
    
    // MARK: - 图片切换状态
    @State private var currentImage: UIImage?       // 当前显示的已解码图片
    @State private var fadingImage: UIImage?        // 正在淡出的旧图
    @State private var fadeOpacity: Double = 0      // 旧图透明度（1→0）
    @State private var isTransitioning = false       // 防抖锁
    @State private var loadingTask: Task<Void, Never>?
    
    // MARK: - LRU 图片缓存（最多 5 张，总上限 50MB）
    private static let imageCache: NSCache<NSData, UIImage> = {
        let cache = NSCache<NSData, UIImage>()
        cache.countLimit = 5
        cache.totalCostLimit = 50 * 1024 * 1024
        return cache
    }()
    
    var body: some View {
        ZStack {
            // ⬛ 第一层：黑色兜底（防止任何情况下出现白边 / 闪白）
            Color.black
                .ignoresSafeArea()
            
            // 🖼️ 第二层：纯色 / 渐变 / 图片
            switch settings.backgroundStyle {
            case .solid:
                settings.solidColor
                    .ignoresSafeArea()
                
            case .gradient:
                LinearGradient(
                    gradient: Gradient(colors: [settings.gradientStart, settings.gradientEnd]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
            case .image:
                ZStack {
                    // 正在淡出的旧图（在顶层淡出）
                    if let oldImage = fadingImage {
                        Image(uiImage: oldImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipped()
                            .opacity(fadeOpacity)
                    }
                    
                    // 当前显示的新图
                    if let newImage = currentImage {
                        Image(uiImage: newImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipped()
                    }
                }
                .ignoresSafeArea()
            }
            
            // 固定半透明遮罩，保持文字对比度
            Color.black.opacity(settings.backgroundStyle == .image ? 0.46 : 0.18)
                .ignoresSafeArea()
            
            LinearGradient(
                colors: [.black.opacity(0.15), .clear, .black.opacity(0.28)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // 模糊层
            if settings.blurRadius > 0 {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(min(settings.blurRadius / 24, 0.45))
                    .ignoresSafeArea()
            }
        }
        .animation(.easeInOut(duration: 0.8), value: settings.backgroundStyle)
        .animation(.easeInOut(duration: 0.8), value: settings.gradientStart)
        .animation(.easeInOut(duration: 0.8), value: settings.gradientEnd)
        // 图片切换单独处理（交叉淡入）
        .onChange(of: settings.backgroundImageData) { _, newData in
            handleImageChange(data: newData)
        }
    }
    
    // MARK: - 图片切换处理
    
    private func handleImageChange(data: Data?) {
        // 防抖锁：动画进行中忽略新请求
        guard !isTransitioning else { return }
        // 取消之前的加载任务
        loadingTask?.cancel()
        
        guard let data = data else {
            // 清除图片（切换回纯色/渐变时自然过渡）
            withAnimation(.easeInOut(duration: 0.3)) {
                currentImage = nil
            }
            return
        }
        
        let nsData = data as NSData
        
        // 先检查缓存
        if let cached = Self.imageCache.object(forKey: nsData) {
            startCrossFade(to: cached)
            return
        }
        
        // 后台解码 + 压缩
        loadingTask = Task.detached(priority: .userInitiated) {
            guard !Task.isCancelled else { return }
            
            guard let original = UIImage(data: data) else { return }
            
            // 压缩：最长边 1080px，JPEG 质量 80%
            let compressed = UIImage.downsample(image: original, maxDimension: 1080)
            let finalImage: UIImage
            if let jpegData = compressed.jpegData(compressionQuality: 0.8),
               let jpegImage = UIImage(data: jpegData) {
                finalImage = jpegImage
            } else {
                finalImage = compressed
            }
            
            // 缓存
            Self.imageCache.setObject(finalImage, forKey: nsData)
            
            await MainActor.run {
                guard !Task.isCancelled else { return }
                startCrossFade(to: finalImage)
            }
        }
    }
    
    /// 交叉淡入切换：旧图透明淡出 + 新图直接显示（利用 SwiftUI 的 ZStack 层级）
    private func startCrossFade(to newImage: UIImage) {
        isTransitioning = true
        
        // 把当前图设为「淡出图」
        fadingImage = currentImage
        fadeOpacity = 1.0
        
        // 立即显示新图（在新图层上，opacity=1）
        currentImage = newImage
        
        // 交叉淡入：新图在下层全程 opacity=1，旧图在顶层从 1→0 渐隐
        withAnimation(.easeInOut(duration: 0.3)) {
            fadeOpacity = 0.0
        }
        
        // 动画完成后清理 + 释放防抖锁（300ms 动画 + 100ms 收尾 = 400ms 防抖）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            fadingImage = nil
            isTransitioning = false
        }
    }
}

// MARK: - UIImage 缩放工具
extension UIImage {
    /// 保持比例缩放到最长边不超过 maxDimension（不放大）
    static func downsample(image: UIImage, maxDimension: CGFloat) -> UIImage {
        let widthRatio = maxDimension / image.size.width
        let heightRatio = maxDimension / image.size.height
        let scale = min(widthRatio, heightRatio, 1.0) // 不放大
        
        let newSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
