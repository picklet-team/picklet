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
    
    #if os(macOS) || os(iOS)
    func testWeatherServiceEdgeCases() {
        let weatherService = WeatherService()
        
        let nonExistentCity = "存在しない都市"
        weatherService.cachedWeather = Weather(
          city: "東京",
          date: "2025-05-02",
          temperature: 25.0,
          condition: "晴れ",
          icon: "sunny",
          updated_at: "2025-05-02T10:00:00Z"
        )
        
        let expectation1 = XCTestExpectation(description: "Get weather for non-existent city")
        
        Task {
            let weatherForNonExistentCity = await weatherService.getCurrentWeather(forCity: nonExistentCity)
            XCTAssertNil(weatherForNonExistentCity)
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: 5.0)
        
        let expectation2 = XCTestExpectation(description: "Save and retrieve weather")
        
        Task {
            do {
                let weatherToSave = Weather(
                  city: "京都",
                  date: "2025-05-02",
                  temperature: 20.0,
                  condition: "雨",
                  icon: "rainy",
                  updated_at: "2025-05-02T11:00:00Z"
                )
                
                try await weatherService.saveWeather(weatherToSave)
                
                XCTAssertEqual(weatherService.cachedWeather?.city, "京都")
                XCTAssertEqual(weatherService.cachedWeather?.temperature, 20.0)
                
                let retrievedWeather = await weatherService.getCurrentWeather(forCity: "京都")
                XCTAssertEqual(retrievedWeather?.city, "京都")
                XCTAssertEqual(retrievedWeather?.temperature, 20.0)
                
                expectation2.fulfill()
            } catch {
                XCTFail("Weather save should not throw an error in this test")
                expectation2.fulfill()
            }
        }
        
        wait(for: [expectation2], timeout: 5.0)
        
        let expectation3 = XCTestExpectation(description: "Handle extreme weather values")
        
        Task {
            let extremeWeather = Weather(
              city: "極端な気象",
              date: "2025-05-02",
              temperature: -100.0,
              condition: "異常気象",
              icon: "extreme",
              updated_at: "2025-05-02T12:00:00Z"
            )
            
            weatherService.cachedWeather = extremeWeather
            let retrievedExtremeWeather = await weatherService.getCurrentWeather(forCity: "極端な気象")
            
            XCTAssertEqual(retrievedExtremeWeather?.temperature, -100.0)
            expectation3.fulfill()
        }
        
        wait(for: [expectation3], timeout: 5.0)
    }
    #endif
    
    // Linux環境でもテストが実行されるようにするための特別なセットアップ
    static var allTests = [
        ("testClothingModel", testClothingModel),
        ("testWeatherModel", testWeatherModel),
        // ClothingImageモデルとWeatherServiceのテストはLinux環境では実行されません
    ]
}
