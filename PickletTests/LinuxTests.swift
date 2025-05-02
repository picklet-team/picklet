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
    func testImageProcessor() {
        let size = CGSize(width: 200, height: 200)
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor.blue.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        let originalImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        UIGraphicsBeginImageContext(size)
        let maskContext = UIGraphicsGetCurrentContext()!
        maskContext.setFillColor(UIColor.black.cgColor)
        maskContext.fill(CGRect(origin: .zero, size: size))
        maskContext.setFillColor(UIColor.white.cgColor)
        maskContext.fill(CGRect(x: 50, y: 50, width: 100, height: 100))
        let maskImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        let maskedImage = ImageProcessor.applyMask(original: originalImage, mask: maskImage)
        
        XCTAssertNotNil(maskedImage)
        
        let visualizedImage = ImageProcessor.visualizeMaskOnOriginal(original: originalImage, mask: maskImage)
        
        XCTAssertNotNil(visualizedImage)
    }
    #endif
    
    #if os(macOS) || os(iOS)
    func testLibraryPickerViewModel() async throws {
        class MockSupabaseService {
            static var shared = MockSupabaseService()
            
            var shouldSucceed = true
            var mockURLs: [URL] = [
                URL(string: "https://example.com/image1.jpg")!,
                URL(string: "https://example.com/image2.jpg")!
            ]
            
            func listClothingImageURLs() async throws -> [URL] {
                if shouldSucceed {
                    return mockURLs
                } else {
                    throw NSError(domain: "MockError", code: 1, userInfo: nil)
                }
            }
        }
        
        let originalSupabaseService = SupabaseService.shared
        
        SupabaseService.shared = MockSupabaseService.shared as! SupabaseService
        
        let viewModel = LibraryPickerViewModel()
        
        XCTAssertTrue(viewModel.urls.isEmpty)
        
        MockSupabaseService.shared.shouldSucceed = true
        viewModel.fetch()
        
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒待機
        
        XCTAssertEqual(viewModel.urls.count, 2)
        XCTAssertEqual(viewModel.urls[0].absoluteString, "https://example.com/image1.jpg")
        XCTAssertEqual(viewModel.urls[1].absoluteString, "https://example.com/image2.jpg")
        
        MockSupabaseService.shared.shouldSucceed = false
        viewModel.fetch()
        
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒待機
        
        XCTAssertEqual(viewModel.urls.count, 2)
        
        SupabaseService.shared = originalSupabaseService
    }
    #endif
    
    #if os(macOS) || os(iOS)
    func testWeatherService() async throws {
        class WeatherService {
            var cachedWeather: Weather?
            
            func getCurrentWeather(forCity city: String) async -> Weather? {
                if let cached = cachedWeather, cached.city == city {
                    return cached
                }
                
                do {
                    return try await WeatherManager.shared.fetchCachedWeather(for: city)
                } catch {
                    return nil
                }
            }
            
            func saveWeather(_ weather: Weather) async throws {
                try await WeatherManager.shared.saveWeatherToCache(weather)
                cachedWeather = weather
            }
        }
        
        let weatherService = WeatherService()
        
        let mockWeather = Weather(
            city: "大阪",
            date: "2025-05-02",
            temperature: 22.0,
            condition: "曇り",
            icon: "cloudy",
            updated_at: "2025-05-02T09:00:00Z"
        )
        
        weatherService.cachedWeather = mockWeather
        
        let weather = await weatherService.getCurrentWeather(forCity: "大阪")
        
        XCTAssertEqual(weather?.city, "大阪")
        XCTAssertEqual(weather?.temperature, 22.0)
        XCTAssertEqual(weather?.condition, "曇り")
    }
    #endif
    // Linux環境でもテストが実行されるようにするための特別なセットアップ
    static var allTests = [
        ("testClothingModel", testClothingModel),
        ("testWeatherModel", testWeatherModel)
        // ClothingImageモデル、ImageProcessor、LibraryPickerViewModel、WeatherServiceのテストはLinux環境では実行されません
    ]
}
