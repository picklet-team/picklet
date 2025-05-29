//
//  PickletApp.swift
//  Picklet
//
//  Created by al dente on 2025/04/12.
//

import SwiftUI

@main
struct PickletApp: App {
  @StateObject private var clothingViewModel = ClothingViewModel()
  @StateObject private var themeManager = ThemeManager()

  // カラースキーム設定を監視
  @AppStorage("colorSchemePreference") private var colorSchemePreference: String = ColorSchemeSelection.system.rawValue

  var body: some Scene {
    WindowGroup {
      GlobalOverlayContainerView {
        MainTabView()
          .environmentObject(clothingViewModel)
          .environmentObject(themeManager)
          .accentColor(themeManager.currentTheme.accentColor)
      }
      .preferredColorScheme(getPreferredColorScheme()) // この行を追加
    }
  }

  private func getPreferredColorScheme() -> ColorScheme? {
    let selection = ColorSchemeSelection(rawValue: colorSchemePreference) ?? .system

    switch selection {
    case .light:
      return .light
    case .dark:
      return .dark
    case .system:
      return nil
    }
  }
}
