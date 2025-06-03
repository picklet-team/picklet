import SwiftUI

struct ClothingListView: View {
  @EnvironmentObject private var viewModel: ClothingViewModel
  @EnvironmentObject private var themeManager: ThemeManager
  @EnvironmentObject private var overlayManager: GlobalOverlayManager
  @EnvironmentObject private var categoryManager: CategoryManager
  @EnvironmentObject private var brandManager: BrandManager

  @State private var navigateToEdit = false
  @State private var editingClothing: Clothing?
  @State private var isNewClothing = false

  var body: some View {
    NavigationStack {
      ClothingDockView()
        .environmentObject(viewModel)
        .environmentObject(overlayManager)
        .environmentObject(themeManager)
        .accessibility(identifier: "clothingListView")
        .background(
          themeManager.currentTheme.backgroundGradient
            .ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
          PrimaryActionButton(
            title: "写真から服を追加",
            backgroundColor: themeManager.currentTheme.lightBackgroundColor) {
              // 新しいClothingモデルを作成
              editingClothing = Clothing(
                name: "",
                purchasePrice: nil,
                favoriteRating: 3,
                colors: [],
                categoryIds: [], // 追加
                brandId: nil, // 追加
                tagIds: [] // 追加
              )
              isNewClothing = true
              navigateToEdit = true
            }
            .accessibility(identifier: "addClothingButton")
        }
        .navigationDestination(isPresented: $navigateToEdit) {
          if let editingClothing = editingClothing {
            ClothingEditView(
              clothing: .constant(editingClothing), // Bindingに変換
              openPhotoPickerOnAppear: true,
              canDelete: false,
              isNew: true)
              .environmentObject(viewModel)
              .environmentObject(themeManager)
              .environmentObject(categoryManager)
              .environmentObject(brandManager)
          }
        }
        .refreshable {
          viewModel.loadClothings()
        }
    }
  }
}
