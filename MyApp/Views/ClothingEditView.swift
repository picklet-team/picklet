import SwiftUI
import SDWebImageSwiftUI


struct ClothingEditView: View {
    @EnvironmentObject var viewModel: ClothingViewModel
    @Environment(\.dismiss) var dismiss
    @Binding var clothing: Clothing
  
    let openPhotoPickerOnAppear: Bool
    let canDelete: Bool
    let isNew: Bool

    @State private var showPhotoPicker = false
    @State private var showImageEditView = false
    @State private var showDeleteConfirm = false
  
    @State private var imageSets: [EditableImageSet] = []
    @State private var selectedImageSet: EditableImageSet? = nil

    var body: some View {
        VStack {
            Form {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(imageSets) { imageSet in
                            imageButton(for: imageSet)
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
                let newSet = EditableImageSet(
                    id: UUID(),
                    original: selectedImage.normalized(),
                    originalUrl: nil,
                    mask: nil,
                    maskUrl: nil,
                    result: nil,
                    resultUrl: nil,
                    isNew: true
                )
                imageSets.append(newSet)
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
        .sheet(isPresented: $showImageEditView) {
            if let selected = selectedImageSet {
                ImageEditView(imageSet: selected)
            }
        }
    }

    private func loadImages() async {
        do {
            let fetchedImages = try await SupabaseService.shared.fetchImages(for: clothing.id)
            imageSets = fetchedImages.map { clothingImage in
                EditableImageSet(
                    id: clothingImage.id,
                    original: nil,
                    originalUrl: clothingImage.original_url,
                    mask: nil,
                    maskUrl: nil,
                    result: nil,
                    resultUrl: nil,
                    isNew: false
                )
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

            for set in imageSets {
                if set.isNew, let original = set.original {
                    let originalUrl = try await SupabaseService.shared.uploadImage(original, for: UUID().uuidString)
                    try await SupabaseService.shared.addImage(for: clothing.id, originalUrl: originalUrl)
                    print("✅ 画像保存完了: \(originalUrl)")
                }
            }
        } catch {
            print("❌ 保存エラー: \(error.localizedDescription)")
        }
    }

    private func imageButton(for imageSet: EditableImageSet) -> some View {
        Button {
            selectedImageSet = imageSet
            showImageEditView = true
        } label: {
            Group {
                if let original = imageSet.original {
                    Image(uiImage: original)
                        .resizable()
                } else if let urlString = imageSet.originalUrl, let url = URL(string: urlString) {
                    WebImage(url: url)
                        .resizable()
                        .indicator(.activity)
                } else {
                    Color.gray
                }
            }
            .scaledToFill()
            .frame(width: 150, height: 150)
            .clipped()
            .cornerRadius(8)
        }
    }
}
