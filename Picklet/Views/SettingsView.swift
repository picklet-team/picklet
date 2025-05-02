//
//  SettingsView.swift
//  MyApp
//
//  Created by al dente on 2025/04/25.
//

import SwiftUI

struct SettingsView: View {
  @Environment(\.dismiss) var dismiss
  @AppStorage("autoCropEnabled") private var autoCropEnabled: Bool = true

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
        }
      }
      .navigationTitle("設定")
    }
  }
}
