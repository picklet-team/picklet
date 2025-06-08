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

    // Linux環境ではClothingImageモデルが含まれていない可能性があるためiOSとmacOS環境のみでテスト
    #if os(macOS) || os(iOS)
    func testClothingImageModel() {
        let testData = createClothingImageTestData()

        let clothingImage = ClothingImage(
            id: testData.id,
            clothingId: testData.clothingId,
            userId: "test-user",
            originalUrl: "https://example.com/original.jpg",
            maskUrl: "https://example.com/mask.jpg",
            aimaskUrl: "https://example.com/aimask.jpg",
            resultUrl: "https://example.com/result.jpg",
            originalLocalPath: "/path/to/original.jpg",
            maskLocalPath: "/path/to/mask.jpg",
            resultLocalPath: "/path/to/result.jpg",
            createdAt: testData.createdDate,
            updatedAt: testData.updatedDate
        )

        verifyClothingImageProperties(clothingImage, testData: testData)
    }

    func testClothingImageModelWithNilValues() {
        let testData = createClothingImageTestData()

        let clothingImageWithNil = ClothingImage(
            id: testData.id,
            clothingId: testData.clothingId,
            userId: nil,
            originalUrl: "https://example.com/original.jpg",
            maskUrl: nil,
            aimaskUrl: nil,
            resultUrl: nil,
            originalLocalPath: "/path/to/original.jpg",
            maskLocalPath: nil,
            resultLocalPath: nil,
            createdAt: testData.createdDate,
            updatedAt: testData.updatedDate
        )

        verifyClothingImageNilProperties(clothingImageWithNil, testData: testData)
    }
    #endif

    // Linux環境でもテストが実行されるようにするための特別なセットアップ
    static var allTests = [
        ("testClothingModel", testClothingModel),
        ("testClothingModelMinimal", testClothingModelMinimal),
        ("testColorDataModel", testColorDataModel),
        ("testWeatherModel", testWeatherModel)
        // ClothingImageモデルのテストはLinux環境では実行されません
    ]
}

// MARK: - Helper Methods
#if os(macOS) || os(iOS)
extension LinuxCompatibleTests {

    struct ClothingImageTestData {
        let id: UUID
        let clothingId: UUID
        let createdDate: Date
        let updatedDate: Date
    }

    private func createClothingImageTestData() -> ClothingImageTestData {
        return ClothingImageTestData(
            id: UUID(),
            clothingId: UUID(),
            createdDate: Date(),
            updatedDate: Date()
        )
    }

    private func verifyClothingImageProperties(_ clothingImage: ClothingImage, testData: ClothingImageTestData) {
        XCTAssertEqual(clothingImage.id, testData.id)
        XCTAssertEqual(clothingImage.clothingId, testData.clothingId)
        XCTAssertEqual(clothingImage.userId, "test-user")
        XCTAssertEqual(clothingImage.originalUrl, "https://example.com/original.jpg")
        XCTAssertEqual(clothingImage.maskUrl, "https://example.com/mask.jpg")
        XCTAssertEqual(clothingImage.aimaskUrl, "https://example.com/aimask.jpg")
        XCTAssertEqual(clothingImage.resultUrl, "https://example.com/result.jpg")
        XCTAssertEqual(clothingImage.originalLocalPath, "/path/to/original.jpg")
        XCTAssertEqual(clothingImage.maskLocalPath, "/path/to/mask.jpg")
        XCTAssertEqual(clothingImage.resultLocalPath, "/path/to/result.jpg")
        XCTAssertEqual(clothingImage.createdAt, testData.createdDate)
        XCTAssertEqual(clothingImage.updatedAt, testData.updatedDate)
    }

    private func verifyClothingImageNilProperties(_ clothingImage: ClothingImage, testData: ClothingImageTestData) {
        XCTAssertEqual(clothingImage.id, testData.id)
        XCTAssertEqual(clothingImage.clothingId, testData.clothingId)
        XCTAssertNil(clothingImage.userId)
        XCTAssertEqual(clothingImage.originalUrl, "https://example.com/original.jpg")
        XCTAssertNil(clothingImage.maskUrl)
        XCTAssertNil(clothingImage.aimaskUrl)
        XCTAssertNil(clothingImage.resultUrl)
        XCTAssertEqual(clothingImage.originalLocalPath, "/path/to/original.jpg")
        XCTAssertNil(clothingImage.maskLocalPath)
        XCTAssertNil(clothingImage.resultLocalPath)
    }
}
#endif
