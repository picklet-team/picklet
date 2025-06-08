import SwiftUI

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
    for weekOffset in (0 ..< 20).reversed() {
      guard let weekStart = calendar.date(byAdding: .weekOfYear,
                                          value: -weekOffset,
                                          to: thisMonday)
      else {
        continue
      }

      var week: [Date] = []
      for dayOffset in 0 ..< 7 {
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
      return Color(.systemGray3)
    }

    // 未来の日付は表示しない
    if date > Date() {
      return Color.clear
    }

    // 着用したかどうかのみ
    if hasWornOnDate(date) {
      return .green
    } else {
      return Color(.systemGray5)
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
          let firstDate = weeksData[weekIndex].first
    else { return false }

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
            // 月ラベル（横軸）
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
            ForEach(0 ..< 7) { dayIndex in
              HStack(spacing: 2) {
                // 曜日ラベル（縦軸のみ）
                Text(["月", "火", "水", "木", "金", "土", "日"][dayIndex])
                  .font(.caption2)
                  .foregroundColor(.secondary)
                  .frame(width: 14, height: 14)

                ForEach(Array(weeksData.enumerated()), id: \.offset) { _, week in
                  if dayIndex < week.count {
                    let date = week[dayIndex]

                    Rectangle()
                      .fill(colorForDate(date))
                      .frame(width: 14, height: 14)
                      .cornerRadius(3)
                      .overlay(
                        Group {
                          if isToday(date) &&
                            date >= Calendar.current.startOfDay(for: purchaseDate) {
                            // 今日マーカー（購入後のみ）
                            Rectangle()
                              .stroke(Color.primary, lineWidth: 1.5)
                              .cornerRadius(3)
                          }
                        })
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
