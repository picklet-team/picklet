import SDWebImageSwiftUI
import SwiftUI

struct ClothingDetailView: View {
    @EnvironmentObject var viewModel: ClothingViewModel
    @Environment(\.dismiss) private var dismiss

    @Binding var clothing: Clothing
    let clothingId: UUID

    @State private var showEdit = false

    var body: some View {
        VStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // ViewModel の imageSetsMap からサムネイルを表示
                    ForEach(viewModel.imageSetsMap[clothingId] ?? []) { set in
                        ClothingDetailImageView(imageURL: set.originalUrl)
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
        .onChange(of: viewModel.clothes) { _, newClothes in
            if !newClothes.contains(where: { $0.id == clothingId }) {
                dismiss()
            }
        }
    }
}

private struct ClothingDetailImageView: View {
    let imageURL: String?
    var body: some View {
        Group {
            if let urlString = imageURL, let url = URL(string: urlString) {
                WebImage(url: url,
                         options: [.queryMemoryData, .queryDiskDataSync, .refreshCached])
                    .resizable()
                    .indicator(.activity)
            } else {
                Rectangle().fill(Color.gray.opacity(0.2))
            }
        }
        .scaledToFill()
        .frame(width: 150, height: 150)
        .clipped()
        .cornerRadius(8)
    }
}
