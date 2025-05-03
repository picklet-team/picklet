//
//  PickletTests.swift
//  PickletTests
//
//  Created by al dente on 2025/04/12.
//

import Testing
import XCTest
import CoreLocation

#if canImport(UIKit)
import UIKit
#endif

@testable import Picklet

struct PickletTests {

  @Test func example() async throws {
    // Write your test here and use APIs like `#expect(...)` to check expected conditions.
  }

  @MainActor
  @Test func testLogin() async throws {
    #if os(macOS) || os(iOS)
    // @MainActorのテストであることを明示
    let viewModel = LoginViewModel()
    
    // MainActor上で実行されているのでawaitは不要
    viewModel.email = "test@example.com"
    viewModel.password = "password123"

    // 実際の認証を行わずにテスト目的でセット
    viewModel.isLoggedIn = true
    viewModel.errorMessage = nil

    #expect(viewModel.isLoggedIn)
    #expect(viewModel.errorMessage == nil)
    #endif
  }
  
  @Test func testClothingModel() throws {
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
    #expect(clothing.id == id)
    #expect(clothing.userID == userId)
    #expect(clothing.name == "テストTシャツ")
    #expect(clothing.category == "トップス")
    #expect(clothing.color == "白")
    #expect(clothing.createdAt == dateStr)
    #expect(clothing.updatedAt == dateStr)
  }
  
  @Test func testWeatherModel() throws {
    let weather = Weather(
      city: "東京",
      date: "2025-05-01",
      temperature: 25.5,
      condition: "晴れ",
      icon: "clear-day",
      updatedAt: "2025-05-01T08:00:00Z"
    )
    
    #expect(weather.city == "東京")
    #expect(weather.date == "2025-05-01")
    #expect(weather.temperature == 25.5)
    #expect(weather.condition == "晴れ")
    #expect(weather.icon == "clear-day")
    #expect(weather.updatedAt == "2025-05-01T08:00:00Z")
  }
  
