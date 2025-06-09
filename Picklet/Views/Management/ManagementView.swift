import SwiftUI

struct ManagementView: View {
  @EnvironmentObject var themeManager: ThemeManager
  @EnvironmentObject var defaultSettingsManager: DefaultSettingsManager
  @State private var tempWearLimit: String = ""

  var body: some View {
    NavigationView {
      ZStack {
        // 背景グラデーション
        themeManager.currentTheme.backgroundGradient
          .ignoresSafeArea()

        List {
          Section("データ管理") {
            NavigationLink(destination: ReferenceDataManagementView(dataType: .category)) {
              SimpleManagementRowView(
                icon: "tag.fill",
                title: "カテゴリ",
                subtitle: "衣類のカテゴリを管理",
                color: themeManager.currentTheme.primaryColor)
            }

            NavigationLink(destination: ReferenceDataManagementView(dataType: .brand)) {
              SimpleManagementRowView(
                icon: "star.fill",
                title: "ブランド",
                subtitle: "お気に入りブランドを管理",
                color: themeManager.currentTheme.primaryColor)
            }

            NavigationLink(destination: ReferenceDataManagementView(dataType: .tag)) {
              SimpleManagementRowView(
                icon: "number",
                title: "タグ",
                subtitle: "カスタムタグを管理",
                color: themeManager.currentTheme.primaryColor)
            }
          }

          Section("アプリ設定") {
            DefaultWearLimitSettingView(tempWearLimit: $tempWearLimit)
              .environmentObject(defaultSettingsManager)
          }
        }
        .background(.clear) // 背景を透明に設定
        .scrollContentBackground(.hidden) // デフォルトの背景を非表示
      }
      .navigationTitle("管理")
      .navigationBarTitleDisplayMode(.large)
      .onAppear {
        setupInitialValues()
      }
      .onChange(of: tempWearLimit) { _, newValue in
        if newValue.isEmpty {
          defaultSettingsManager.saveDefaultWearLimit(30)
        } else if let limit = Int(newValue), limit > 0 {
          defaultSettingsManager.saveDefaultWearLimit(limit)
        }
      }
    }
    .accentColor(themeManager.currentTheme.accentColor)
  }

  private func setupInitialValues() {
    if let defaultLimit = defaultSettingsManager.defaultWearLimit {
      tempWearLimit = String(defaultLimit)
    } else {
      tempWearLimit = "30"
      defaultSettingsManager.saveDefaultWearLimit(30)
    }
  }
}
