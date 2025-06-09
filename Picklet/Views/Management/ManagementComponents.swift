import SwiftUI

// MARK: - Simple Management Row View

struct SimpleManagementRowView: View {
  let icon: String
  let title: String
  let subtitle: String
  let color: Color

  @EnvironmentObject var themeManager: ThemeManager

  var body: some View {
    HStack(spacing: 12) {
      ZStack {
        RoundedRectangle(cornerRadius: 8)
          .fill(color.opacity(0.1))
          .frame(width: 40, height: 40)

        Image(systemName: icon)
          .foregroundColor(color)
          .font(.system(size: 18, weight: .semibold))
      }

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.body)
          .fontWeight(.medium)
          .foregroundColor(.primary)

        Text(subtitle)
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
    .padding(.vertical, 4)
  }
}

// MARK: - Default Wear Limit Setting View

struct DefaultWearLimitSettingView: View {
  @Binding var tempWearLimit: String
  @EnvironmentObject var defaultSettingsManager: DefaultSettingsManager
  @EnvironmentObject var themeManager: ThemeManager

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 12) {
        // アイコン
        ZStack {
          RoundedRectangle(cornerRadius: 8)
            .fill(themeManager.currentTheme.primaryColor.opacity(0.1))
            .frame(width: 40, height: 40)

          Image(systemName: "repeat.circle.fill")
            .foregroundColor(themeManager.currentTheme.primaryColor)
            .font(.system(size: 18, weight: .semibold))
        }

        // テキスト情報
        VStack(alignment: .leading, spacing: 2) {
          Text("デフォルト着用上限")
            .font(.body)
            .fontWeight(.medium)
            .foregroundColor(.primary)

          Text("新規登録時の着用上限回数")
            .font(.caption)
            .foregroundColor(.secondary)
        }

        Spacer()

        // 入力フィールド
        HStack(spacing: 8) {
          TextField("30", text: $tempWearLimit)
            .keyboardType(.numberPad)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .frame(width: 80)
            .multilineTextAlignment(.trailing)
            .accentColor(themeManager.currentTheme.accentColor)

          Text("回")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }

      // 説明文
      WearLimitExplanationView()
    }
    .padding(.vertical, 4)
  }
}

// MARK: - Wear Limit Explanation View

struct WearLimitExplanationView: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("🧥 30回を目安にする理由")
        .font(.subheadline)
        .fontWeight(.semibold)
        .foregroundColor(.primary)

      Text("「#30wears」は、服を買う前に「これを30回着られるか？」と考える、サステナブルなファッションの目安です。\nこのアプリでは、服を大切に長く使うための基準として「30回着用」を初期設定にしています。")
        .font(.caption)
        .foregroundColor(.secondary)
        .lineLimit(nil)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(.top, 8)
  }
}
