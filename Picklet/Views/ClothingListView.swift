import SwiftUI

struct ClothingListView: View {
  @EnvironmentObject private var viewModel: ClothingViewModel
  @EnvironmentObject private var themeManager: ThemeManager
  @EnvironmentObject private var overlayManager: GlobalOverlayManager

  @State private var navigateToEdit = false
  @State private var editingClothing: Clothing?
  @State private var isNewClothing = false

  var body: some View {
    NavigationStack {
      ClothingDockView()
        .environmentObject(viewModel)
        .environmentObject(overlayManager)
        .environmentObject(themeManager) // この行を追加
        .accessibility(identifier: "clothingListView")
        .background(
          themeManager.currentTheme.backgroundGradient
            .ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
          PrimaryActionButton(
            title: "写真から服を追加",
            backgroundColor: themeManager.currentTheme.lightBackgroundColor) {
              editingClothing = Clothing(
                id: UUID(),
                name: "",
                category: "",
                color: "",
                createdAt: Date(),
                updatedAt: Date())
              isNewClothing = true
              navigateToEdit = true
            }
            .accessibility(identifier: "addClothingButton")
        }
        .navigationDestination(isPresented: $navigateToEdit) {
          if let editingClothing = editingClothing {
            ClothingEditView(
              clothing: Binding(
                get: { editingClothing },
                set: { self.editingClothing = $0 }),
              openPhotoPickerOnAppear: true,
              canDelete: false,
              isNew: true)
              .environmentObject(viewModel)
          }
        }
        .refreshable {
          viewModel.loadClothings()
        }
    }
  }
}
