import SwiftUI

struct ClothingDetailView: View {
    @EnvironmentObject var viewModel: ClothingViewModel
    @Environment(\.dismiss) private var dismiss

    let clothing: Clothing

    @State private var showEdit = false
    @State private var images: [ClothingImage] = []

    var body: some View {
        VStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(images) { image in
                        AsyncImage(url: URL(string: image.image_url)) { image in
                            image.resizable()
                                 .scaledToFill()
                                 .frame(width: 150, height: 150)
                                 .clipped()
                        } placeholder: {
                            ProgressView()
                        }
                    }
                }
                .padding()
            }

            Text(clothing.name)
                .font(.title)

            Spacer()
        }
        .navigationTitle("服の詳細")
        .safeAreaInset(edge: .bottom) {
            PrimaryActionButton(title: "編集する") {
                showEdit = true
            }
        }
        .sheet(isPresented: $showEdit) {
            ClothingEditView(
                clothing: clothing,
                openPhotoPickerOnAppear: false,
                canDelete: true,
                isNew: false
            )
            .environmentObject(viewModel)
        }
        .onChange(of: viewModel.clothes) { oldClothes, newClothes in
            if !newClothes.contains(where: { $0.id == clothing.id }) {
                dismiss()
            }
        }
        .task {
            await loadImages()
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
