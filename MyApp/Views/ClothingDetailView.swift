import SwiftUI

struct ClothingDetailView: View {
    @EnvironmentObject var viewModel: ClothingViewModel
    @Environment(\.dismiss) private var dismiss

    let clothing: Clothing

    @State private var showEdit = false

    var body: some View {
        VStack {
            if let url = URL(string: clothing.image_url), !clothing.image_url.isEmpty {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(height: 250)
                } placeholder: {
                    ProgressView()
                }
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
    }
}
