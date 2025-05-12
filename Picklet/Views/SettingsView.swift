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

  @Environment(\.colorScheme) var systemColorScheme

  private var selectedColorScheme: ColorSchemeSelection {
    ColorSchemeSelection(rawValue: colorSchemePreference) ?? .system
  }

  // アプリバージョンを取得
  private var appVersion: String {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "不明"
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "不明"
    return "バージョン \(version) (\(build))"
  }

  var body: some View {
    NavigationView {
      Form {
        Section(header: Text("切り抜き設定")) {
          Toggle("自動で切り抜く", isOn: $autoCropEnabled)
        }

        Section(header: Text("カラースキーム")) {
          Picker("カラースキーム", selection: $colorSchemePreference) {
            ForEach(ColorSchemeSelection.allCases) { scheme in
              Text(scheme.displayName).tag(scheme.rawValue)
            }
          }
          .pickerStyle(SegmentedPickerStyle())
        }

        Section(header: Text("情報")) {
          Text(appVersion)
            .foregroundColor(.gray)
            .accessibility(identifier: "versionLabel")
        }
      }
      .navigationTitle("設定")
      .accessibility(identifier: "settingsView")
    }
  }
}
