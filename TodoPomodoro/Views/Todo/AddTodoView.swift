import SwiftUI
import PhotosUI

struct AddTodoView: View {
    let item: TodoItem?
    let onSave: (TodoItem) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Date().addingTimeInterval(86400)
    @State private var selectedImage: UIImage?
    @State private var showCamera = false
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var isImageLoading = false
    
    private var isEditing: Bool { item != nil }
    
    init(item: TodoItem?, onSave: @escaping (TodoItem) -> Void) {
        self.item = item
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.07, green: 0.08, blue: 0.08)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 标题
                        VStack(alignment: .leading, spacing: 6) {
                            Text("标题")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white.opacity(0.6))
                            
                            TextField("输入待办事项", text: $title)
                                .font(.title3)
                                .foregroundStyle(.white)
                                .tint(.orange)
                                .padding()
                                .background(.white.opacity(0.07))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        // 备注
                        VStack(alignment: .leading, spacing: 6) {
                            Text("备注")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white.opacity(0.6))
                            
                            TextField("添加备注...", text: $notes, axis: .vertical)
                                .foregroundStyle(.white)
                                .tint(.orange)
                                .lineLimit(3...6)
                                .padding()
                                .background(.white.opacity(0.07))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        // 截止日期
                        VStack(alignment: .leading, spacing: 10) {
                            Toggle(isOn: $hasDueDate.animation()) {
                                HStack {
                                    Image(systemName: "calendar.badge.clock")
                                        .foregroundStyle(hasDueDate ? .orange : .white.opacity(0.3))
                                    Text("设置截止日期")
                                        .foregroundStyle(.white)
                                }
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .orange))
                            
                            if hasDueDate {
                                DatePicker("截止时间", selection: $dueDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                                    .datePickerStyle(.graphical)
                                    .tint(.orange)
                                    .foregroundStyle(.white)
                                    .background(.white.opacity(0.05))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        
                        // 图片导入
                        VStack(alignment: .leading, spacing: 10) {
                            Text("附件图片")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white.opacity(0.6))
                            
                            HStack(spacing: 12) {
                                // 拍照
                                Button(action: { showCamera = true }) {
                                    imageSourceButton(
                                        icon: "camera.fill",
                                        label: "拍照",
                                        color: .blue
                                    )
                                }
                                
                                // 相册
                                PhotosPicker(selection: $photoPickerItem, matching: .images) {
                                    imageSourceButton(
                                        icon: "photo.on.rectangle.fill",
                                        label: "相册",
                                        color: .green
                                    )
                                }
                                .disabled(isImageLoading)
                                .opacity(isImageLoading ? 0.4 : 1)
                                
                                // 已选图片预览
                                if let image = selectedImage {
                                    Button(action: { selectedImage = nil }) {
                                        ZStack(alignment: .topTrailing) {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 80, height: 80)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                            
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 18))
                                                .foregroundStyle(.red)
                                                .background(Circle().fill(.white))
                                                .offset(x: 6, y: -6)
                                        }
                                    }
                                }
                                
                                Spacer()
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(isEditing ? "编辑待办" : "新建待办")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .foregroundStyle(.white.opacity(0.6))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "保存" : "添加") {
                        save()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(title.trimmed.isEmpty ? .gray : .orange)
                    .disabled(title.trimmed.isEmpty)
                }
            }
            .onAppear {
                if let item = item {
                    title = item.title
                    notes = item.notes
                    hasDueDate = item.hasDueDate
                    dueDate = item.dueDate ?? Date()
                    if let data = item.imageData, let image = UIImage(data: data) {
                        selectedImage = image
                    }
                }
            }
            .onChange(of: photoPickerItem) { _, newItem in
                guard let newItem else { return }
                isImageLoading = true
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            selectedImage = image
                        }
                    }
                    await MainActor.run {
                        isImageLoading = false
                        photoPickerItem = nil
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker(sourceType: .camera, selectedImage: $selectedImage)
                    .ignoresSafeArea()
            }
        }
    }
    
    private func imageSourceButton(icon: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.16))
                    .frame(width: 80, height: 80)
                
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(color)
            }
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
        }
    }
    
    private func save() {
        let newItem = TodoItem(
            id: item?.id ?? UUID(),
            title: title.trimmed,
            notes: notes.trimmed,
            dueDate: hasDueDate ? dueDate : nil,
            hasDueDate: hasDueDate,
            isCompleted: item?.isCompleted ?? false,
            createdAt: item?.createdAt ?? Date(),
            imageData: selectedImage?.jpegData(compressionQuality: 0.8),
            imageFilename: selectedImage != nil ? item?.imageFilename ?? "image_\(UUID().uuidString).jpg" : nil
        )
        onSave(newItem)
        dismiss()
    }
}

// MARK: - ImagePicker (相机)
struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Helper
extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
