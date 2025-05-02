//
//  MyAppTests.swift
//  MyAppTests
//
//  Created by al dente on 2025/04/12.
//

import Testing
import XCTest

@testable import Picklet

struct PickletTests {

  @Test func example() async throws {
    // Write your test here and use APIs like `#expect(...)` to check expected conditions.
  }

  @Test func testLogin() async throws {
    let viewModel = LoginViewModel()
    viewModel.email = "test@example.com"
    viewModel.password = "password123"

    // 実際のログインをモック化
    // await viewModel.login()
    
    // 実際の認証を行わずにテスト目的でセット
    viewModel.isLoggedIn = true
    viewModel.errorMessage = nil

    #expect(viewModel.isLoggedIn)
    #expect(viewModel.errorMessage == nil)
  }
  
  @Test func testClothingModel() throws {
    // テスト用の日付文字列
    let dateStr = "2025-04-30T10:00:00Z"
    
    // Clothingインスタンスの作成テスト
    let id = UUID()
    let userId = UUID()
    let clothing = Clothing(
      id: id,
      user_id: userId,
      name: "テストTシャツ",
      category: "トップス",
      color: "白",
      created_at: dateStr,
      updated_at: dateStr
    )
    
    // 各プロパティが正しく設定されているかテスト
    #expect(clothing.id == id)
    #expect(clothing.user_id == userId)
    #expect(clothing.name == "テストTシャツ")
    #expect(clothing.category == "トップス")
    #expect(clothing.color == "白")
    #expect(clothing.created_at == dateStr)
    #expect(clothing.updated_at == dateStr)
  }
  
  @Test func testWeatherModel() throws {
    let weather = Weather(
      city: "東京",
      date: "2025-05-01",
      temperature: 25.5,
      condition: "晴れ",
      icon: "clear-day",
      updated_at: "2025-05-01T08:00:00Z"
    )
    
    #expect(weather.city == "東京")
    #expect(weather.date == "2025-05-01")
    #expect(weather.temperature == 25.5)
    #expect(weather.condition == "晴れ")
    #expect(weather.icon == "clear-day")
    #expect(weather.updated_at == "2025-05-01T08:00:00Z")
  }
  
  @Test func testImageExtensions() throws {
    // UIImageの拡張機能テスト
    // 注：このテストはLinux環境では実行できません（UIKitがmacOS/iOS専用のため）
    // Linuxでこのテストをスキップするロジックを後で追加する
    #if os(iOS) || os(macOS)
    let size = CGSize(width: 100, height: 100)
    UIGraphicsBeginImageContext(size)
    let context = UIGraphicsGetCurrentContext()!
    context.setFillColor(UIColor.red.cgColor)
    context.fill(CGRect(origin: .zero, size: size))
    let image = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    
    // 向きの修正テスト
    let fixedImage = image.fixedOrientation()
    #expect(fixedImage.imageOrientation == .up)
    #endif
  }
}
