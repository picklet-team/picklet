import SwiftUI

// MARK: - 視覚的サポートビュー

struct InteractiveStarRatingView: View {
  @Binding var rating: Int
  let maxRating: Int = 5

  var body: some View {
    HStack(spacing: 4) {
      ForEach(1...maxRating, id: \.self) { index in
        Button(action: {
          rating = index
        }) {
          Image(systemName: index <= rating ? "star.fill" : "star")
            .foregroundColor(index <= rating ? .yellow : .gray.opacity(0.3))
            .font(.title3)
        }
        .buttonStyle(PlainButtonStyle())
      }
    }
  }
}

struct StarRatingView: View {
  let rating: Int
  let maxRating: Int = 5

  var body: some View {
    HStack(spacing: 4) {
      ForEach(1...maxRating, id: \.self) { index in
        Image(systemName: index <= rating ? "star.fill" : "star")
          .foregroundColor(index <= rating ? .yellow : .gray.opacity(0.3))
          .font(.title3)
      }
    }
  }
}

struct PriceDisplayView: View {
  let price: Double

  var body: some View {
    HStack(spacing: 4) {
      Image(systemName: "yensign.circle.fill")
        .foregroundColor(.green)
        .font(.title2)

      Text("¥\(Int(price).formatted())")
        .font(.title2)
        .fontWeight(.bold)
        .foregroundColor(.primary)
    }
  }
}

// MARK: - 改善された統計カード

struct ImprovedStatisticCardView: View {
  let icon: String
  let value: String
  let label: String
  let color: Color
  let progress: Double?

  init(icon: String, value: String, label: String, color: Color, progress: Double? = nil) {
    self.icon = icon
    self.value = value
    self.label = label
    self.color = color
    self.progress = progress
  }

  var body: some View {
    VStack(spacing: 12) {
      // アイコンと値
      VStack(spacing: 8) {
        ZStack {
          Circle()
            .fill(color.opacity(0.1))
            .frame(width: 50, height: 50)

          Image(systemName: icon)
            .font(.title2)
            .foregroundColor(color)
        }

        Text(value)
          .font(.title2)
          .fontWeight(.bold)
          .foregroundColor(.primary)
          .minimumScaleFactor(0.8)
          .lineLimit(1)
      }

      // プログレスバー（オプション）
      if let progress = progress {
        GeometryReader { geometry in
          ZStack(alignment: .leading) {
            Rectangle()
              .fill(color.opacity(0.2))
              .frame(height: 4)
              .cornerRadius(2)

            Rectangle()
              .fill(color)
              .frame(width: geometry.size.width * min(progress, 1.0), height: 4)
              .cornerRadius(2)
          }
        }
        .frame(height: 4)
      }

      // ラベル
      Text(label)
        .font(.caption)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .lineLimit(2)
    }
    .frame(maxWidth: .infinity)
    .padding()
    .background(Color(.secondarySystemBackground))
    .cornerRadius(16)
  }
}

// MARK: - GitHub風着用履歴ヒートマップ

struct WearHistoryHeatmapView: View {
  let wearHistories: [WearHistory]
  let clothingId: UUID
  let purchaseDate: Date

  private var filteredHistories: [WearHistory] {
    wearHistories.filter { $0.clothingId == clothingId }
  }

