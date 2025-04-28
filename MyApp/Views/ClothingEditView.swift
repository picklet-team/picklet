import SwiftUI
import SDWebImageSwiftUI

struct EditableClothingImage: Identifiable {
    let id: UUID
    var imageUrl: String?
    var localImage: UIImage?
}

struct ClothingEditView: View {
    @EnvironmentObject var viewModel: ClothingViewModel
    @Environment(\.dismiss) var dismiss
    @Binding var clothing: Clothing
  
    let openPhotoPickerOnAppear: Bool
    let canDelete: Bool
    let isNew: Bool

    @State private var showPhotoPicker = false
    @State private var showDeleteConfirm = false
  
    @State private var editableImages: [EditableClothingImage] = []
    @State private var selectedEditableImage: EditableClothingImage? = nil
    @State private var selectedImageForCrop: UIImage? = nil
    @State private var showCropView = false

    var body: some View {
        VStack {
            Form {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(editableImages) { editableImage in
                            Button {
                                Task {
                                    if let loadedImage = await loadUIImageFromEditable(editableImage) {
                                        selectedEditableImage = editableImage
                                        selectedImageForCrop = loadedImage
                                        showCropView = true
                                    }
                                }
                            } label: {
                                if let urlString = editableImage.imageUrl, let url = URL(string: urlString) {
                                    WebImage(url: url, options: [.queryMemoryData, .queryDiskDataSync, .refreshCached])
                                        .resizable()
                                        .indicator(.activity)
                                        .transition(.fade(duration: 0.5))
                                        .scaledToFill()
                                        .frame(width: 150, height: 150)
                                        .clipped()
                                        .cornerRadius(8)
                                } else if let localImage = editableImage.localImage {
                                    Image(uiImage: localImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 150, height: 150)
                                        .clipped()
                                        .cornerRadius(8)
                                }
                            }
                        }

                        Button(action: {
                            showPhotoPicker = true
                        }) {
                            VStack {
                                Image(systemName: "plus")
                                    .font(.largeTitle)
                                    .frame(width: 150, height: 150)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.vertical)
                }
                Section(header: Text("服の情報")) {
                    TextField("名前", text: $clothing.name)
                    TextField("カテゴリ", text: $clothing.category)
                    TextField("色", text: $clothing.color)
                }

                if canDelete {
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Text("この服を削除する")
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }
            }

            PrimaryActionButton(title: "変更を保存") {
                Task {
                    await saveChanges()
                    dismiss()
                }
            }
            .padding()
        }
        .navigationTitle("服を編集")
        .sheet(isPresented: $showPhotoPicker) {
            CaptureOrLibraryView { selectedImage in
                selectedImageForCrop = selectedImage
                showCropView = true
            }
        }
        .confirmationDialog("本当に削除しますか？", isPresented: $showDeleteConfirm) {
            Button("削除する", role: .destructive) {
                Task {
                    await viewModel.deleteClothing(clothing)
                    dismiss()
                }
            }
            Button("キャンセル", role: .cancel) {}
        }
        .task {
            await loadImages()
        }
        .onAppear {
            if openPhotoPickerOnAppear {
                showPhotoPicker = true
            }
        }
        .sheet(isPresented: $showCropView) {
            if let image = selectedImageForCrop {
                ClothingCropEditView(
                    originalImage: image,
                    onComplete: { croppedImage in
                        if let selected = selectedEditableImage {
                            // 既存の画像を置き換える
                            if let index = editableImages.firstIndex(where: { $0.id == selected.id }) {
                                editableImages[index] = EditableClothingImage(id: selected.id, imageUrl: nil, localImage: croppedImage)
                            }
                        } else {
                            // 新規登録の場合
                            let newEditableImage = EditableClothingImage(id: UUID(), imageUrl: nil, localImage: croppedImage)
                            editableImages.append(newEditableImage)
                        }
                        selectedEditableImage = nil
                        showCropView = false
                    }
                )
            }
        }
    }

    private func loadImages() async {
        do {
            let fetchedImages = try await SupabaseService.shared.fetchImages(for: clothing.id)
            editableImages = fetchedImages.map { clothingImage in
                EditableClothingImage(id: clothingImage.id, imageUrl: clothingImage.image_url, localImage: nil)
            }
        } catch {
            print("❌ 画像取得エラー: \(error.localizedDescription)")
        }
    }

    private func saveChanges() async {
        do {
            if isNew {
                try await SupabaseService.shared.addClothing(clothing)
            } else {
                try await SupabaseService.shared.updateClothing(clothing)
            }

            for editableImage in editableImages {
                if let localImage = editableImage.localImage {
                    let uploadedUrl = try await SupabaseService.shared.uploadImage(localImage, for: UUID().uuidString)
                    try await SupabaseService.shared.addImage(for: clothing.id, imageUrl: uploadedUrl)
                } else {
                    // imageUrlがある場合は既存画像なので特に何もしない
                }
            }
        } catch {
            print("❌ 保存エラー: \(error.localizedDescription)")
        }
    }

    private func loadUIImageFromEditable(_ editableImage: EditableClothingImage) async -> UIImage? {
        if let localImage = editableImage.localImage {
            return localImage
        } else if let urlString = editableImage.imageUrl,
                  let url = URL(string: urlString) {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                return UIImage(data: data)
            } catch {
                print("❌ 画像ロードエラー: \(error.localizedDescription)")
                return nil
            }
        }
        return nil
    }
}
