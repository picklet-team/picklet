import SDWebImageSwiftUI
import SwiftUI

struct ClothingDetailView: View {
  @EnvironmentObject var viewModel: ClothingViewModel
  @EnvironmentObject var themeManager: ThemeManager
  @EnvironmentObject var referenceDataManager: ReferenceDataManager // 変更
  @Environment(\.dismiss) private var dismiss

  @Binding var clothing: Clothing
  let clothingId: UUID

  @State private var showEdit = false

  var body: some View {
    ZStack {
      themeManager.currentTheme.backgroundGradient
        .ignoresSafeArea()

      VStack(spacing: 0) {
        ScrollView {
          LazyVStack(spacing: 20) {
            // 画像ギャラリー
            ClothingImageGalleryView(
              imageSets: viewModel.imageSetsMap[clothingId] ?? [],
              showAddButton: false)

            // ヘッダーセクション（お気に入り度・価格）
            ClothingDetailHeaderSection(clothing: $clothing)
              .environmentObject(themeManager)
              .environmentObject(viewModel)

            // 着用記録セクション
            ClothingWearCountSection(clothing: $clothing)
              .environmentObject(themeManager)
              .environmentObject(viewModel)

            // 統計情報
            ClothingStatisticsSection(clothing: clothing, clothingId: clothingId)
              .environmentObject(themeManager)
              .environmentObject(viewModel)

            // 詳細情報セクション
            ClothingDetailInfoSection(clothing: clothing)
              .environmentObject(themeManager)

            // カテゴリ情報
            ClothingCategorySection(clothing: clothing)
              .environmentObject(themeManager)
              .environmentObject(referenceDataManager) // 変更

            // ブランド情報
            ClothingBrandSection(clothing: clothing)
              .environmentObject(themeManager)
              .environmentObject(referenceDataManager) // 変更

            // カラー情報
            ClothingColorSection(clothing: clothing)
              .environmentObject(themeManager)

            Spacer(minLength: 100)
          }
          .padding(.horizontal)
        }

        // 編集ボタン
        PrimaryActionButton(title: "編集する") {
          showEdit = true
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
      }
    }
    .accessibility(identifier: "clothingDetailView")
    .navigationTitle(clothing.name)
    .navigationBarTitleDisplayMode(.large)
    .navigationBarBackButtonHidden(false)
    .tint(themeManager.currentTheme.accentColor)
    .sheet(isPresented: $showEdit) {
      ClothingEditView(
        clothing: $clothing,
        openPhotoPickerOnAppear: false,
        canDelete: true,
        isNew: false)
        .environmentObject(viewModel)
        .environmentObject(themeManager)
        .environmentObject(referenceDataManager) // 変更
    }
    .onChange(of: viewModel.clothes) { _, newClothes in
      if !newClothes.contains(where: { $0.id == clothingId }) {
        dismiss()
      }
    }
  }
}