  // 過去の週データを取得（月曜日始まり）
  private var weeksData: [[Date]] {
    let calendar = Calendar.current
    let today = Date()
    var weeks: [[Date]] = []

    // 今週の月曜日を取得
    let weekday = calendar.component(.weekday, from: today)
    let daysFromMonday = (weekday == 1) ? 6 : weekday - 2
    guard let thisMonday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else {
      return weeks
    }

    // 20週分のデータを作成
    for weekOffset in (0..<20).reversed() {
      guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: thisMonday) else {
        continue
      }

      var week: [Date] = []
      for dayOffset in 0..<7 {
        if let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) {
          week.append(day)
        }
      }
      weeks.append(week)
    }

    return weeks
  }

  private func hasWornOnDate(_ date: Date) -> Bool {
    let calendar = Calendar.current
    let dayStart = calendar.startOfDay(for: date)
    let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

    return filteredHistories.contains { history in
      history.wornAt >= dayStart && history.wornAt < dayEnd
    }
  }

  private func colorForDate(_ date: Date) -> Color {
    // 購入日前は濃いグレー
    if date < Calendar.current.startOfDay(for: purchaseDate) {
      return Color(.systemGray3) // より濃いグレーに変更
    }

    // 未来の日付は表示しない
    if date > Date() {
      return Color.clear
    }

    // 着用したかどうかのみ
    if hasWornOnDate(date) {
      return .green
    } else {
      return Color(.systemGray5) // 購入後未着用はより濃いグレーに変更
    }
  }

  private func isToday(_ date: Date) -> Bool {
    Calendar.current.isDate(date, inSameDayAs: Date())
  }

  private func monthNumber(for date: Date) -> Int {
    Calendar.current.component(.month, from: date)
  }

  // 月ラベルを表示すべき週かどうかを判定
  private func shouldShowMonthLabel(for weekIndex: Int) -> Bool {
    guard weekIndex < weeksData.count,
          let firstDate = weeksData[weekIndex].first else { return false }

    let calendar = Calendar.current
    let dayOfMonth = calendar.component(.day, from: firstDate)

    // 月の最初の週（1日から7日の間）の場合のみ表示
    return dayOfMonth <= 7
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("着用履歴")
          .font(.headline)
          .fontWeight(.semibold)

        Spacer()
      }

      VStack(spacing: 2) {
        // ヒートマップ本体
        ScrollView(.horizontal, showsIndicators: false) {
          VStack(spacing: 2) {
            // 月ラベル（横軸）- 曜日ラベル削除
            HStack(spacing: 2) {
              // 曜日ラベル用スペース
              Text("")
                .frame(width: 14)

              ForEach(Array(weeksData.enumerated()), id: \.offset) { weekIndex, week in
                if let firstDate = week.first, shouldShowMonthLabel(for: weekIndex) {
                  Text("\(monthNumber(for: firstDate))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: 14, height: 14)
                } else {
                  Text("")
                    .frame(width: 14, height: 14)
                }
              }
            }

            // 日付グリッド
            ForEach(0..<7) { dayIndex in
              HStack(spacing: 2) {
                // 曜日ラベル（縦軸のみ）
                Text(["月", "火", "水", "木", "金", "土", "日"][dayIndex])
                  .font(.caption2)
                  .foregroundColor(.secondary)
                  .frame(width: 14, height: 14)

                ForEach(Array(weeksData.enumerated()), id: \.offset) { weekIndex, week in
                  if dayIndex < week.count {
                    let date = week[dayIndex]

                    Rectangle()
                      .fill(colorForDate(date))
                      .frame(width: 14, height: 14)
                      .cornerRadius(3)
                      .overlay(
                        Group {
                          if isToday(date) && date >= Calendar.current.startOfDay(for: purchaseDate) {
                            // 今日マーカー（購入後のみ）
                            Rectangle()
                              .stroke(Color.primary, lineWidth: 1.5)
                              .cornerRadius(3)
                          }
                        }
                      )
                  } else {
                    Rectangle()
                      .fill(Color.clear)
                      .frame(width: 14, height: 14)
                  }
                }
              }
            }
          }
          .padding(.horizontal, 4)
        }
      }
    }
    .padding()
    .background(Color(.secondarySystemBackground))
    .cornerRadius(16)
  }
}

// MARK: - その他のビュー（変更なし）

struct CompactTagView: View {
  let text: String
  let color: Color

  var body: some View {
    Text(text)
      .font(.caption)
      .fontWeight(.medium)
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
      .background(color.opacity(0.15))
      .foregroundColor(color)
      .cornerRadius(16)
  }
}

extension DateFormatter {
  static let shortDate: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.locale = Locale(identifier: "ja_JP")
    return formatter
  }()
}

// MARK: - 改善されたセクション

