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
  @State private var selectedTab = 0

  var body: some View {
    TabView(selection: $selectedTab) {
      ClothingListView()
        .tabItem {
          Image(systemName: "tshirt")
        }
        .tag(0)

      WeatherLoaderView()
        .tabItem {
          Image(systemName: "sun.max")
        }
        .tag(1)

      ManagementView()
        .tabItem {
          Image(systemName: "gear.circle")
        }
        .tag(4)

      SettingsView()
        .tabItem {
          Image(systemName: "gearshape")
        }
        .tag(5)
    }
    .accentColor(themeManager.currentTheme.accentColor)
  }
}
