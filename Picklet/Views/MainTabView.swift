//
//  MainTabView.swift
//  Picklet
//
//  Created by al dente on 2025/04/25.
//

import SwiftUI

struct MainTabView: View {
  @EnvironmentObject private var viewModel: ClothingViewModel
  @EnvironmentObject private var themeManager: ThemeManager

  var body: some View {
    TabView {
      ClothingListView()
        .tabItem {
          Image(systemName: "tshirt")
        }

      WeatherLoaderView()
        .tabItem {
          Image(systemName: "sun.max")
        }

      SettingsView()
        .tabItem {
          Image(systemName: "gear")
        }
    }
    .accentColor(themeManager.currentTheme.accentColor)
  }
}