struct ClothingDetailHeaderSection: View {
  @Binding var clothing: Clothing
  @EnvironmentObject var themeManager: ThemeManager
  @EnvironmentObject var viewModel: ClothingViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      // お気に入り度（タップで変更可能）- ラベルを削除
      InteractiveStarRatingView(rating: $clothing.favoriteRating)
        .onChange(of: clothing.favoriteRating) { _, newRating in
          // 更新日時を設定
          clothing.updatedAt = Date()

          // ViewModelの同期更新（UIのちらつきを防ぐ）
          if let index = viewModel.clothes.firstIndex(where: { $0.id == clothing.id }) {
            viewModel.clothes[index] = clothing
          }

          // Swift 6対応の非同期処理
          let clothingCopy = clothing
          DispatchQueue.global(qos: .userInitiated).async {
            let success = SQLiteManager.shared.updateClothing(clothingCopy) // 直接SQLiteManagerを使用
            DispatchQueue.main.async {
              if success {
                print("✅ お気に入り度更新成功: \(newRating)")
              } else {
                print("❌ お気に入り度更新失敗")
              }
            }
          }
        }

      // 購入価格（常に表示）
      HStack {
        Text("購入価格")
          .font(.subheadline)
          .foregroundColor(.secondary)
        Spacer()

        if let price = clothing.purchasePrice {
          PriceDisplayView(price: price)
        } else {
          // 購入価格未設定の場合は"-"で表示
          HStack(spacing: 4) {
            Image(systemName: "yensign.circle")
              .foregroundColor(.gray)
              .font(.title2)

            Text("-")
              .font(.title2)
              .fontWeight(.bold)
              .foregroundColor(.gray)
          }
        }
      }
    }
    .padding()
    .background(Color(.secondarySystemBackground))
    .cornerRadius(16)
  }
}

struct ClothingDetailInfoSection: View {
  let clothing: Clothing
  @EnvironmentObject var themeManager: ThemeManager

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Image(systemName: "info.circle.fill")
          .foregroundColor(themeManager.currentTheme.primaryColor)
        Text("詳細")
          .font(.title3)
          .fontWeight(.bold)
          .foregroundColor(themeManager.currentTheme.primaryColor)
      }

      VStack(spacing: 12) {
        HStack {
          Image(systemName: "calendar")
            .foregroundColor(.blue)
            .frame(width: 20)
          Text("登録日")
            .font(.subheadline)
            .foregroundColor(.secondary)
          Spacer()
          Text(DateFormatter.shortDate.string(from: clothing.createdAt))
            .font(.subheadline)
            .fontWeight(.medium)
        }
      }
      .padding()
      .background(Color(.secondarySystemBackground))
      .cornerRadius(16)
    }
  }
}

struct ClothingCategorySection: View {
  let clothing: Clothing
  @EnvironmentObject var themeManager: ThemeManager
  @EnvironmentObject var categoryManager: CategoryManager

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Image(systemName: "tag.fill")
          .foregroundColor(themeManager.currentTheme.primaryColor)
        Text("カテゴリ")
          .font(.title3)
          .fontWeight(.bold)
          .foregroundColor(themeManager.currentTheme.primaryColor)
      }

      if !clothing.categoryIds.isEmpty {
        FlowLayout(spacing: 8) {
          ForEach(categoryManager.getCategoryNames(for: clothing.categoryIds), id: \.self) { category in
            CompactTagView(text: category, color: themeManager.currentTheme.primaryColor)
          }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
      } else {
        HStack {
          Image(systemName: "tag.dashed")
            .foregroundColor(.secondary)
          Text("カテゴリ未設定")
            .foregroundColor(.secondary)
          Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
      }
    }
  }
}

