import Foundation
import SQLite

// MARK: - Clothing Data Management

extension SQLiteManager {
  /// 衣類データを保存または更新（UPSERT操作）
  func saveClothing(_ clothing: Clothing) -> Bool {
    // 既存データをチェック
    if loadClothing(id: clothing.id) != nil {
      // 既存データがある場合は更新
      return updateClothing(clothing)
    } else {
      // 新規データの場合は挿入
      return insertClothing(clothing)
    }
  }

  /// 新規衣類データを挿入（内部用）
  private func insertClothing(_ clothing: Clothing) -> Bool {
    do {
      let encoder = JSONEncoder()
      encoder.dateEncodingStrategy = .iso8601

      // ColorDataをJSONエンコード
      let colorsData = try encoder.encode(clothing.colors)
      let colorsString = String(data: colorsData, encoding: .utf8) ?? "[]"

      // CategoryIdsをJSONエンコード
      let categoryIdsData = try encoder.encode(clothing.categoryIds)
      let categoryIdsString = String(data: categoryIdsData, encoding: .utf8) ?? "[]"

      // TagIdsをJSONエンコード
      let tagIdsData = try encoder.encode(clothing.tagIds)
      let tagIdsString = String(data: tagIdsData, encoding: .utf8) ?? "[]"

      let insert = clothesTable.insert(
        clothesId <- clothing.id.uuidString,
        clothesName <- clothing.name,
        clothesPurchasePrice <- clothing.purchasePrice,
        clothesFavoriteRating <- clothing.favoriteRating,
        clothesColors <- colorsString,
        clothesCategoryIds <- categoryIdsString,
        clothesBrandId <- clothing.brandId?.uuidString,
        clothesTagIds <- tagIdsString,
        clothesWearCount <- clothing.wearCount,
        clothesWearLimit <- clothing.wearLimit,
        clothesCreatedAt <- clothing.createdAt,
        clothesUpdatedAt <- clothing.updatedAt)

      try db?.run(insert)
      print("✅ SQLite: 新規衣類データ挿入成功 - \(clothing.id)")
      return true
    } catch {
      print("❌ 衣類挿入エラー: \(error)")
      return false
    }
  }

  /// 衣類データを読み込み
  func loadClothing(id: UUID) -> Clothing? {
    do {
      let query = clothesTable.filter(clothesId == id.uuidString)
      guard let row = try db?.pluck(query) else {
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

      // TagIdsをJSONから復元
      var tagIds: [UUID] = []
      if let tagIdsString = row[clothesTagIds],
         let tagIdsData = tagIdsString.data(using: .utf8) {
        tagIds = (try? decoder.decode([UUID].self, from: tagIdsData)) ?? []
      }

      // BrandIdの復元
      let brandId: UUID?
      if let brandIdString = row[clothesBrandId] {
        brandId = UUID(uuidString: brandIdString)
      } else {
        brandId = nil
      }

      // データベースから取得した日時を使用して正しく初期化
      let clothing = Clothing(
        id: UUID(uuidString: row[clothesId])!,
        name: row[clothesName],
        purchasePrice: row[clothesPurchasePrice],
        favoriteRating: row[clothesFavoriteRating],
        colors: colors,
        categoryIds: categoryIds,
        brandId: brandId,
        tagIds: tagIds,
        wearCount: row[clothesWearCount],
        wearLimit: row[clothesWearLimit],
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
    do {
      var clothes: [Clothing] = []

      guard let db = db else { return [] }

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

        // TagIdsをJSONデコード
        var tagIds: [UUID] = []
        if let tagIdsString = row[clothesTagIds],
           let tagIdsData = tagIdsString.data(using: .utf8) {
          tagIds = (try? decoder.decode([UUID].self, from: tagIdsData)) ?? []
        }

        // BrandIdの復元
        let brandId: UUID?
        if let brandIdString = row[clothesBrandId] {
          brandId = UUID(uuidString: brandIdString)
        } else {
          brandId = nil
        }

        // データベースから取得した日時を使用して正しく初期化
        let clothing = Clothing(
          id: UUID(uuidString: row[clothesId]) ?? UUID(),
          name: row[clothesName],
          purchasePrice: row[clothesPurchasePrice],
          favoriteRating: row[clothesFavoriteRating],
          colors: colors,
          categoryIds: categoryIds,
          brandId: brandId,
          tagIds: tagIds,
          wearCount: row[clothesWearCount],
          wearLimit: row[clothesWearLimit],
          createdAt: row[clothesCreatedAt],
          updatedAt: row[clothesUpdatedAt])

        clothes.append(clothing)
      }

      return clothes
    } catch {
      print("❌ 衣類読み込みエラー: \(error)")
      return []
    }
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

      // TagIdsをJSONエンコード
      let tagIdsData = try encoder.encode(clothing.tagIds)
      let tagIdsString = String(data: tagIdsData, encoding: .utf8) ?? "[]"

      let update = clothesTable
        .filter(clothesId == clothing.id.uuidString)
        .update(
          clothesName <- clothing.name,
          clothesPurchasePrice <- clothing.purchasePrice,
          clothesFavoriteRating <- clothing.favoriteRating,
          clothesColors <- colorsString,
          clothesCategoryIds <- categoryIdsString,
          clothesBrandId <- clothing.brandId?.uuidString,
          clothesTagIds <- tagIdsString,
          clothesWearCount <- clothing.wearCount,
          clothesWearLimit <- clothing.wearLimit,
          clothesUpdatedAt <- clothing.updatedAt)

      guard let db = db else { return false }
      let rowsAffected = try db.run(update)

      if rowsAffected > 0 {
        print("✅ SQLite: 衣類データ更新成功 - \(clothing.id)")
        return true
      } else {
        print("⚠️ SQLite: 更新対象の衣類データが見つかりません - \(clothing.id)")
        return false
      }
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
