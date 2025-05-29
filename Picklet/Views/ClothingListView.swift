import SwiftUI

struct ClothingListView: View {
  @EnvironmentObject private var viewModel: ClothingViewModel

  @State private var navigateToEdit = false
  @State private var editingClothing: Clothing?
  @State private var isNewClothing = false

  var body: some View {
    NavigationStack {
      ClothingDockView().environmentObject(viewModel)
        .accessibility(identifier: "clothingListView")
        .safeAreaInset(edge: .bottom) {
          PrimaryActionButton(title: "写真から服を追加") {
            // Supabase認証チェックを削除し、直接服の追加を許可
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
          // Supabase同期を削除し、ローカルデータのリロードのみ
          viewModel.loadClothings()
        }
    }
  }
}
