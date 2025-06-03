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

  @EnvironmentObject var themeManager: ThemeManager
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
                          .stroke(currentTheme == theme ? Color.primary : Color.clear, lineWidth: 3))
                      .scaleEffect(currentTheme == theme ? 1.1 : 1.0)
                  })
                  .buttonStyle(PlainButtonStyle())
              }
            }
            .padding(.vertical, 8)

            Text("選択中: \(currentTheme.displayName)")
              .font(.caption)
              .foregroundColor(.secondary)
          }

          // 情報セクションを拡張
          Section(header: Text("情報")) {
            // アプリバージョン
            Text(appVersion)
              .foregroundColor(.gray)
              .accessibility(identifier: "versionLabel")

            // サポートページ
            HStack {
              Image(systemName: "questionmark.circle")
                .foregroundColor(themeManager.currentTheme.primaryColor)
              Text("サポート")
              Spacer()
              Image(systemName: "arrow.up.right")
                .foregroundColor(.secondary)
                .font(.caption)
            }
            .contentShape(Rectangle())
            .onTapGesture {
              if let url = URL(string: "https://support.picklet.app") {
                UIApplication.shared.open(url)
              }
            }

            // プライバシーポリシー
            HStack {
              Image(systemName: "hand.raised")
                .foregroundColor(themeManager.currentTheme.primaryColor)
              Text("プライバシーポリシー")
              Spacer()
              Image(systemName: "arrow.up.right")
                .foregroundColor(.secondary)
                .font(.caption)
            }
            .contentShape(Rectangle())
            .onTapGesture {
              if let url = URL(string: "https://privacy.picklet.app") {
                UIApplication.shared.open(url)
              }
            }
          }

          // ライセンス情報セクションを修正
          Section(header: Text("ライセンス")) {
            // OpenWeatherMapライセンス情報
            VStack(alignment: .leading, spacing: 12) {
              // ヘッダー
              HStack {
                Image(systemName: "cloud.sun.fill")
                  .foregroundColor(themeManager.currentTheme.primaryColor)
                Text("天気情報")
                  .font(.subheadline)
                  .fontWeight(.semibold)
              }

              // ライセンス内容
              VStack(alignment: .leading, spacing: 8) {
                Text("Weather data provided by OpenWeatherMap.")
                  .font(.footnote)
                  .foregroundColor(.secondary)

                Text("This data is made available under the following licenses:")
                  .font(.footnote)
                  .foregroundColor(.secondary)

                // ODbL情報
                HStack(alignment: .top, spacing: 6) {
                  Text("•")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                  VStack(alignment: .leading, spacing: 4) {
                    Text("Data/Databases:")
                      .font(.footnote)
                      .foregroundColor(.secondary)
                    Group {
                      Text("Open Database License (") +
                      Text("ODbL")
                        .foregroundColor(themeManager.currentTheme.primaryColor)
                        .underline() +
                      Text(")")
                    }
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .onTapGesture {
                      if let url = URL(string: "https://opendatacommons.org/licenses/odbl/") {
                        UIApplication.shared.open(url)
                      }
                    }
                  }
                }

                // CC BY-SA 4.0情報
                HStack(alignment: .top, spacing: 6) {
                  Text("•")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                  VStack(alignment: .leading, spacing: 4) {
                    Text("Content descriptions:")
                      .font(.footnote)
                      .foregroundColor(.secondary)
                    Group {
                      Text("Creative Commons (") +
                      Text("CC BY-SA 4.0")
                        .foregroundColor(themeManager.currentTheme.primaryColor)
                        .underline() +
                      Text(")")
                    }
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .onTapGesture {
                      if let url = URL(string: "https://creativecommons.org/licenses/by-sa/4.0/") {
                        UIApplication.shared.open(url)
                      }
                    }
                  }
                }
              }
            }
            .padding(.vertical, 4)
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
