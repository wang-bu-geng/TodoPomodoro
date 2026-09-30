import SwiftUI
import PhotosUI

struct SettingsView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var pomodoroVM: PomodoroViewModel
    @State private var showPhotoPicker = false
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var isImageLoading = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 主题背景（全屏统一渲染）
                BackgroundView(settings: settingsVM)
                    .ignoresSafeArea()
                Color.black.opacity(0.10)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - 背景主题
                        settingsSection("背景主题", icon: "paintpalette.fill") {
                            // 风格切换
                            Picker("风格", selection: $settingsVM.backgroundStyle) {
                                Text("纯色").tag(BackgroundStyle.solid)
                                Text("渐变").tag(BackgroundStyle.gradient)
                                Text("图片").tag(BackgroundStyle.image)
                            }
                            .pickerStyle(.segmented)
                            
                            // 内容根据风格切换
                            switch settingsVM.backgroundStyle {
                            case .solid:
                                colorGrid
                            case .gradient:
                                gradientGrid
                            case .image:
                                imagePickerSection
                            }
                            
                            // 模糊滑块
                            VStack(spacing: 8) {
                                HStack {
                                    Image(systemName: "drop.degreeslash")
                                        .foregroundStyle(.white.opacity(0.4))
                                    Text("模糊")
                                        .foregroundStyle(.white.opacity(0.6))
                                    Spacer()
                                    Text("\(Int(settingsVM.blurRadius))")
                                        .foregroundStyle(.white.opacity(0.4))
                                        .font(.caption)
                                }
                                Slider(value: $settingsVM.blurRadius, in: 0...20, step: 1)
                                    .tint(.white.opacity(0.5))
                            }
                            .padding(.top, 8)
                        }
                        
                        // MARK: - 番茄钟设置
                        settingsSection("番茄钟设置", icon: "timer") {
                            VStack(spacing: 12) {
                                HStack {
                                    Text("专注时长")
                                    Spacer()
                                    stepperValue("\(pomodoroVM.focusMinutes)", value: $pomodoroVM.focusMinutes, range: 1...60)
                                }
                                
                                Divider().overlay(.white.opacity(0.1))
                                
                                HStack {
                                    Text("短休息")
                                    Spacer()
                                    stepperValue("\(pomodoroVM.shortBreakMinutes)", value: $pomodoroVM.shortBreakMinutes, range: 1...30)
                                }
                                
                                Divider().overlay(.white.opacity(0.1))
                                
                                HStack {
                                    Text("长休息")
                                    Spacer()
                                    stepperValue("\(pomodoroVM.longBreakMinutes)", value: $pomodoroVM.longBreakMinutes, range: 1...30)
                                }
                                
                                Divider().overlay(.white.opacity(0.1))
                                
                                HStack {
                                    Text("长休息间隔")
                                    Spacer()
                                    HStack {
                                        Button(action: { if pomodoroVM.sessionsBeforeLongBreak > 2 { pomodoroVM.sessionsBeforeLongBreak -= 1 } }) {
                                            minusButton
                                        }
                                        Text("\(pomodoroVM.sessionsBeforeLongBreak) 轮")
                                            .font(.subheadline)
                                            .foregroundStyle(.white)
                                            .frame(minWidth: 70)
                                        Button(action: { if pomodoroVM.sessionsBeforeLongBreak < 10 { pomodoroVM.sessionsBeforeLongBreak += 1 } }) {
                                            plusButton
                                        }
                                    }
                                }
                            }
                        }
                        
                        // MARK: - 待办设置
                        settingsSection("待办设置", icon: "checklist") {
                            Toggle(isOn: $settingsVM.showCompletedTodos) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("显示已完成任务")
                                        .foregroundStyle(.white)
                                    Text("关闭后，列表会自动收起已完成项")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.45))
                                }
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .orange))
                        }
                        
                        // MARK: - 关于
                        settingsSection("关于", icon: "info.circle") {
                            VStack(spacing: 8) {
                                HStack {
                                    Text("版本")
                                    Spacer()
                                    Text("1.0.0")
                                        .foregroundStyle(.white.opacity(0.4))
                                }
                                HStack {
                                    Text("开发者")
                                    Spacer()
                                    Text("王不更")
                                        .foregroundStyle(.orange.opacity(0.8))
                                }
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.large)
            .onChange(of: photoPickerItem) { _, newItem in
                guard let newItem else { return }
                isImageLoading = true
                Task {
                    // 从 PhotosPicker 加载原始数据
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        await MainActor.run {
                            settingsVM.backgroundImageData = data
                        }
                    }
                    await MainActor.run {
                        isImageLoading = false
                        // 重置选择状态，允许重新选择同一张照片
                        photoPickerItem = nil
                    }
                }
            }
        }
    }
    
    // MARK: - 纯色网格
    private var colorGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
            ForEach(settingsVM.presetColors.indices, id: \.self) { index in
                Button(action: { settingsVM.applyColor(index) }) {
                    VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 8)
                            .fill(settingsVM.presetColors[index].color)
                            .frame(height: 60)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(isSelectedColorIndex(index) ? 0.6 : 0.1), lineWidth: 2)
                                    )
                        Text(settingsVM.presetColors[index].name)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
        }
    }
    
    // MARK: - 渐变网格
    private var gradientGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
            ForEach(settingsVM.presetGradients.indices, id: \.self) { index in
                Button(action: { settingsVM.applyGradient(index) }) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [settingsVM.presetGradients[index].start, settingsVM.presetGradients[index].end]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                }
            }
        }
    }
    
    // MARK: - 图片选择
    private var imagePickerSection: some View {
        VStack(spacing: 12) {
            PhotosPicker(selection: $photoPickerItem, matching: .images) {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title2)
                    Text("从相册选择背景")
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .disabled(isImageLoading)
            .opacity(isImageLoading ? 0.5 : 1)
            
            if isImageLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(.white)
                    Text("加载图片中...")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .frame(height: 160)
                .frame(maxWidth: .infinity)
                .background(.white.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            if let data = settingsVM.backgroundImageData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(alignment: .topTrailing) {
                        Button(action: { settingsVM.backgroundImageData = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.red)
                                .background(Circle().fill(.white))
                                .padding(8)
                        }
                    }
            }
        }
    }
    
    // MARK: - Helpers
    private func settingsSection(_ title: String, icon: String, @ViewBuilder content: @escaping () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(.orange.opacity(0.8))
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            
            content()
                .padding(16)
                .background(.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private func stepperValue(_ text: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack(spacing: 8) {
            Button(action: { if value.wrappedValue > range.lowerBound { value.wrappedValue -= 1 } }) {
                minusButton
            }
            Text("\(text) 分钟")
                .font(.subheadline)
                .foregroundStyle(.white)
                .frame(minWidth: 70)
            Button(action: { if value.wrappedValue < range.upperBound { value.wrappedValue += 1 } }) {
                plusButton
            }
        }
    }
    
    private var minusButton: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7)
                .fill(.white.opacity(0.08))
                .frame(width: 30, height: 30)
            Image(systemName: "minus")
                .font(.caption)
                .foregroundStyle(.white)
        }
    }
    
    private var plusButton: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7)
                .fill(.white.opacity(0.08))
                .frame(width: 30, height: 30)
            Image(systemName: "plus")
                .font(.caption)
                .foregroundStyle(.white)
        }
    }
    
    /// 通过索引比较选中的纯色，避免 UIColor.cgColor.components 为 nil
    private func isSelectedColorIndex(_ index: Int) -> Bool {
        guard index < settingsVM.presetColors.count else { return false }
        let color = settingsVM.presetColors[index].color
        return UIColor(color).cgColor == UIColor(settingsVM.solidColor).cgColor
    }
}
