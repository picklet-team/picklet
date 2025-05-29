//
//  SettingsView.swift
//  Picklet
//
//  Created by al dente on 2025/04/25.
//

import SwiftUI

struct SettingsView: View {
  @Environment(\.dismiss) var dismiss
  @AppStorage("autoCropEnabled") private var autoCropEnabled: Bool = true
  @AppStorage("colorSchemePreference") private var colorSchemePreference: String = ColorSchemeSelection.system.rawValue
  @AppStorage("selectedTheme") private var selectedTheme: String = ThemeColor.blue.rawValue

  @EnvironmentObject var themeManager: ThemeManager // 追加
  @Environment(\.colorScheme) var systemColorScheme

  private var selectedColorScheme: ColorSchemeSelection {
    ColorSchemeSelection(rawValue: colorSchemePreference) ?? .system
  }

  private var currentTheme: ThemeColor {
    ThemeColor(rawValue: selectedTheme) ?? .blue
  }

  private var appVersion: String {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "不明"
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "不明"
    return "バージョン \(version) (\(build))"
  }

  var body: some View {
    NavigationView {
      ZStack {
        // 背景グラデーション
        themeManager.currentTheme.backgroundGradient
          .ignoresSafeArea()

        Form {
          Section(header: Text("切り抜き設定")) {
            Toggle("自動で切り抜く", isOn: $autoCropEnabled)
              .tint(themeManager.currentTheme.primaryColor)
          }

          Section(header: Text("カラースキーム")) {
            Picker("カラースキーム", selection: $colorSchemePreference) {
              ForEach(ColorSchemeSelection.allCases) { scheme in
                Text(scheme.displayName).tag(scheme.rawValue)
              }
            }
            .pickerStyle(SegmentedPickerStyle())
            .accentColor(themeManager.currentTheme.primaryColor)
          }

          Section(header: Text("テーマカラー")) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
              ForEach(ThemeColor.allCases) { theme in
                Button(
                  action: {
                    selectedTheme = theme.rawValue
                    themeManager.setTheme(theme)
                  },
                  label: {
                    Circle()
                      .fill(theme.primaryColor)
                      .frame(width: 40, height: 40)
                      .overlay(
                        Circle()
                          .stroke(currentTheme == theme ? Color.primary : Color.clear, lineWidth: 3)
                      )
                      .scaleEffect(currentTheme == theme ? 1.1 : 1.0)
                  }
                )
                .buttonStyle(PlainButtonStyle())
              }
            }
            .padding(.vertical, 8)

            Text("選択中: \(currentTheme.displayName)")
              .font(.caption)
              .foregroundColor(.secondary)
          }

          Section(header: Text("情報")) {
            Text(appVersion)
              .foregroundColor(.gray)
              .accessibility(identifier: "versionLabel")
          }
        }
        .scrollContentBackground(.hidden)
      }
      .navigationTitle("設定")
      .accessibility(identifier: "settingsView")
    }
    .accentColor(themeManager.currentTheme.accentColor)
  }
}
