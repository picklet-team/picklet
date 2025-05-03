//
//  LinuxTests.swift
//  PickletTests
//
//  Created on 2025/05/02.
//

import XCTest
@testable import Picklet

final class LinuxCompatibleTests: XCTestCase {
    
    func testClothingModel() {
        // テスト用の日付文字列
        let dateStr = "2025-04-30T10:00:00Z"
        
        // Clothingインスタンスの作成テスト
        let id = UUID()
        let userId = UUID()
        let clothing = Clothing(
          id: id,
          userID: userId,
          name: "テストTシャツ",
          category: "トップス",
          color: "白",
          createdAt: dateStr,
          updatedAt: dateStr
        )
        
        // 各プロパティが正しく設定されているかテスト
        XCTAssertEqual(clothing.id, id)
        XCTAssertEqual(clothing.userID, userId)
        XCTAssertEqual(clothing.name, "テストTシャツ")
        XCTAssertEqual(clothing.category, "トップス")
        XCTAssertEqual(clothing.color, "白")
        XCTAssertEqual(clothing.createdAt, dateStr)
        XCTAssertEqual(clothing.updatedAt, dateStr)
    }
    
    func testWeatherModel() {
        let weather = Weather(
          city: "東京",
          date: "2025-05-01",
          temperature: 25.5,
          condition: "晴れ",
          icon: "clear-day",
          updatedAt: "2025-05-01T08:00:00Z"
        )
        
        XCTAssertEqual(weather.city, "東京")
        XCTAssertEqual(weather.date, "2025-05-01")
        XCTAssertEqual(weather.temperature, 25.5)
        XCTAssertEqual(weather.condition, "晴れ")
        XCTAssertEqual(weather.icon, "clear-day")
        XCTAssertEqual(weather.updatedAt, "2025-05-01T08:00:00Z")
    }
    
    // Linux環境ではClothingImageモデルがPickletモジュールに含まれていない可能性があるためiOSとmacOS環境のみでテスト
    #if os(macOS) || os(iOS)
    func testClothingImageModel() {
        // テスト用の日付
        let createdDate = Date()
        let updatedDate = Date()
        
        // ClothingImageインスタンスの作成テスト
        let id = UUID()
        let clothingId = UUID()
        let userId = UUID()
        let clothingImage = ClothingImage(
          id: id,
          clothingId: clothingId,
          userId: userId,
          originalUrl: "https://example.com/original.jpg",
          maskUrl: "https://example.com/mask.jpg",
          resultUrl: "https://example.com/result.jpg",
          createdAt: createdDate,
          updatedAt: updatedDate
        )
        
        // 各プロパティが正しく設定されているかテスト
        XCTAssertEqual(clothingImage.id, id)
        XCTAssertEqual(clothingImage.clothingId, clothingId)
        XCTAssertEqual(clothingImage.userId, userId)
        XCTAssertEqual(clothingImage.originalUrl, "https://example.com/original.jpg")
        XCTAssertEqual(clothingImage.maskUrl, "https://example.com/mask.jpg")
        XCTAssertEqual(clothingImage.resultUrl, "https://example.com/result.jpg")
        XCTAssertEqual(clothingImage.createdAt, createdDate)
        XCTAssertEqual(clothingImage.updatedAt, updatedDate)
        
        let clothingImageWithNil = ClothingImage(
          id: id,
          clothingId: clothingId,
          userId: userId,
          originalUrl: "https://example.com/original.jpg",
          maskUrl: nil,
          resultUrl: nil,
          createdAt: createdDate,
          updatedAt: updatedDate
        )
        
        XCTAssertNil(clothingImageWithNil.maskUrl)
        XCTAssertNil(clothingImageWithNil.resultUrl)
    }
    #endif
    
    // Linux環境で動作しない可能性の高いテストケースは除外
    
    // Linux環境でもテストが実行されるようにするための特別なセットアップ
    static var allTests = [
        ("testClothingModel", testClothingModel),
        ("testWeatherModel", testWeatherModel)
        // ClothingImageモデルのテストはLinux環境では実行されません
    ]
}
