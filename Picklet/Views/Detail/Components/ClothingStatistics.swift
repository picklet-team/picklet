import SwiftUI

struct ClothingStatisticsSection: View {
  let clothing: Clothing
  let clothingId: UUID
  @EnvironmentObject var themeManager: ThemeManager
  @EnvironmentObject var viewModel: ClothingViewModel

  // 最後に着用した日を取得
  private var lastWornDate: Date? {
    viewModel.wearHistories
      .filter { $0.clothingId == clothingId }
      .map { $0.wornAt }
      .max()
  }

  // 最後に着用してから何日経ったか
  private var daysSinceLastWorn: Int? {
    guard let lastDate = lastWornDate else { return nil }
    return Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      HStack {
        Image(systemName: "chart.bar.fill")
          .foregroundColor(themeManager.currentTheme.primaryColor)
        Text("統計")
          .font(.title3)
          .fontWeight(.bold)
          .foregroundColor(themeManager.currentTheme.primaryColor)
      }

      // ヒートマップ
      WearHistoryHeatmapView(
        wearHistories: viewModel.wearHistories,
        clothingId: clothingId,
        purchaseDate: clothing.createdAt)

      // 統計カード
      VStack(spacing: 16) {
        let daysSinceCreation = max(
          Calendar.current.dateComponents([.day], from: clothing.createdAt, to: Date()).day ?? 0,
          1)
        let wearCount = viewModel.getWearCount(for: clothingId)

        // 上段：基本情報
        HStack(spacing: 12) {
          ImprovedStatisticCardView(
            icon: "calendar",
            value: "\(daysSinceCreation)",
            label: "購入から\n何日",
            color: .indigo)

          ImprovedStatisticCardView(
            icon: "tshirt.fill",
            value: "\(wearCount)",
            label: clothing.wearLimit != nil ?
              "\(wearCount)/\(clothing.wearLimit!) 回" : "着用回数",
            color: .orange,
            progress: clothing.wearLimit != nil ?
              Double(wearCount) / Double(clothing.wearLimit!) : nil)
        }

        // 中段：着用間隔と最終着用
        HStack(spacing: 12) {
          // 着用間隔
          if wearCount > 1 {
            let averageDaysBetweenWears = Double(daysSinceCreation) / Double(wearCount)
            ImprovedStatisticCardView(
              icon: "clock.arrow.circlepath",
              value: String(format: "%.1f", averageDaysBetweenWears),
              label: "平均間隔\n(日)",
              color: .cyan)
          } else {
            ImprovedStatisticCardView(
              icon: "clock.arrow.circlepath",
              value: "-",
              label: "平均間隔\n(日)",
              color: .gray)
          }

          // 最終着用からの日数
          if let daysSince = daysSinceLastWorn {
            let color: Color = {
              if daysSince == 0 { return .green }
              if daysSince <= 7 { return .yellow }
              if daysSince <= 30 { return .orange }
              return .red
            }()

            ImprovedStatisticCardView(
              icon: "clock.badge",
              value: daysSince == 0 ? "今日" : "\(daysSince)",
              label: daysSince == 0 ? "最終着用" : "日前着用",
              color: color)
          } else {
            ImprovedStatisticCardView(
              icon: "clock.badge",
              value: "-",
              label: "未着用",
              color: .gray)
          }
        }

        // 下段：コスト分析
        HStack(spacing: 12) {
          // 着用単価
          if let price = clothing.purchasePrice {
            if wearCount > 0 {
              let costPerWear = price / Double(wearCount)
              let targetWears = clothing.wearLimit ?? 30
              let targetCost = price / Double(targetWears)

              ImprovedStatisticCardView(
                icon: "yensign.circle",
                value: "¥\(Int(costPerWear))",
                label: "着用単価",
                color: .mint,
                progress: max(0, min(1.0 - (costPerWear - targetCost) / price, 1.0)))
            } else {
              ImprovedStatisticCardView(
                icon: "yensign.circle",
                value: "¥\(Int(price))",
                label: "着用単価",
                color: .gray)
            }
          } else {
            ImprovedStatisticCardView(
              icon: "yensign.circle",
              value: "-",
              label: "着用単価",
              color: .gray)
          }

          // 目標達成率
          if let wearLimit = clothing.wearLimit {
            let progress = Double(wearCount) / Double(wearLimit)
            let percentage = Int(progress * 100)

            ImprovedStatisticCardView(
              icon: "target",
              value: "\(percentage)%",
              label: "目標達成",
              color: progress >= 1.0 ? .green : .blue,
              progress: min(progress, 1.0))
          } else {
            ImprovedStatisticCardView(
              icon: "target",
              value: "-",
              label: "目標未設定",
              color: .gray)
          }
        }
      }
    }
  }
}
