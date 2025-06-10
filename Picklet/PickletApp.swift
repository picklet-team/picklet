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
  @StateObject private var referenceDataManager = ReferenceDataManager() // 変更
  @StateObject private var defaultSettingsManager = DefaultSettingsManager()

  // カラースキーム設定を監視
  @AppStorage("colorSchemePreference") private var colorSchemePreference: String = ColorSchemeSelection.system.rawValue

  var body: some Scene {
    WindowGroup {
      GlobalOverlayContainerView {
        MainTabView()
          .environmentObject(clothingViewModel)
          .environmentObject(themeManager)
          .environmentObject(referenceDataManager) // 変更
          .environmentObject(defaultSettingsManager)
          .accentColor(themeManager.currentTheme.accentColor)
      }
      .preferredColorScheme(getPreferredColorScheme())
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
