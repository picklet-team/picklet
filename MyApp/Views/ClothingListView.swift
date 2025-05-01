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
//            VStack(spacing: 0) {
//                // column selector
//                HStack(spacing: 12) {
//                    ForEach(2...4, id: \ .self) { n in
//                        Button("\(n)") {
//                            // remember current top before changing layout
//                            let currentTop = topVisibleId
//                            withAnimation { columnCount = n }
//                            // after layout change, scroll back to the same item
//                            if let id = currentTop {
//                                DispatchQueue.main.async {
//                                    scrollProxy?.scrollTo(id, anchor: .top)
//                                }
//                            }
//                        }
//                        .padding(6)
//                        .background(columnCount == n ? Color.accentColor.opacity(0.2) : Color.clear)
//                        .cornerRadius(6)
//                    }
//                }
//                .font(.subheadline)
//                .padding([.horizontal,.top])
//
//                ScrollViewReader { proxy in
//                    ScrollView {
//                        LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: spacing), count: columnCount), spacing: spacing) {
//                            ForEach($viewModel.clothes, id: \ .id) { $clothing in
//                                NavigationLink(destination: ClothingDetailView(clothing: $clothing, clothingId: clothing.id).environmentObject(viewModel)) {
//                                    ClothingItemView(clothing: clothing, imageUrl: viewModel.imageSetsMap[clothing.id]?.first?.originalUrl)
//                                        .environmentObject(viewModel)
//                                }
//                                .id(clothing.id) // enable scrollTo
//                                .background(
//                                    GeometryReader { geo in
//                                        Color.clear.preference(key: TopItemPreferenceKey.self, value: [clothing.id: geo.frame(in: .named("gridSpace")).minY])
//                                    }
//                                )
//                            }
//                        }
//                        .padding(spacing)
//                    }
//                    .coordinateSpace(name: "gridSpace")
//                    .onPreferenceChange(TopItemPreferenceKey.self) { values in
//                        if let (id, _) = values.filter({ $0.value >= 0 }).min(by: { $0.value < $1.value }) {
//                            topVisibleId = id
//                        }
//                    }
//                    .onAppear { scrollProxy = proxy }
//                }
//            }
            .navigationTitle("My Clothes")
            .safeAreaInset(edge: .bottom) {
                PrimaryActionButton(title: "写真から服を追加") {
                    if let user = SupabaseService.shared.currentUser {
                        let newClothing = Clothing(id: UUID(), user_id: user.id, name: "", category: "", color: "", created_at: ISO8601DateFormatter().string(from: Date()), updated_at: "")
                        self.editingClothing = newClothing
                        self.isNewClothing = true
                        self.navigateToEdit = true
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToEdit) {
                if let editingClothing = editingClothing {
                    ClothingEditView(clothing: Binding(get: { editingClothing }, set: { self.editingClothing = $0 }), openPhotoPickerOnAppear: true, canDelete: false, isNew: true)
                        .environmentObject(viewModel)
                }
            }
            .task { await viewModel.loadClothes() }
        }
    }
}