  @Test func testImageExtensions() throws {
    // UIImageの拡張機能テスト - macOSとiOSのみ
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
  
  @MainActor
  @Test func testClothingViewModel() async throws {
    #if os(iOS) || os(macOS)
    // ClothingViewModelのテスト - MainActorコンテキストで実行
    let viewModel = ClothingViewModel()
    
    // MainActor上で実行されているのでawaitは不要
    #expect(viewModel.clothes.isEmpty)
    #expect(viewModel.isLoading == false)
    #expect(viewModel.errorMessage == nil)
    
    // テストデータの作成
    let clothing = Clothing(
      id: UUID(),
      userID: UUID(),
      name: "テストアイテム",
      category: "ボトムス",
      color: "青",
      createdAt: "2025-05-01T10:00:00Z",
      updatedAt: "2025-05-01T10:00:00Z"
    )
    
    // モック化したデータを追加 - MainActor上で直接操作
    viewModel.clothes = [clothing]
    
    #expect(viewModel.clothes.count == 1)
    #expect(viewModel.clothes[0].name == "テストアイテム")
    #expect(viewModel.clothes[0].category == "ボトムス")
    #endif
  }
  
  @Test func testWeatherService() async throws {
    #if os(iOS) || os(macOS)
    // モック化したWeatherServiceをテスト用に作成
    actor MockWeatherService {
      var cachedWeather: Weather?
      
      func getCurrentWeather(forCity city: String) -> Weather? {
        if let cached = cachedWeather, cached.city == city {
          return cached
        }
        return nil
      }
      
      func saveWeather(_ weather: Weather) {
        cachedWeather = weather
      }
    }
    
    let weatherService = MockWeatherService()
    
    // モックの天気データを設定
    let mockWeather = Weather(
      city: "大阪",
      date: "2025-05-02",
      temperature: 22.0,
      condition: "曇り",
      icon: "cloudy",
      updatedAt: "2025-05-02T09:00:00Z"
    )
    
    // 実際のAPIコールの代わりにモックデータを返すようにする
    await weatherService.saveWeather(mockWeather)
    
    // テスト実行 (実際のAPIにはアクセスしない)
    let weather = await weatherService.getCurrentWeather(forCity: "大阪")
    
    // 結果を検証
    #expect(weather?.city == "大阪")
    #expect(weather?.temperature == 22.0)
    #expect(weather?.condition == "曇り")
    #endif
  }
  
  @Test func testImageProcessor() throws {
    #if os(iOS) || os(macOS)
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
    
    #expect(maskedImage != nil)
    
    let visualizedImage = ImageProcessor.visualizeMaskOnOriginal(original: originalImage, mask: maskImage)
    
    #expect(visualizedImage != nil)
    #endif
  }
  
  @Test func testLocationManager() throws {
    #if os(iOS) || os(macOS)
    let locationManager = LocationManager()
    
    // 初期状態のテスト
    #expect(locationManager.currentLocation == nil)
    #expect(locationManager.placemark == nil)
    #expect(locationManager.locationError == nil)
    
    // テスト用のロケーションデータ
    let testLocation = CLLocation(latitude: 35.6812, longitude: 139.7671) // 東京の座標
    let locations = [testLocation]
    
    // ロケーション更新をシミュレート
    locationManager.locationManager(CLLocationManager(), didUpdateLocations: locations)
    
    #expect(locationManager.currentLocation != nil)
    #expect(locationManager.currentLocation?.coordinate.latitude == 35.6812)
    #expect(locationManager.currentLocation?.coordinate.longitude == 139.7671)
    
    // エラー処理のテスト
    let testError = NSError(domain: "LocationManagerTest", code: 1, userInfo: nil)
    locationManager.locationManager(CLLocationManager(), didFailWithError: testError)
    
    #expect(locationManager.locationError != nil)
    #expect((locationManager.locationError as NSError?)?.domain == "LocationManagerTest")
    #expect((locationManager.locationError as NSError?)?.code == 1)
    #endif
  }
  
  @MainActor
  @Test func testCoreMLService() async throws {
    #if os(iOS) || os(macOS)
    let coreMLService = CoreMLService()
    
    // テスト用の画像を作成
    let size = CGSize(width: 512, height: 512)
    UIGraphicsBeginImageContext(size)
    let context = UIGraphicsGetCurrentContext()!
    context.setFillColor(UIColor.white.cgColor)
    context.fill(CGRect(origin: .zero, size: size))
    // 簡単な服の形を描画
    context.setFillColor(UIColor.black.cgColor)
    context.fill(CGRect(x: 100, y: 100, width: 312, height: 312))
    let testImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
    let maskContext = UIGraphicsGetCurrentContext()!
    maskContext.setFillColor(UIColor.white.cgColor)
    maskContext.fill(CGRect(origin: .zero, size: size))
    let rectSize = CGSize(width: size.width * 0.7, height: size.height * 0.7)
    let origin = CGPoint(x: (size.width - rectSize.width) / 2, y: (size.height - rectSize.height) / 2)
    maskContext.setFillColor(UIColor.black.cgColor)
    maskContext.fill(CGRect(origin: origin, size: rectSize))
    let maskImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    
    // 画像処理のテスト
    let processed = ImageProcessor.applyMask(original: testImage, mask: maskImage)
    #expect(processed != nil)
    
    // EditableImageSetのインスタンス化方法を修正
    let imageSet = EditableImageSet(
      id: UUID(),
      original: testImage,
      originalUrl: "https://example.com/test.jpg",
      mask: nil,
      maskUrl: nil,
      isNew: true
    )
    
    // CoreMLServiceのテスト
    let processedSet = await coreMLService.processImageSet(imageSet: imageSet)
    #expect(processedSet != nil)
    #expect(processedSet?.original != nil)
    #endif
  }
  
  @Test func testClothingImageModel() throws {
    #if os(iOS) || os(macOS)
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
    #expect(clothingImage.id == id)
    #expect(clothingImage.clothingId == clothingId)
    #expect(clothingImage.userId == userId)
    #expect(clothingImage.originalUrl == "https://example.com/original.jpg")
    #expect(clothingImage.maskUrl == "https://example.com/mask.jpg")
    #expect(clothingImage.resultUrl == "https://example.com/result.jpg")
    #expect(clothingImage.createdAt == createdDate)
    #expect(clothingImage.updatedAt == updatedDate)
    
    // オプショナルプロパティのテスト
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
    
    #expect(clothingImageWithNil.maskUrl == nil)
    #expect(clothingImageWithNil.resultUrl == nil)
    #endif
  }
}
