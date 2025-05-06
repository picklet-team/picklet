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
      // 共通コンポーネントを使用（プラスボタンなし）
      ClothingImageGalleryView(
        imageSets: viewModel.imageSetsMap[clothingId] ?? [],
        showAddButton: false // プラスボタンは表示しない
      )

      Text(clothing.name)
        .font(.title)

      Spacer()
    }
    .accessibility(identifier: "clothingDetailView")
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
        isNew: false)
        .environmentObject(viewModel)
    }
    .onChange(of: viewModel.clothes) { _, newClothes in
      if !newClothes.contains(where: { $0.id == clothingId }) {
        dismiss()
      }
    }
  }
}
