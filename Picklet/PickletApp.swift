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
  @StateObject private var viewModel = ClothingViewModel()

  var body: some Scene {
    WindowGroup {
      if isLoggedIn && SupabaseService.shared.currentUser != nil {
        MainTabView()
          .environmentObject(viewModel)
          .task {
            await viewModel.syncIfNeeded()
          }
      } else {
        LoginView()
      }
    }
  }
}
