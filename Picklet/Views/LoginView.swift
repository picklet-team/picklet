//
//  LoginView.swift
//  Picklet
//
//  Created by al dente on 2025/04/25.
//

// Views/LoginView.swift
import SwiftUI

struct LoginView: View {
  @StateObject private var viewModel = LoginViewModel()

  var body: some View {
    VStack(spacing: 16) {
      Text("ログイン")
        .font(.largeTitle)
        .bold()

      TextField("メールアドレス", text: $viewModel.email)
        .autocapitalization(.none)
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .keyboardType(.emailAddress)
        .accessibility(identifier: "emailTextField")

      SecureField("パスワード", text: $viewModel.password)
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .accessibility(identifier: "passwordTextField")

      if let error = viewModel.errorMessage {
        Text(error)
          .foregroundColor(.red)
          .font(.caption)
      }

      if viewModel.isLoading {
        ProgressView()
      }

      Button("ログイン") {
        Task {
          await viewModel.login()
        }
      }
      .accessibility(identifier: "loginButton")

      Button("新規登録") {
        Task { await viewModel.signUp() }
      }
      .accessibility(identifier: "signUpButton")
    }
    .padding()
  }
}
