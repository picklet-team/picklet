import SDWebImageSwiftUI
import SwiftUI

struct ClothingDetailView: View {
  @EnvironmentObject var viewModel: ClothingViewModel
  @Environment(\.dismiss) private var dismiss

  @Binding var clothing: Clothing
  let clothingId: UUID

  @State private var showEdit = false

  var body: some View {
    VStack(spacing: 0) {
      // メインコンテンツをScrollViewに入れる
      ScrollView {
        VStack {
          // 共通コンポーネントを使用（プラスボタンなし）
          ClothingImageGalleryView(
            imageSets: viewModel.imageSetsMap[clothingId] ?? [],
            showAddButton: false // プラスボタンは表示しない
          )

          // その他の詳細情報をここに追加
          // ...

          // スクロール領域の末尾に余白を追加（必要に応じて）
          Spacer(minLength: 20)
        }
        .padding(.horizontal)
      }

      // タブのすぐ上に固定表示される編集ボタン
      PrimaryActionButton(title: "編集する") {
        showEdit = true
      }
      .padding(.vertical, 8)
      .padding(.horizontal)
    }
    .accessibility(identifier: "clothingDetailView")
    .navigationTitle(clothing.name)
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
