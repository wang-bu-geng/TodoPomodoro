import SwiftUI

struct TodoDetailView: View {
    @EnvironmentObject var vm: TodoViewModel
    let item: TodoItem
    @Binding var selectedTab: Int
    let pomodoroVM: PomodoroViewModel
    
    @State private var showEditSheet = false
    @State private var showDeleteConfirm = false
    @Environment(\.dismiss) private var dismiss
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastIcon = ""
    @State private var isCompleted: Bool
    @State private var showImageViewer = false
    
    init(item: TodoItem, selectedTab: Binding<Int>, pomodoroVM: PomodoroViewModel) {
        self.item = item
        self._selectedTab = selectedTab
        self.pomodoroVM = pomodoroVM
        self._isCompleted = State(initialValue: item.isCompleted)
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.08)
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // MARK: - ① 图片区 — 点击查看大图
                    if let data = item.imageData, let uiImage = UIImage(data: data) {
                        Button(action: { showImageViewer = true }) {
                            ZStack(alignment: .bottomTrailing) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 320)
                                    .clipped()
                                    .overlay(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.clear, .black.opacity(0.6)]),
                                            startPoint: .center,
                                            endPoint: .bottom
                                        )
                                    )
                                
                                // 图片标签
                                HStack(spacing: 6) {
                                    Image(systemName: "photo")
                                        .font(.caption2)
                                    Text("附件")
                                        .font(.caption2)
                                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                                        .font(.caption2)
                                }
                                .foregroundStyle(.white.opacity(0.7))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 7))
                                .padding(16)
                            }
                            .frame(maxWidth: .infinity)
                            .clipShape(
                                .rect(
                                    topLeadingRadius: 0,
                                    bottomLeadingRadius: 10,
                                    bottomTrailingRadius: 10,
                                    topTrailingRadius: 0
                                )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    VStack(spacing: 24) {
                        // MARK: - 标题 + 完成按钮
                        HStack(alignment: .center, spacing: 14) {
                            Button(action: toggleComplete) {
                                ZStack {
                                    Circle()
                                        .stroke(
                                            isCompleted ? Color.green : .white.opacity(0.3),
                                            lineWidth: 2.5
                                        )
                                        .frame(width: 44, height: 44)
                                    
                                    if isCompleted {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 44, weight: .bold))
                                            .foregroundStyle(.green)
                                    }
                                }
                            }
                            .sensoryFeedback(.success, trigger: isCompleted)
                            
                            Text(item.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .strikethrough(isCompleted)
                                .opacity(isCompleted ? 0.6 : 1)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, item.imageData != nil ? 8 : 24)
                        
                        // MARK: - ② 截止日期卡片 + 进度条
                        if item.hasDueDate, let dueDate = item.dueDate {
                            VStack(spacing: 8) {
                                // 日期卡片
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(item.dueDateColor.opacity(0.15))
                                            .frame(width: 44, height: 44)
                                        
                                        Image(systemName: item.isOverdue ? "exclamationmark.triangle.fill" : "calendar")
                                            .font(.system(size: 18))
                                            .foregroundStyle(item.dueDateColor)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.isOverdue ? "已过期" : "截止")
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.4))
                                        
                                        Text(dueDate.formatted(date: .long, time: .shortened))
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundStyle(item.isOverdue ? .red : .white)
                                    }
                                    
                                    Spacer()
                                    
                                    if !isCompleted {
                                        Text(relativeDate(dueDate))
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(item.dueDateColor)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(item.dueDateColor.opacity(0.15))
                                            .clipShape(RoundedRectangle(cornerRadius: 7))
                                    }
                                }
                                .padding(14)
                                .background(.white.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                // 进度条 — 4pt 原生风格
                                if !isCompleted {
                                    DueDateProgressBar(
                                        progress: dueDateProgress,
                                        color: dueDateProgressColor,
                                        timeLabel: dueDateTimeLabel
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // MARK: - 开始专注按钮
                        Button(action: startFocus) {
                            HStack(spacing: 10) {
                                Image(systemName: "timer")
                                    .font(.system(size: 16))
                                Text("开始专注")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.orange)
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // MARK: - 备注
                        if !item.notes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("备注", systemImage: "note.text")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white.opacity(0.5))
                                
                                Text(item.notes)
                                    .font(.body)
                                    .foregroundStyle(.white.opacity(0.85))
                                    .lineSpacing(6)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(16)
                            .background(.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .padding(.horizontal, 20)
                        }
                        
                        // MARK: - 底部操作区
                        VStack(spacing: 12) {
                            Button(role: .destructive) {
                                showDeleteConfirm = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 14))
                                    Text("删除任务")
                                        .font(.subheadline)
                                }
                                .foregroundStyle(.red.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(.white.opacity(0.04))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            
                            Text("创建于 \(item.createdAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.25))
                                .padding(.bottom, 4)
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            
            // MARK: - Toast 提示层
            if showToast {
                VStack {
                    Spacer()
                    HStack(spacing: 10) {
                        Image(systemName: toastIcon)
                            .font(.title3)
                        Text(toastMessage)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
                    .padding(.bottom, 100)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showToast)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showEditSheet = true }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            AddTodoView(item: item) { updatedItem in
                var mutable = updatedItem
                mutable.isCompleted = isCompleted
                vm.updateItem(mutable)
                showEditSheet = false
            }
        }
        .alert("确认删除", isPresented: $showDeleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                vm.deleteItem(item)
                dismiss()
            }
        } message: {
            Text("确定要删除「\(item.title)」吗？此操作不可撤销。")
        }
        // ① 全屏图片查看器
        .fullScreenCover(isPresented: $showImageViewer) {
            if let data = item.imageData, let uiImage = UIImage(data: data) {
                ImageViewer(image: uiImage)
            }
        }
    }
    
    // MARK: - 完成/取消完成
    private func toggleComplete() {
        isCompleted.toggle()
        var updated = item
        updated.isCompleted = isCompleted
        vm.updateItem(updated)
        
        if isCompleted {
            toastIcon = "sparkles"
            toastMessage = "任务已完成"
            withAnimation { showToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation { showToast = false }
            }
        }
    }
    
    // MARK: - 开始专注
    private func startFocus() {
        pomodoroVM.startFocusFromDetail(taskTitle: item.title)
        dismiss()
    }
    
    // MARK: - 相对时间
    private func relativeDate(_ date: Date) -> String {
        let diff = Calendar.current.dateComponents([.day, .hour], from: Date(), to: date)
        if let days = diff.day, days > 0 { return "\(days) 天" }
        if let hours = diff.hour, hours > 0 { return "\(hours) 小时" }
        return "不到 1 小时"
    }
    
    // MARK: - ② 进度条计算
    
    /// 剩余时间比例（7天=100%，已过期=0%）
    private var dueDateProgress: Double {
        guard let dueDate = item.dueDate else { return 0 }
        let remaining = dueDate.timeIntervalSinceNow
        let maxSeconds: TimeInterval = 7 * 24 * 3600
        return min(max(remaining / maxSeconds, 0), 1)
    }
    
    /// 进度条颜色（豆包审计精确色值）
    private var dueDateProgressColor: Color {
        guard let dueDate = item.dueDate, !item.isCompleted else { return Color(red: 142/255, green: 142/255, blue: 147/255) }
        if item.isOverdue { return Color(red: 142/255, green: 142/255, blue: 147/255) }
        let remaining = dueDate.timeIntervalSinceNow
        if remaining > 7 * 24 * 3600 { return Color(red: 52/255, green: 199/255, blue: 89/255) }  // 绿色
        if remaining > 3 * 24 * 3600 { return Color(red: 255/255, green: 204/255, blue: 0/255) }  // 黄色
        if remaining > 24 * 3600 { return Color(red: 255/255, green: 149/255, blue: 0/255) }      // 橙色
        return Color(red: 255/255, green: 59/255, blue: 48/255)                                   // 红色
    }
    
    /// 进度条时间标签文字
    private var dueDateTimeLabel: String {
        guard let dueDate = item.dueDate else { return "" }
        if item.isOverdue { return "已过期" }
        let remaining = dueDate.timeIntervalSinceNow
        if remaining > 7 * 24 * 3600 {
            let days = Int(remaining / (24 * 3600))
            return "剩余 \(days) 天"
        }
        if remaining > 24 * 3600 {
            let days = Int(remaining / (24 * 3600))
            let hours = Int((remaining.truncatingRemainder(dividingBy: 24 * 3600)) / 3600)
            return "剩余 \(days) 天 \(hours) 小时"
        }
        if remaining > 3600 {
            let hours = Int(remaining / 3600)
            let mins = Int((remaining.truncatingRemainder(dividingBy: 3600)) / 60)
            return "剩余 \(hours) 小时 \(mins) 分钟"
        }
        if remaining > 0 {
            let mins = max(1, Int(remaining / 60))
            return "剩余 \(mins) 分钟"
        }
        return "已过期"
    }
}

// MARK: - ② 截止日期进度条（4pt 高，2pt 圆角）

struct DueDateProgressBar: View {
    let progress: Double     // 0.0...1.0
    let color: Color
    let timeLabel: String
    
    var body: some View {
        VStack(spacing: 6) {
            // 进度条
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // 背景
                    Capsule()
                        .fill(.white.opacity(0.2))
                        .frame(height: 4)
                    
                    // 填充
                    Capsule()
                        .fill(color)
                        .frame(width: max(4, geo.size.width * progress), height: 4)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 4)
            
            // 时间标签
            HStack {
                Text(timeLabel)
                    .font(.caption2)
                    .foregroundStyle(color)
                Spacer()
            }
        }
    }
}

