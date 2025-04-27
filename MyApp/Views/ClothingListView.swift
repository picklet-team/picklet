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
                    ForEach(viewModel.clothes) { clothing in
                        NavigationLink(destination: ClothingDetailView(clothing: clothing).environmentObject(viewModel)) {
                            ClothingItemView(clothing: clothing)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("My Clothes")
            .safeAreaInset(edge: .bottom) {
                PrimaryActionButton(title: "写真から服を追加") {
                    Task {
                        let newClothing = try? await viewModel.createLocalTemporaryClothing()
                        self.editingClothing = newClothing
                        self.isNewClothing = true
                        self.navigateToEdit = true
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToEdit) {
                if let clothing = editingClothing {
                    ClothingEditView(
                        clothing: clothing,
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
