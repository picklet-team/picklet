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
    
    // Linux環境ではClothingImageモデルがPickletCoreモジュールに含まれていないため、
    #if os(macOS) || os(iOS)
    func testClothingImageModel() {
        // テスト用の日付文字列
        let dateStr = "2025-05-01T10:00:00Z"
        
        // ClothingImageインスタンスの作成テスト
        let id = UUID()
        let clothingId = UUID()
        let userId = UUID()
        let clothingImage = ClothingImage(
          id: id,
          clothing_id: clothingId,
          user_id: userId,
          original_url: "https://example.com/original.jpg",
          mask_url: "https://example.com/mask.jpg",
          result_url: "https://example.com/result.jpg",
          created_at: dateStr,
          updated_at: dateStr
        )
        
        // 各プロパティが正しく設定されているかテスト
        XCTAssertEqual(clothingImage.id, id)
        XCTAssertEqual(clothingImage.clothing_id, clothingId)
        XCTAssertEqual(clothingImage.user_id, userId)
        XCTAssertEqual(clothingImage.original_url, "https://example.com/original.jpg")
        XCTAssertEqual(clothingImage.mask_url, "https://example.com/mask.jpg")
        XCTAssertEqual(clothingImage.result_url, "https://example.com/result.jpg")
        XCTAssertEqual(clothingImage.created_at, dateStr)
        XCTAssertEqual(clothingImage.updated_at, dateStr)
        
        let clothingImageWithNil = ClothingImage(
          id: id,
          clothing_id: clothingId,
          user_id: userId,
          original_url: "https://example.com/original.jpg",
          mask_url: nil,
          result_url: nil,
          created_at: dateStr,
          updated_at: dateStr
        )
        
        XCTAssertNil(clothingImageWithNil.mask_url)
        XCTAssertNil(clothingImageWithNil.result_url)
    }
    #endif
    
    // Linux環境でもテストが実行されるようにするための特別なセットアップ
    static var allTests = [
        ("testClothingModel", testClothingModel),
        ("testWeatherModel", testWeatherModel),
        #if os(macOS) || os(iOS)
        ("testClothingImageModel", testClothingImageModel),
        #endif
    ]
}
