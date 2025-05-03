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
        .navigationTitle("My Clothes")
        .safeAreaInset(edge: .bottom) {
          PrimaryActionButton(title: "写真から服を追加") {
            if let user = SupabaseService.shared.currentUser {
              editingClothing = Clothing(
                id: UUID(),
                userID: user.id,
                name: "",
                category: "",
                color: "",
                createdAt: ISO8601DateFormatter().string(from: Date()),
                updatedAt: ISO8601DateFormatter().string(from: Date())
              )
              isNewClothing = true
              navigateToEdit = true
            }
          }
          .accessibility(identifier: "addClothingButton")
        }
        .navigationDestination(isPresented: $navigateToEdit) {
          if let editingClothing = editingClothing {
            ClothingEditView(
              clothing: Binding(
                get: { editingClothing },
                set: { self.editingClothing = $0 }
              ),
              openPhotoPickerOnAppear: true,
              canDelete: false,
              isNew: true
            )
            .environmentObject(viewModel)
          }
        }
        .refreshable {
          await viewModel.syncIfNeeded()
        }
    }
  }
}
