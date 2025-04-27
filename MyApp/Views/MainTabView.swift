//
//  MainTabView.swift
//  MyApp
//
//  Created by al dente on 2025/04/25.
//


import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            ClothingListView()
                .tabItem {
                    Label("クローゼット", systemImage: "tshirt")
                }

            WeatherLoaderView()
                .tabItem {
                    Label("今日のコーデ", systemImage: "sun.max")
                }

            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gear")
                }
        }
    }
}
