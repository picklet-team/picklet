//
//  MyAppApp.swift
//  MyApp
//
//  Created by al dente on 2025/04/12.
//

import SwiftUI

@main
struct PickletApp: App {
  @AppStorage("isLoggedIn") var isLoggedIn = false

  var body: some Scene {
    WindowGroup {
      if isLoggedIn && SupabaseService.shared.currentUser != nil {
        MainTabView()
      } else {
        LoginView()
      }
    }
  }
}
