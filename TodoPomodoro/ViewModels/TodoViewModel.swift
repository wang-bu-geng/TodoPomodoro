import Foundation
import SwiftUI
import Combine

class TodoViewModel: ObservableObject {
    @Published var items: [TodoItem] = []
    @Published var searchText = ""
    @Published var filterOption: FilterOption = .all
    
    enum FilterOption: String, CaseIterable {
        case all = "全部"
        case today = "今天"
        case upcoming = "待办"
        case completed = "已完成"
        case overdue = "已过期"
    }
    
    private let saveKey = "todos"
    
    init() {
        loadItems()
        if items.isEmpty {
            // 添加示例数据
            addSampleData()
        }
    }
    
    var filteredItems: [TodoItem] {
        let filtered: [TodoItem]
        switch filterOption {
        case .all:
            filtered = items
        case .today:
            filtered = items.filter { $0.isDueToday }
        case .upcoming:
            filtered = items.filter { !$0.isCompleted }
        case .completed:
            filtered = items.filter { $0.isCompleted }
        case .overdue:
            filtered = items.filter { $0.isOverdue }
        }
        
        if searchText.isEmpty {
            return filtered.sorted { $0.createdAt > $1.createdAt }
        } else {
            return filtered.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
                .sorted { $0.createdAt > $1.createdAt }
        }
    }
    
    var statsText: String {
        let total = items.count
        let completed = items.filter { $0.isCompleted }.count
        let overdue = items.filter { $0.isOverdue }.count
        return "总计 \(total) | 已完成 \(completed) | 过期 \(overdue)"
    }
    
    func addItem(_ item: TodoItem) {
        items.insert(itemReadyForMemory(item, replacing: nil), at: 0)
        saveItems()
    }
    
    func updateItem(_ item: TodoItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index] = itemReadyForMemory(item, replacing: items[index])
        saveItems()
    }
    
    func toggleCompletion(_ item: TodoItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isCompleted.toggle()
        saveItems()
    }
    
    func deleteItem(_ item: TodoItem) {
        TodoImageStore.delete(filename: item.imageFilename)
        items.removeAll { $0.id == item.id }
        saveItems()
    }
    
    func deleteItems(at offsets: IndexSet, from filteredList: [TodoItem]) {
        let ids = offsets.map { filteredList[$0].id }
        items
            .filter { ids.contains($0.id) }
            .forEach { TodoImageStore.delete(filename: $0.imageFilename) }
        items.removeAll { ids.contains($0.id) }
        saveItems()
    }
    
    private func saveItems() {
        let persistedItems = items.map { item -> TodoItem in
            var copy = item
            copy.imageData = nil
            return copy
        }
        
        if let encoded = try? JSONEncoder().encode(persistedItems) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadItems() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) {
            items = decoded.map { itemReadyForMemory($0, replacing: nil) }
        }
    }
    
    private func addSampleData() {
        let samples = [
            TodoItem(title: "设计 App 原型", notes: "在 Figma 中完成主界面设计", dueDate: Date().addingTimeInterval(86400), hasDueDate: true),
            TodoItem(title: "阅读《SwiftUI 进阶》", notes: "第 3-5 章"),
            TodoItem(title: "提交周报", dueDate: Date().addingTimeInterval(172800), hasDueDate: true, isCompleted: true),
            TodoItem(title: "健身 30 分钟"),
        ]
        items = samples
        saveItems()
    }
    
    private func itemReadyForMemory(_ item: TodoItem, replacing oldItem: TodoItem?) -> TodoItem {
        var mutable = item
        
        if let data = item.imageData {
            let filename = TodoImageStore.save(data: data, preferredFilename: item.imageFilename ?? oldItem?.imageFilename)
            mutable.imageFilename = filename
        } else if let filename = item.imageFilename {
            mutable.imageData = TodoImageStore.load(filename: filename)
        } else {
            TodoImageStore.delete(filename: oldItem?.imageFilename)
        }
        
        return mutable
    }
}

extension TodoItem {
    var isDueToday: Bool {
        guard let date = dueDate, hasDueDate else { return false }
        return Calendar.current.isDateInToday(date)
    }
}

private enum TodoImageStore {
    private static var directoryURL: URL? {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        return appSupport.appendingPathComponent("TodoPomodoro/TodoImages", isDirectory: true)
    }
    
    static func save(data: Data, preferredFilename: String?) -> String? {
        guard let directoryURL else { return preferredFilename }
        do {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            let filename = preferredFilename ?? "image_\(UUID().uuidString).jpg"
            try data.write(to: directoryURL.appendingPathComponent(filename), options: .atomic)
            return filename
        } catch {
            return preferredFilename
        }
    }
    
    static func load(filename: String) -> Data? {
        guard let directoryURL else { return nil }
        return try? Data(contentsOf: directoryURL.appendingPathComponent(filename))
    }
    
    static func delete(filename: String?) {
        guard let filename, let directoryURL else { return }
        try? FileManager.default.removeItem(at: directoryURL.appendingPathComponent(filename))
    }
}
