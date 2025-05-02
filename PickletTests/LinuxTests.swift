//
//  LinuxTests.swift
//  PickletTests
//
//  Created on 2025/05/02.
//

import XCTest
@testable import PickletCore

final class LinuxCompatibleTests: XCTestCase {
    
    func testClothingModel() {
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
        XCTAssertEqual(clothing.id, id)
        XCTAssertEqual(clothing.user_id, userId)
        XCTAssertEqual(clothing.name, "テストTシャツ")
        XCTAssertEqual(clothing.category, "トップス")
        XCTAssertEqual(clothing.color, "白")
        XCTAssertEqual(clothing.created_at, dateStr)
        XCTAssertEqual(clothing.updated_at, dateStr)
    }
    
    func testWeatherModel() {
        let weather = Weather(
          city: "東京",
          date: "2025-05-01",
          temperature: 25.5,
          condition: "晴れ",
          icon: "clear-day",
          updated_at: "2025-05-01T08:00:00Z"
        )
        
        XCTAssertEqual(weather.city, "東京")
        XCTAssertEqual(weather.date, "2025-05-01")
        XCTAssertEqual(weather.temperature, 25.5)
        XCTAssertEqual(weather.condition, "晴れ")
        XCTAssertEqual(weather.icon, "clear-day")
        XCTAssertEqual(weather.updated_at, "2025-05-01T08:00:00Z")
    }
    
    // Linux環境でもテストが実行されるようにするための特別なセットアップ
    static var allTests = [
        ("testClothingModel", testClothingModel),
        ("testWeatherModel", testWeatherModel),
    ]
}
