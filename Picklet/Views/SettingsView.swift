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

        Section {
          Button("ログアウト", role: .destructive) {
            Task {
              try? await SupabaseService.shared.signOut()
              dismiss()
            }
          }
          .accessibility(identifier: "logoutButton")
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
