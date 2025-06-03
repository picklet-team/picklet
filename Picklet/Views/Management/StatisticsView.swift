import SwiftUI

struct StatisticsView: View {
  @EnvironmentObject var themeManager: ThemeManager

  var body: some View {
    List {
      Section("基本統計") {
        StatRowView(title: "総衣類数", value: "42着")
        StatRowView(title: "平均購入価格", value: "¥3,500")
        StatRowView(title: "最も多いカテゴリ", value: "Tシャツ")
        StatRowView(title: "最も多い色", value: "ブルー")
      }

      Section("購入履歴") {
        StatRowView(title: "今月の購入数", value: "3着")
        StatRowView(title: "今年の購入数", value: "18着")
        StatRowView(title: "総購入金額", value: "¥147,000")
      }

      Section(footer: Text("統計データは登録された衣類情報から自動計算されます。")) {
        EmptyView()
      }
    }
    .navigationTitle("統計情報")
    .navigationBarTitleDisplayMode(.inline)
  }
}

struct StatRowView: View {
  let title: String
  let value: String

  var body: some View {
    HStack {
      Text(title)
        .font(.body)

      Spacer()

      Text(value)
        .font(.body)
        .fontWeight(.semibold)
        .foregroundColor(.secondary)
    }
    .padding(.vertical, 4)
  }
}
