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
          //                    Label("クローゼット", systemImage: "tshirt")
          Image(systemName: "tshirt")

        }

      WeatherLoaderView()
        .tabItem {
//          Label("今日のコーデ", systemImage: "sun.max")
          Image(systemName: "sun.max")
        }

      SettingsView()
        .tabItem {
          //                    Label("設定", systemImage: "gear")
          Image(systemName: "gear")
        }
    }
  }
}
