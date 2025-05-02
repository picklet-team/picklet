//
//  LoginView.swift
//  MyApp
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

      SecureField("パスワード", text: $viewModel.password)
        .textFieldStyle(RoundedBorderTextFieldStyle())

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

      Button("新規登録") {
        Task { await viewModel.signUp() }
      }
    }
    .padding()
  }
}
