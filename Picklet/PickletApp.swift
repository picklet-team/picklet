//
//  PickletApp.swift
//  Picklet
//
//  Created by al dente on 2025/04/12.
//

import SwiftUI

@main
struct PickletApp: App {
  // ログイン状態は常にtrueとして扱う
  @AppStorage("isLoggedIn") var isLoggedIn = true
  @AppStorage("colorSchemePreference") private var colorSchemePreference: String = ColorSchemeSelection.system.rawValue
  @StateObject private var viewModel = ClothingViewModel()

  private var selectedColorScheme: ColorSchemeSelection {
    ColorSchemeSelection(rawValue: colorSchemePreference) ?? .system
  }

  var body: some Scene {
    WindowGroup {
      // GlobalOverlayContainerViewでラップして全画面オーバーレイを可能に
      GlobalOverlayContainerView {
        // ログイン画面を表示せず、常にMainTabViewを表示
        MainTabView()
          .environmentObject(viewModel)
          .task {
            // Properly call the async syncIfNeeded method
            await viewModel.syncIfNeeded()
          }
      }
      .preferredColorScheme(selectedColorScheme.colorScheme)
    }
  }
}
