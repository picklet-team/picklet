import SwiftUI

struct ManagementView: View {
  @EnvironmentObject var themeManager: ThemeManager

  var body: some View {
    NavigationView {
      List {
        Section("データ管理") {
          NavigationLink(destination: CategoryManagementView()) {
            ManagementRowView(
              icon: "tag.fill",
              title: "カテゴリ",
              subtitle: "衣類のカテゴリを管理",
              color: .blue
            )
          }

          NavigationLink(destination: BrandManagementView()) {
            ManagementRowView(
              icon: "star.fill",
              title: "ブランド",
              subtitle: "お気に入りブランドを管理",
              color: .purple
            )
          }

          NavigationLink(destination: TagManagementView()) {
            ManagementRowView(
              icon: "number",
              title: "タグ",
              subtitle: "カスタムタグを管理",
              color: .green
            )
          }
        }

      }
      .navigationTitle("管理")
      .navigationBarTitleDisplayMode(.large)
    }
  }
}

struct ManagementRowView: View {
  let icon: String
  let title: String
  let subtitle: String
  let color: Color
  @EnvironmentObject var themeManager: ThemeManager

  var body: some View {
    HStack(spacing: 12) {
      // アイコン
      ZStack {
        RoundedRectangle(cornerRadius: 8)
          .fill(color.opacity(0.1))
          .frame(width: 40, height: 40)

        Image(systemName: icon)
          .foregroundColor(color)
          .font(.system(size: 18, weight: .semibold))
      }

      // テキスト情報
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.body)
          .fontWeight(.medium)
          .foregroundColor(.primary)

        Text(subtitle)
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Spacer()

      // 矢印
      Image(systemName: "chevron.right")
        .foregroundColor(.secondary)
        .font(.caption)
    }
    .padding(.vertical, 4)
  }
}
