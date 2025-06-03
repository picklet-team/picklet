import Foundation
import SQLite

// MARK: - Clothing Data Management

extension SQLiteManager {
  /// 衣類データを保存
  func saveClothing(_ clothing: Clothing) -> Bool {
    do {
      let encoder = JSONEncoder()
      encoder.dateEncodingStrategy = .iso8601

      // ColorDataをJSONエンコード
      let colorsData = try encoder.encode(clothing.colors)
      let colorsString = String(data: colorsData, encoding: .utf8) ?? "[]"

      // CategoryIdsをJSONエンコード
      let categoryIdsData = try encoder.encode(clothing.categoryIds)
      let categoryIdsString = String(data: categoryIdsData, encoding: .utf8) ?? "[]"

      let insert = clothesTable.insert(
        clothesId <- clothing.id.uuidString,
        clothesName <- clothing.name,
        clothesPurchasePrice <- clothing.purchasePrice,
        clothesFavoriteRating <- clothing.favoriteRating,
        clothesColors <- colorsString, // ColorDataのJSON文字列
        clothesCategoryIds <- categoryIdsString, // 新しいカラム
        clothesCreatedAt <- clothing.createdAt,
        clothesUpdatedAt <- clothing.updatedAt
      )

      try db?.run(insert)
      return true
    } catch {
      print("❌ 衣類保存エラー: \(error)")
      return false
    }
  }

  /// 衣類データを読み込み
  func loadClothing(id: UUID) -> Clothing? {
    do {
      let query = clothesTable.filter(clothesId == id.uuidString)
      guard let row = try db?.pluck(query) else {
        print("⚠️ SQLite: 衣類データが見つかりません - \(id)")
        return nil
      }

      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601

      // ColorDataをJSONから復元
      var colors: [ColorData] = []
      if let colorsString = row[clothesColors],
         let colorsData = colorsString.data(using: .utf8) {
        colors = (try? decoder.decode([ColorData].self, from: colorsData)) ?? []
      }

      // CategoryIdsをJSONから復元
      var categoryIds: [UUID] = []
      if let categoryIdsString = row[clothesCategoryIds],
         let categoryIdsData = categoryIdsString.data(using: .utf8) {
        categoryIds = (try? decoder.decode([UUID].self, from: categoryIdsData)) ?? []
      }

      let clothing = Clothing(
        id: UUID(uuidString: row[clothesId])!,
        name: row[clothesName],
        purchasePrice: row[clothesPurchasePrice],
        favoriteRating: row[clothesFavoriteRating],
        colors: colors, // ColorDataの配列に変更
        categoryIds: categoryIds, // 追加: カテゴリIDの配列
        createdAt: row[clothesCreatedAt],
        updatedAt: row[clothesUpdatedAt])

      return clothing
    } catch {
      print("❌ SQLite: 衣類データ読み込みエラー - \(error)")
      return nil
    }
  }

  /// 全ての衣類データを読み込み
  func loadAllClothing() -> [Clothing] {
    var clothingList: [Clothing] = []

    do {
      guard let db = db else { return clothingList }

      for row in try db.prepare(clothesTable) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // ColorDataをJSONデコード
        var colors: [ColorData] = []
        if let colorsString = row[clothesColors],
           let colorsData = colorsString.data(using: .utf8) {
          colors = (try? decoder.decode([ColorData].self, from: colorsData)) ?? []
        }

        // CategoryIdsをJSONデコード
        var categoryIds: [UUID] = []
        if let categoryIdsString = row[clothesCategoryIds],
           let categoryIdsData = categoryIdsString.data(using: .utf8) {
          categoryIds = (try? decoder.decode([UUID].self, from: categoryIdsData)) ?? []
        }

        let clothing = Clothing(
          id: UUID(uuidString: row[clothesId]) ?? UUID(),
          name: row[clothesName],
          purchasePrice: row[clothesPurchasePrice],
          favoriteRating: row[clothesFavoriteRating],
          colors: colors, // ColorDataの配列
          categoryIds: categoryIds, // 追加: カテゴリIDの配列
          createdAt: row[clothesCreatedAt],
          updatedAt: row[clothesUpdatedAt]
        )

        clothingList.append(clothing)
      }
    } catch {
      print("❌ 衣類読み込みエラー: \(error)")
    }

    return clothingList
  }

  /// 衣類データを更新
  func updateClothing(_ clothing: Clothing) -> Bool {
    do {
      let encoder = JSONEncoder()
      encoder.dateEncodingStrategy = .iso8601

      // ColorDataをJSONエンコード
      let colorsData = try encoder.encode(clothing.colors)
      let colorsString = String(data: colorsData, encoding: .utf8) ?? "[]"

      // CategoryIdsをJSONエンコード
      let categoryIdsData = try encoder.encode(clothing.categoryIds)
      let categoryIdsString = String(data: categoryIdsData, encoding: .utf8) ?? "[]"

      let update = clothesTable
        .filter(clothesId == clothing.id.uuidString)
        .update(
          clothesName <- clothing.name,
          clothesPurchasePrice <- clothing.purchasePrice,
          clothesFavoriteRating <- clothing.favoriteRating,
          clothesColors <- colorsString,
          clothesCategoryIds <- categoryIdsString, // 追加: カテゴリIDの更新
          clothesUpdatedAt <- Date()
        )

      guard let db = db else { return false }
      try db.run(update)
      return true
    } catch {
      print("❌ 衣類更新エラー: \(error)")
      return false
    }
  }

  /// 衣類データを削除
  func deleteClothing(id: UUID) -> Bool {
    do {
      let clothing = clothesTable.filter(clothesId == id.uuidString)
      let deleted = try db?.run(clothing.delete()) ?? 0

      if deleted > 0 {
        print("✅ SQLite: 衣類データ削除成功 - \(id)")
        return true
      } else {
        print("⚠️ SQLite: 削除対象の衣類データが見つかりません - \(id)")
        return false
      }
    } catch {
      print("❌ SQLite: 衣類データ削除エラー - \(error)")
      return false
    }
  }

  /// 全ての衣類データを削除
  func clearAllClothing() {
    do {
      try db?.run(clothesTable.delete())
      print("✅ SQLite: 全衣類データ削除完了")
    } catch {
      print("❌ SQLite: 全衣類データ削除エラー - \(error)")
    }
  }
}