struct ClothingBrandSection: View {
  let clothing: Clothing
  @EnvironmentObject var themeManager: ThemeManager
  @EnvironmentObject var brandManager: BrandManager

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Image(systemName: "star.fill")
          .foregroundColor(.purple)
        Text("ブランド")
          .font(.title3)
          .fontWeight(.bold)
          .foregroundColor(.purple)
      }

      if let brandId = clothing.brandId {
        CompactTagView(text: brandManager.getBrandName(for: brandId), color: .purple)
          .padding()
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color(.secondarySystemBackground))
          .cornerRadius(16)
      } else {
        HStack {
          Image(systemName: "star.dashed")
            .foregroundColor(.secondary)
          Text("ブランド未設定")
            .foregroundColor(.secondary)
          Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
      }
    }
  }
}

struct ClothingColorSection: View {
  let clothing: Clothing
  @EnvironmentObject var themeManager: ThemeManager

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Image(systemName: "paintpalette.fill")
          .foregroundColor(themeManager.currentTheme.primaryColor)
        Text("カラー")
          .font(.title3)
          .fontWeight(.bold)
          .foregroundColor(themeManager.currentTheme.primaryColor)
      }

      Group {
        if !clothing.colors.isEmpty {
          HStack(spacing: 12) {
            ForEach(clothing.colors.prefix(10), id: \.id) { colorData in
              Circle()
                .fill(Color(colorData.color))
                .frame(width: 36, height: 36)
                .overlay(
                  Circle()
                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            }

            if clothing.colors.count > 10 {
              Text("+\(clothing.colors.count - 10)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .padding(.leading, 8)
            }

            Spacer()
          }
          .padding()
          .background(Color(.secondarySystemBackground))
          .cornerRadius(16)
        } else {
          HStack {
            Image(systemName: "circle.dashed")
              .foregroundColor(.secondary)
            Text("カラー未設定")
              .foregroundColor(.secondary)
            Spacer()
          }
          .padding()
          .background(Color(.secondarySystemBackground))
          .cornerRadius(16)
        }
      }
    }
  }
}

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
        purchaseDate: clothing.createdAt
      )

      // 統計カード
      VStack(spacing: 16) {
        let daysSinceCreation = max(Calendar.current.dateComponents([.day], from: clothing.createdAt, to: Date()).day ?? 0, 1)
        let wearCount = viewModel.getWearCount(for: clothingId)

        // 上段：基本情報
        HStack(spacing: 12) {
          ImprovedStatisticCardView(
            icon: "calendar",
            value: "\(daysSinceCreation)",
            label: "購入から\n何日",
            color: .indigo
          )

          ImprovedStatisticCardView(
            icon: "tshirt.fill",
            value: "\(wearCount)",
            label: clothing.wearLimit != nil ? "\(wearCount)/\(clothing.wearLimit!) 回" : "着用回数",
            color: .orange,
            progress: clothing.wearLimit != nil ? Double(wearCount) / Double(clothing.wearLimit!) : nil
          )
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
              color: .cyan
            )
          } else {
            ImprovedStatisticCardView(
              icon: "clock.arrow.circlepath",
              value: "-",
              label: "平均間隔\n(日)",
              color: .gray
            )
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
              color: color
            )
          } else {
            ImprovedStatisticCardView(
              icon: "clock.badge",
              value: "-",
              label: "未着用",
              color: .gray
            )
          }
        }

        // 下段：コスト分析
        HStack(spacing: 12) {
          // 着用単価
          if let price = clothing.purchasePrice {
            if wearCount > 0 {
              let costPerWear = price / Double(wearCount)
              let targetWears = clothing.wearLimit ?? 30 // デフォルト30回
              let targetCost = price / Double(targetWears)

              ImprovedStatisticCardView(
                icon: "yensign.circle",
                value: "¥\(Int(costPerWear))",
                label: "着用単価",
                color: .mint,
                progress: max(0, min(1.0 - (costPerWear - targetCost) / price, 1.0))
              )
            } else {
              ImprovedStatisticCardView(
                icon: "yensign.circle",
                value: "¥\(Int(price))",
                label: "着用単価",
                color: .gray
              )
            }
          } else {
            ImprovedStatisticCardView(
              icon: "yensign.circle",
              value: "-",
              label: "着用単価",
              color: .gray
            )
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
              progress: min(progress, 1.0)
            )
          } else {
            ImprovedStatisticCardView(
              icon: "target",
              value: "-",
              label: "目標未設定",
              color: .gray
            )
          }
        }
      }
    }
  }
}

