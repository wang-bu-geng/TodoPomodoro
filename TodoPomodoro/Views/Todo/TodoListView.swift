import SwiftUI

struct TodoListView: View {
    @EnvironmentObject var vm: TodoViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var pomodoroVM: PomodoroViewModel
    @Binding var selectedTab: Int
    @State private var showAddSheet = false
    @State private var editingItem: TodoItem?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 主题背景（全屏统一渲染）
                BackgroundView(settings: settingsVM)
                    .ignoresSafeArea()
                Color.black.opacity(0.10)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 过滤标签
                    filterBar
                    
                    // 统计
                    HStack {
                        Text(vm.statsText)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.45))
                        Spacer()
                        Text("\(visibleItems.count) 项")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    
                    if visibleItems.isEmpty {
                        emptyState
                    } else {
                        todoList
                    }
                }
                .navigationTitle("待办事项")
                .navigationBarTitleDisplayMode(.large)
                .searchable(text: $vm.searchText, prompt: "搜索待办")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { showAddSheet = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 34, height: 34)
                                .background(.orange)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .sheet(isPresented: $showAddSheet) {
                    AddTodoView(item: nil) { newItem in
                        vm.addItem(newItem)
                    }
                }
                .sheet(item: $editingItem) { item in
                    AddTodoView(item: item) { updatedItem in
                        vm.updateItem(updatedItem)
                    }
                }
            }
        }
    }
    
    // MARK: - 过滤栏
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TodoViewModel.FilterOption.allCases, id: \.self) { option in
                    Button(action: { vm.filterOption = option }) {
                        Text(option.rawValue)
                            .font(.subheadline)
                            .fontWeight(vm.filterOption == option ? .semibold : .regular)
                            .foregroundStyle(vm.filterOption == option ? .white : .white.opacity(0.5))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(vm.filterOption == option ? .white.opacity(0.14) : .white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - 空状态
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checklist")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.2))
            Text("还没有待办事项")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.62))
            Text("添加一个任务，然后从详情页开始专注")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.38))
            Spacer()
        }
    }
    
    // MARK: - 待办列表
    private var todoList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(Array(visibleItems.enumerated()), id: \.element.id) { index, item in
                    todoCard(item, index: index)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            // 左滑显示编辑按钮
                            Button {
                                editingItem = item
                            } label: {
                                Label("编辑", systemImage: "pencil")
                            }
                            .tint(.orange)
                            
                            // 删除
                            Button(role: .destructive) {
                                vm.deleteItem(item)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            // 右滑快速完成
                            Button {
                                vm.toggleCompletion(item)
                            } label: {
                                Label(item.isCompleted ? "取消完成" : "完成", systemImage: "checkmark.circle")
                            }
                            .tint(.green)
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
    
    private func todoCard(_ item: TodoItem, index: Int) -> some View {
        NavigationLink(destination: TodoDetailView(item: item, selectedTab: $selectedTab, pomodoroVM: pomodoroVM)) {
            HStack(spacing: 12) {
                // 完成按钮
                Button(action: { vm.toggleCompletion(item) }) {
                    ZStack {
                        Circle()
                            .stroke(
                                item.isCompleted ? Color.green : item.isOverdue ? Color.red.opacity(0.5) : .white.opacity(0.3),
                                lineWidth: 2
                            )
                            .frame(width: 24, height: 24)
                        
                        if item.isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.green)
                        }
                    }
                }
                .buttonStyle(.plain)
                
                // 内容
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .strikethrough(item.isCompleted)
                        .opacity(item.isCompleted ? 0.5 : 1)
                    
                    if item.hasDueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                            Text(item.dueDateString)
                                .font(.caption)
                        }
                        .foregroundStyle(item.dueDateColor.opacity(item.isCompleted ? 0.45 : 0.9))
                    }
                    
                    if !item.notes.isEmpty {
                        Text(item.notes)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // 图片指示
                if item.imageData != nil {
                    Image(systemName: "photo.fill")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.3))
                }
                
                // 展开箭头
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.18))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.white.opacity(item.isCompleted ? 0.045 : 0.075))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(item.isOverdue ? Color.red.opacity(0.35) : .white.opacity(0.06), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.9)),
            removal: .opacity.combined(with: .move(edge: .trailing))
        ))
    }
    
    private var visibleItems: [TodoItem] {
        if settingsVM.showCompletedTodos || vm.filterOption == .completed {
            return vm.filteredItems
        }
        return vm.filteredItems.filter { !$0.isCompleted }
    }
}
