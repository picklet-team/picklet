//
//  LinuxTests.swift
//  PickletTests
//
//  Created on 2025/05/02.
//

@testable import Picklet
import XCTest

final class LinuxCompatibleTests: XCTestCase {

    func testClothingModel() {
        // テスト用の日付作成
        let date = Date()

        // Clothingインスタンスの作成テスト - 新しい構造に対応
        let id = UUID()
        let clothing = Clothing(
            id: id,
            name: "テストTシャツ",
            purchasePrice: 2_000.0,
            favoriteRating: 4,
            colors: [ColorData(hue: 0.0, saturation: 0.0, brightness: 1.0)], // 白色
            categoryIds: [UUID()], // テスト用のカテゴリID
            brandId: UUID(), // テスト用のブランドID
            tagIds: [],
            wearCount: 5,
            wearLimit: 30,
            createdAt: date,
            updatedAt: date
        )

        // 各プロパティが正しく設定されているかテスト
        XCTAssertEqual(clothing.id, id)
        XCTAssertEqual(clothing.name, "テストTシャツ")
        XCTAssertEqual(clothing.purchasePrice, 2_000.0)
        XCTAssertEqual(clothing.favoriteRating, 4)
        XCTAssertEqual(clothing.colors.count, 1)
        XCTAssertEqual(clothing.categoryIds.count, 1)
        XCTAssertNotNil(clothing.brandId)
        XCTAssertTrue(clothing.tagIds.isEmpty)
        XCTAssertEqual(clothing.wearCount, 5)
        XCTAssertEqual(clothing.wearLimit, 30)
        XCTAssertEqual(clothing.createdAt, date)
        XCTAssertEqual(clothing.updatedAt, date)
    }

    func testClothingModelMinimal() {
        // 最小限のプロパティでのテスト
        let clothing = Clothing(name: "シンプルTシャツ")

        XCTAssertEqual(clothing.name, "シンプルTシャツ")
        XCTAssertNil(clothing.purchasePrice)
        XCTAssertEqual(clothing.favoriteRating, 3) // デフォルト値
        XCTAssertTrue(clothing.colors.isEmpty)
        XCTAssertTrue(clothing.categoryIds.isEmpty)
        XCTAssertNil(clothing.brandId)
        XCTAssertTrue(clothing.tagIds.isEmpty)
        XCTAssertEqual(clothing.wearCount, 0) // デフォルト値
        XCTAssertNil(clothing.wearLimit)
    }

    func testColorDataModel() {
        // ColorDataのテスト
        let redColor = ColorData(hue: 0.0, saturation: 1.0, brightness: 1.0)
        
        XCTAssertEqual(redColor.hue, 0.0)
        XCTAssertEqual(redColor.saturation, 1.0)
        XCTAssertEqual(redColor.brightness, 1.0)
        XCTAssertNotNil(redColor.id)
        
        // 同じ色の比較テスト
        let anotherRedColor = ColorData(hue: 0.0, saturation: 1.0, brightness: 1.0)
        XCTAssertTrue(redColor == anotherRedColor)
        
        // 異なる色の比較テスト
        let blueColor = ColorData(hue: 0.67, saturation: 1.0, brightness: 1.0)
        XCTAssertFalse(redColor == blueColor)
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

        // ClothingImageインスタンスの作成テスト - 引数の順序を修正
        let id = UUID()
        let clothingId = UUID()
        let clothingImage = ClothingImage(
            id: id,
            originalUrl: "https://example.com/original.jpg",
            originalLocalPath: "/path/to/original.jpg",
            maskUrl: "https://example.com/mask.jpg",
            maskLocalPath: "/path/to/mask.jpg",
            resultUrl: "https://example.com/result.jpg"
        )

        // 各プロパティが正しく設定されているかテスト
        XCTAssertEqual(clothingImage.id, id)
        XCTAssertEqual(clothingImage.originalLocalPath, "/path/to/original.jpg")
        XCTAssertEqual(clothingImage.maskLocalPath, "/path/to/mask.jpg")
        XCTAssertEqual(clothingImage.originalUrl, "https://example.com/original.jpg")
        XCTAssertEqual(clothingImage.maskUrl, "https://example.com/mask.jpg")
        XCTAssertEqual(clothingImage.resultUrl, "https://example.com/result.jpg")

        let clothingImageWithNil = ClothingImage(
            id: id,
            originalUrl: "https://example.com/original.jpg",
            originalLocalPath: "/path/to/original.jpg",
            maskUrl: nil,
            maskLocalPath: nil,
            resultUrl: nil
        )

        XCTAssertNil(clothingImageWithNil.maskLocalPath)
        XCTAssertNil(clothingImageWithNil.maskUrl)
        XCTAssertNil(clothingImageWithNil.resultUrl)
    }
    #endif

    // Linux環境で動作しない可能性の高いテストケースは除外

    // Linux環境でもテストが実行されるようにするための特別なセットアップ
    static var allTests = [
        ("testClothingModel", testClothingModel),
        ("testClothingModelMinimal", testClothingModelMinimal),
        ("testColorDataModel", testColorDataModel),
        ("testWeatherModel", testWeatherModel)
        // ClothingImageモデルのテストはLinux環境では実行されません
    ]
}
