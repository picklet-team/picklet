import SwiftUI

struct ClothingListView: View {
    @StateObject private var viewModel = ClothingViewModel()
    @State private var navigateToEdit = false
    @State private var editingClothing: Clothing?
    @State private var isNewClothing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach($viewModel.clothes, id: \.id) { $clothing in
                        NavigationLink(
                            destination: ClothingDetailView(clothing: $clothing, clothingId: clothing.id)
                                .environmentObject(viewModel)
                        ) {
                            ClothingItemView(clothing: clothing)
                                .environmentObject(viewModel)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("My Clothes")
            .safeAreaInset(edge: .bottom) {
                PrimaryActionButton(title: "写真から服を追加") {
                    if let user = SupabaseService.shared.currentUser {
                        let newClothing = Clothing(
                            id: UUID(),
                            user_id: user.id,
                            name: "",
                            category: "",
                            color: "",
                            created_at: ISO8601DateFormatter().string(from: Date())
                        )
                        self.editingClothing = newClothing
                        self.isNewClothing = true
                        self.navigateToEdit = true
                    } else {
                        print("❌ ログインユーザーがいません")
                    }
                }
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
            .task {
                await viewModel.loadClothes()
            }
        }
    }
}
