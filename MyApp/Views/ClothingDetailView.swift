import SwiftUI
import SDWebImageSwiftUI

struct ClothingDetailView: View {
    @EnvironmentObject var viewModel: ClothingViewModel
    @Environment(\.dismiss) private var dismiss

    @Binding var clothing: Clothing
    let clothingId: UUID

    @State private var showEdit = false
    @State private var images: [ClothingImage] = []

    var body: some View {
        VStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(images) { image in
                        if let url = URL(string: image.original_url) {
                            WebImage(url: url, options: [.queryMemoryData, .queryDiskDataSync, .refreshCached])
                                .resizable()
                                .indicator(.activity)
                                .transition(.fade(duration: 0.5))
                                .scaledToFill()
                                .frame(width: 150, height: 150)
                                .clipped()
                                .cornerRadius(8)
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 150, height: 150)
                                .cornerRadius(8)
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
                clothing: $clothing,
                openPhotoPickerOnAppear: false,
                canDelete: true,
                isNew: false
            )
            .environmentObject(viewModel)
        }
        .onChange(of: viewModel.clothes) { oldClothes, newClothes in
            if !newClothes.contains(where: { $0.id == clothingId }) {
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
