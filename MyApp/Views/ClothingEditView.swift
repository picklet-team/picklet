import SwiftUI

struct ClothingEditView: View {
    @EnvironmentObject var viewModel: ClothingViewModel
    @Environment(\.dismiss) var dismiss
    @State var clothing: Clothing
  
    let openPhotoPickerOnAppear: Bool
    let canDelete: Bool
    let isNew: Bool

    @State private var showPhotoPicker = false
    @State private var showDeleteConfirm = false
  
    @State private var images: [ClothingImage] = []

    var body: some View {
        VStack {
            Form {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(images) { image in
                            AsyncImage(url: URL(string: image.image_url)) { img in
                                img.resizable()
                                    .scaledToFill()
                                    .frame(width: 150, height: 150)
                                    .clipped()
                            } placeholder: {
                                ProgressView()
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
                    await viewModel.updateClothing(clothing, isNew: isNew)
                    dismiss()
                }
            }
            .padding()
        }
        .navigationTitle("服を編集")
        .sheet(isPresented: $showPhotoPicker) {
            CaptureOrLibraryView { selectedImage in
                Task {
                    let url = try await SupabaseService.shared.uploadImage(selectedImage, for: UUID().uuidString)
                    let newImage = ClothingImage(
                        id: UUID(),
                        clothing_id: clothing.id,
                        image_url: url,
                        created_at: ISO8601DateFormatter().string(from: Date())
                    )
                    images.append(newImage)
                }
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
    }

    private func loadImages() async {
        do {
            images = try await SupabaseService.shared.fetchImages(for: clothing.id)
        } catch {
            print("❌ 画像取得エラー: \(error.localizedDescription)")
        }
    }
}
