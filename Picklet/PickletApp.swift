//
//  PickletApp.swift
//  Picklet
//
//  Created by al dente on 2025/04/12.
//

import SwiftUI

@main
struct PickletApp: App {
  @AppStorage("isLoggedIn") var isLoggedIn = false
  @AppStorage("colorSchemePreference") private var colorSchemePreference: String = ColorSchemeSelection.system.rawValue
  @StateObject private var viewModel = ClothingViewModel()

  private var selectedColorScheme: ColorSchemeSelection {
    ColorSchemeSelection(rawValue: colorSchemePreference) ?? .system
  }

  var body: some Scene {
    WindowGroup {
      if isLoggedIn && SupabaseService.shared.currentUser != nil {
        MainTabView()
          .environmentObject(viewModel)
          .task {
            await viewModel.syncIfNeeded()
          }
          .preferredColorScheme(selectedColorScheme.colorScheme)
      } else {
        LoginView()
          .preferredColorScheme(selectedColorScheme.colorScheme)
      }
    }
  }
}
