import SwiftUI

struct DataExportView: View {
  @EnvironmentObject var themeManager: ThemeManager
  @State private var showingExportAlert = false

  var body: some View {
    List {
      Section("エクスポート") {
        Button(action: { showingExportAlert = true }) {
          HStack {
            Image(systemName: "square.and.arrow.up")
              .foregroundColor(themeManager.currentTheme.primaryColor)

            VStack(alignment: .leading, spacing: 2) {
              Text("JSONファイルでエクスポート")
                .foregroundColor(.primary)
              Text("全データを JSON 形式で出力")
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()
          }
        }

        Button(action: { showingExportAlert = true }) {
          HStack {
            Image(systemName: "doc.text")
              .foregroundColor(themeManager.currentTheme.primaryColor)

            VStack(alignment: .leading, spacing: 2) {
              Text("CSVファイルでエクスポート")
                .foregroundColor(.primary)
              Text("表計算ソフトで開ける形式")
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()
          }
        }
      }

      Section("バックアップ") {
        Button(action: { showingExportAlert = true }) {
          HStack {
            Image(systemName: "icloud.and.arrow.up")
              .foregroundColor(themeManager.currentTheme.primaryColor)

            VStack(alignment: .leading, spacing: 2) {
              Text("iCloudにバックアップ")
                .foregroundColor(.primary)
              Text("データを安全にクラウド保存")
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()
          }
        }
      }

      Section(footer: Text("エクスポート機能は開発中です。")) {
        EmptyView()
      }
    }
    .navigationTitle("データエクスポート")
    .navigationBarTitleDisplayMode(.inline)
    .alert("準備中", isPresented: $showingExportAlert) {
      Button("OK") {}
    } message: {
      Text("この機能は現在開発中です。今後のアップデートをお待ちください。")
    }
  }
}
