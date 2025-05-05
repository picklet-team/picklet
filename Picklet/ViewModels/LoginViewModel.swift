//
//  LoginViewModel.swift
//
//  Created by al dente on 2025/04/25.
//

import Foundation
import Supabase

@MainActor
class LoginViewModel: ObservableObject {
  @Published var email = ""
  @Published var password = ""
  @Published var errorMessage: String?
  @Published var isLoading = false
  @Published var isLoggedIn = false

  private let authService = AuthService.shared

  func login() async {
    isLoading = true
    do {
      try await authService.signIn(email: email, password: password)
      errorMessage = nil
    } catch {
      errorMessage = "ログインに失敗しました: \(error.localizedDescription)"
    }
    isLoading = false
  }

  func signUp() async {
    isLoading = true
    do {
      try await authService.signUp(email: email, password: password)
      errorMessage = nil
    } catch {
      errorMessage = "サインアップに失敗しました: \(error.localizedDescription)"
    }
    isLoading = false
  }
}
