//
//  LoginViewModel.swift
//  MyApp
//
//  Created by al dente on 2025/04/25.
//

// ViewModels/LoginViewModel.swift
import Foundation

@MainActor
class LoginViewModel: ObservableObject {
  @Published var email = ""
  @Published var password = ""
  @Published var errorMessage: String?
  @Published var isLoading = false
  @Published var isLoggedIn = false

  func login() async {
    do {
      try await SupabaseService.shared.signIn(email: email, password: password)
      errorMessage = nil
    } catch {
      errorMessage = "ログインに失敗しました: \(error.localizedDescription)"
    }
  }

  func signUp() async {
    do {
      try await SupabaseService.shared.signUp(email: email, password: password)
      errorMessage = nil
    } catch {
      errorMessage = "サインアップに失敗しました: \(error.localizedDescription)"
    }
  }
}
