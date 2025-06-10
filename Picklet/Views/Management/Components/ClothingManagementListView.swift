import SDWebImageSwiftUI
import SwiftUI

struct ClothingManagementListView: View {
  @EnvironmentObject private var viewModel: ClothingViewModel
  @EnvironmentObject private var themeManager: ThemeManager
  @EnvironmentObject private var referenceDataManager: ReferenceDataManager

  @State private var showingDeleteAlert = false
  @State private var clothingToDelete: Clothing?

  var body: some View {
    ZStack {
      themeManager.currentTheme.backgroundGradient
        .ignoresSafeArea()

      VStack(spacing: 0) {
        // 統計情報
        statisticsView

        // 洋服リスト
        if viewModel.clothes.isEmpty {
          emptyStateView
        } else {
          clothingListView
        }
      }
    }
    .navigationTitle("洋服管理")
    .navigationBarTitleDisplayMode(.large)
    .alert("洋服を削除", isPresented: $showingDeleteAlert) {
      Button("削除", role: .destructive) {
        if let clothing = clothingToDelete {
          deleteClothing(clothing)
        }
      }
      Button("キャンセル", role: .cancel) { }
    } message: {
      if let clothing = clothingToDelete {
        Text("「\(clothing.name)」を削除しますか？この操作は取り消せません。")
      }
    }
    .onAppear {
      viewModel.loadClothings()
    }
  }

  // MARK: - View Components

  private var statisticsView: some View {
    HStack {
      // 総数
      StatisticItemView(
        icon: "tshirt.fill",
        value: "\(viewModel.clothes.count)",
        label: "件",
        color: themeManager.currentTheme.primaryColor
      )

      Spacer()

      // 総着用回数
      StatisticItemView(
        icon: "repeat",
        value: "\(viewModel.clothes.reduce(0) { $0 + $1.wearCount })",
        label: "回",
        color: .blue
      )

      Spacer()

      // 総購入金額
      if viewModel.clothes.contains(where: { $0.purchasePrice != nil }) {
        let totalPrice = viewModel.clothes.compactMap { $0.purchasePrice }.reduce(0, +)
        StatisticItemView(
          icon: "yensign.circle",
          value: "¥\(Int(totalPrice).formatted())",
          label: "",
          color: .green
        )
      }
    }
    .padding()
    .background(.ultraThinMaterial)
  }

  private var clothingListView: some View {
    List {
      ForEach(viewModel.clothes) { clothing in
        ClothingManagementRowView(
          clothing: clothing,
          onDelete: {
            clothingToDelete = clothing
            showingDeleteAlert = true
          }
        )
        .environmentObject(viewModel)
        .environmentObject(themeManager)
        .environmentObject(referenceDataManager)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
      }
    }
    .listStyle(PlainListStyle())
    .scrollContentBackground(.hidden)
  }

  private var emptyStateView: some View {
    VStack(spacing: 20) {
      Image(systemName: "tshirt")
        .font(.system(size: 60))
        .foregroundColor(.secondary)

      Text("洋服が登録されていません")
        .font(.title2)
        .fontWeight(.semibold)
        .foregroundColor(.secondary)

      Text("「写真から服を追加」ボタンから\n最初の洋服を追加してみましょう")
        .font(.body)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.clear)
  }

  // MARK: - Actions

  private func deleteClothing(_ clothing: Clothing) {
    withAnimation {
      viewModel.deleteClothing(clothing)
    }
  }
}

// MARK: - Support Components

struct StatisticItemView: View {
  let icon: String
  let value: String
  let label: String
  let color: Color

  var body: some View {
    VStack(spacing: 4) {
      Image(systemName: icon)
        .font(.title3)
        .foregroundColor(color)

      HStack(spacing: 2) {
        Text(value)
          .font(.headline)
          .fontWeight(.bold)

        if !label.isEmpty {
          Text(label)
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
    }
  }
}
