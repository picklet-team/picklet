//
//  MyAppTests.swift
//  MyAppTests
//
//  Created by al dente on 2025/04/12.
//

import Testing

@testable import MyApp

struct MyAppTests {

  @Test func example() async throws {
    // Write your test here and use APIs like `#expect(...)` to check expected conditions.
  }

  @Test func testLogin() async throws {
    let viewModel = LoginViewModel()
    viewModel.email = "test@example.com"
    viewModel.password = "password123"

    await viewModel.login()

    XCTAssertTrue(viewModel.isLoggedIn)
    XCTAssertNil(viewModel.errorMessage)
  }

}
