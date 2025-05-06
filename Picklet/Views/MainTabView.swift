//
//  MainTabView.swift
//  Picklet
//
//  Created by al dente on 2025/04/25.
//

import SwiftUI

struct MainTabView: View {
  @EnvironmentObject private var viewModel: ClothingViewModel
  var body: some View {
    TabView {
      ClothingListView()
        .environmentObject(viewModel)
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
  }
}