struct ClothingWearCountSection: View {
  @Binding var clothing: Clothing
  @EnvironmentObject var themeManager: ThemeManager
  @EnvironmentObject var viewModel: ClothingViewModel

  // 今日着用したかどうかを判定
  private var hasWornToday: Bool {
    let today = Calendar.current.startOfDay(for: Date())
    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

    return viewModel.wearHistories.contains { history in
      history.clothingId == clothing.id &&
      history.wornAt >= today &&
      history.wornAt < tomorrow
    }
  }

  var body: some View {
    HStack(spacing: 16) {
      // チェックマーク（着用状態表示・タップで削除）
      Button(action: {
        if hasWornToday {
          // 着用記録を削除
          viewModel.removeWearHistoryForToday(for: clothing.id)

          // @Bindingの値も同期
          if let index = viewModel.clothes.firstIndex(where: { $0.id == clothing.id }) {
            clothing = viewModel.clothes[index]
          }
        }
      }) {
        Image(systemName: hasWornToday ? "checkmark.circle.fill" : "circle")
          .font(.title)
          .foregroundColor(hasWornToday ? .green : .gray)
      }
      .buttonStyle(PlainButtonStyle())
      .disabled(!hasWornToday) // 未着用時はタップ無効

      // 今日着る/着用取り消しボタン（状態によって切り替え）
      Button(action: {
        if hasWornToday {
          // 今日の着用履歴を削除
          viewModel.removeWearHistoryForToday(for: clothing.id)
        } else {
          // 着用履歴を追加
          viewModel.addWearHistory(for: clothing.id)
        }

        // @Bindingの値も同期
        if let index = viewModel.clothes.firstIndex(where: { $0.id == clothing.id }) {
          clothing = viewModel.clothes[index]
        }
      }) {
        HStack {
          Image(systemName: hasWornToday ? "xmark.circle.fill" : "plus.circle.fill")
            .font(.title2)
            .foregroundColor(.white)

          Text(hasWornToday ? "着用取り消し" : "今日着る")
            .font(.headline)
            .fontWeight(.medium)
            .foregroundColor(.white)

          Spacer()
        }
        .padding()
        .background(hasWornToday ? Color.red : themeManager.currentTheme.primaryColor)
        .cornerRadius(16)
      }
      .buttonStyle(PlainButtonStyle())
    }
    .padding(.vertical, 8)
  }
}

// MARK: - FlowLayout（変更なし）

struct FlowLayout: Layout {
  let spacing: CGFloat

  init(spacing: CGFloat = 8) {
    self.spacing = spacing
  }

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let result = FlowResult(
      in: proposal.replacingUnspecifiedDimensions().width,
      subviews: subviews,
      spacing: spacing
    )
    return result.bounds
  }

  func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
    let result = FlowResult(
      in: proposal.replacingUnspecifiedDimensions().width,
      subviews: subviews,
      spacing: spacing
    )
    for (index, subview) in subviews.enumerated() {
      subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX,
                               y: bounds.minY + result.frames[index].minY),
                   proposal: ProposedViewSize(result.frames[index].size))
    }
  }
}

struct FlowResult {
  var bounds = CGSize.zero
  var frames: [CGRect] = []

  init(in maxWidth: CGFloat, subviews: LayoutSubviews, spacing: CGFloat) {
    var origin = CGPoint.zero
    var rowHeight: CGFloat = 0

    for subview in subviews {
      let size = subview.sizeThatFits(.unspecified)

      if origin.x + size.width > maxWidth {
        origin.x = 0
        origin.y += rowHeight + spacing
        rowHeight = 0
      }

      frames.append(CGRect(origin: origin, size: size))
      origin.x += size.width + spacing
      rowHeight = max(rowHeight, size.height)
    }

    bounds = CGSize(width: maxWidth, height: origin.y + rowHeight)
  }
}
