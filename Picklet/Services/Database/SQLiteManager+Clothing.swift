import Foundation
import SQLite

// MARK: - Clothing Data Management

extension SQLiteManager {
  /// 衣類データを保存
  func saveClothing(_ clothing: Clothing) -> Bool {
    do {
      // インサート文の構文修正
      let insertStatement = clothesTable.insert(or: .replace, [
        clothesId <- clothing.id.uuidString,
        clothesName <- clothing.name,
        clothesCategory <- clothing.category,
        clothesColor <- clothing.color,
        clothesCreatedAt <- clothing.createdAt,
        clothesUpdatedAt <- clothing.updatedAt
      ])

      try db?.run(insertStatement)
      print("✅ SQLite: 衣類データ保存成功 - \(clothing.name)")
      return true
    } catch {
      print("❌ SQLite: 衣類データ保存エラー - \(error)")
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

      let clothing = Clothing(
        id: UUID(uuidString: row[clothesId])!,
        name: row[clothesName],
        category: row[clothesCategory],
        color: row[clothesColor],
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

      // ここを修正 - guard letとオプショナルチェーンを使用
      guard let db = db else { return [] }

      // 直接forループで回す
      for row in try db.prepare(clothesTable) {
        let clothing = Clothing(
          id: UUID(uuidString: row[clothesId])!,
          name: row[clothesName],
          category: row[clothesCategory],
          color: row[clothesColor],
          createdAt: row[clothesCreatedAt],
          updatedAt: row[clothesUpdatedAt])
        clothes.append(clothing)
      }

      print("✅ SQLite: 衣類データ読み込み完了 - \(clothes.count)件")
      return clothes
    } catch {
      print("❌ SQLite: 衣類データ読み込みエラー - \(error)")
      return []
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
