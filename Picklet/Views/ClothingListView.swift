import SwiftUI

// PreferenceKey to capture each item's vertical offset in the scroll view
private struct TopItemPreferenceKey: PreferenceKey {
  static var defaultValue: [UUID: CGFloat] = [:]
  static func reduce(value: inout [UUID: CGFloat], nextValue: () -> [UUID: CGFloat]) {
    value.merge(nextValue(), uniquingKeysWith: { $1 })
  }
}

struct ClothingListView: View {
  @StateObject private var viewModel = ClothingViewModel()

  // grid columns can be changed by the user (2–4) – default 2
  @State private var columnCount: Int = 2

  // id of the item that is currently top‑most (captured via PreferenceKey)
  @State private var topVisibleId: UUID?

  // scroll proxy saved once to reuse when columnCount changes
  @State private var scrollProxy: ScrollViewProxy?

  @State private var navigateToEdit = false
  @State private var editingClothing: Clothing?
  @State private var isNewClothing = false

  // spacing between cells
  private let spacing: CGFloat = 16

  @State private var useDockView = true

  var body: some View {
    NavigationStack {
      ClothingDockView().environmentObject(viewModel)
        .navigationTitle("My Clothes")
        .safeAreaInset(edge: .bottom) {
          PrimaryActionButton(title: "写真から服を追加") {
            if let user = SupabaseService.shared.currentUser {
              let newClothing = Clothing(
                id: UUID(),
                userID: user.id,
                name: "",
                category: "",
                color: "",
                createdAt: ISO8601DateFormatter().string(from: Date()),
                updatedAt: ""
              )
              self.editingClothing = newClothing
              self.isNewClothing = true
              self.navigateToEdit = true
            }
          }
        }
        .navigationDestination(isPresented: $navigateToEdit) {
          if let editingClothing = editingClothing {
            ClothingEditView(
              clothing: Binding(get: { editingClothing }, set: { self.editingClothing = $0 }),
              openPhotoPickerOnAppear: true, canDelete: false, isNew: true
            )
            .environmentObject(viewModel)
          }
        }
        .task { await viewModel.loadClothes() }
    }
  }
}