// MARK: - ① 全屏图片查看器（原生交互：缩放+拖动+下滑关闭）

struct ImageViewer: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var dragOffset: CGSize = .zero
    
    private let maxScale: CGFloat = 3.0
    private let dragDismissThreshold: CGFloat = 0.33
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 背景色 — 随下滑透明度渐变
                Color.black.opacity(backgroundOpacity)
                    .ignoresSafeArea()
                
                // 图片
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(x: offset.width + dragOffset.width,
                            y: offset.height + dragOffset.height)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let newScale = value
                                scale = min(max(newScale, 1.0), maxScale)
                            }
                            .onEnded { _ in
                                if scale < 1.0 {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        scale = 1.0
                                        offset = .zero
                                    }
                                }
                                // 如果缩放后超出边界，上弹回正
                                let maxOffsetX = max(0, (geo.size.width * scale - geo.size.width) / 2)
                                let maxOffsetY = max(0, (geo.size.height * scale - geo.size.height) / 2)
                                withAnimation(.spring()) {
                                    offset.width = min(max(offset.width, -maxOffsetX), maxOffsetX)
                                    offset.height = min(max(offset.height, -maxOffsetY), maxOffsetY)
                                }
                            }
                    )
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                if scale > 1.0 {
                                    // 缩放状态：平移图片
                                    offset = CGSize(
                                        width: value.translation.width,
                                        height: value.translation.height
                                    )
                                } else {
                                    // 正常状态：下滑关闭
                                    dragOffset = value.translation
                                }
                            }
                            .onEnded { value in
                                if scale > 1.0 {
                                    // 缩放状态：限制边界
                                    let maxOffsetX = max(0, (geo.size.width * scale - geo.size.width) / 2)
                                    let maxOffsetY = max(0, (geo.size.height * scale - geo.size.height) / 2)
                                    withAnimation(.spring()) {
                                        offset.width = min(max(offset.width, -maxOffsetX), maxOffsetX)
                                        offset.height = min(max(offset.height, -maxOffsetY), maxOffsetY)
                                    }
                                } else {
                                    // 正常状态：下滑超过阈值则关闭
                                    if abs(value.translation.height) > geo.size.height * dragDismissThreshold {
                                        dismiss()
                                    } else {
                                        withAnimation(.spring()) {
                                            dragOffset = .zero
                                        }
                                    }
                                }
                            }
                    )
                
                // 右上角「完成」按钮
                VStack {
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Text("完成")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 8)
                                .background(.white.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 12)
                    }
                    Spacer()
                }
            }
        }
        .statusBarHidden()
    }
    
    /// 根据下滑距离控制背景透明度
    private var backgroundOpacity: Double {
        let progress = abs(dragOffset.height) / 300
        return Double(max(0.4, 1.0 - progress))
    }
}
