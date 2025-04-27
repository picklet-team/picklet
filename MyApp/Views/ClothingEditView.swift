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

    var body: some View {
        VStack {
            Form {
                Section(header: Text("服の情報")) {
                    TextField("名前", text: $clothing.name)
                    TextField("カテゴリ", text: $clothing.category)
                    TextField("色", text: $clothing.color)
                }

                if let url = URL(string: clothing.image_url), !clothing.image_url.isEmpty {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                    } placeholder: {
                        ProgressView()
                    }
                }

                Section {
                    Button("写真を変更する") {
                        showPhotoPicker = true
                    }
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
            CaptureOrLibraryView{ selectedImage in
                Task {
                    let url = try await SupabaseService.shared.uploadImage(selectedImage, for: UUID().uuidString)
                    clothing.image_url = url
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
        .onAppear {
            if openPhotoPickerOnAppear {
                showPhotoPicker = true
            }
        }
    }
}
