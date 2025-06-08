import Foundation
import SQLite
import UIKit

// MARK: - Core Database Setup and Migration

extension SQLiteManager {
  func setupDatabase() {
    do {
      // データベースファイルのパス
      let dbPath = documentsDirectory.appendingPathComponent("picklet.sqlite3").path
      db = try Connection(dbPath)

      // テーブル作成
      try createTables()

      // マイグレーション実行
      performMigrations()

      print("✅ SQLiteデータベース初期化完了: \(dbPath)")
    } catch {
      print("❌ SQLiteデータベース初期化エラー: \(error)")
    }
  }

  func createTables() throws {
    // 衣類テーブル
    try db?.run(clothesTable.create(ifNotExists: true) { table in
      table.column(clothesId, primaryKey: true)
      table.column(clothesName)
      table.column(clothesPurchasePrice)
      table.column(clothesFavoriteRating, defaultValue: 3)
      table.column(clothesColors, defaultValue: "[]")
      table.column(clothesCategoryIds, defaultValue: "[]")
      table.column(clothesBrandId)
      table.column(clothesTagIds, defaultValue: "[]")
      table.column(clothesWearCount, defaultValue: 0)
      table.column(clothesWearLimit)
      table.column(clothesCreatedAt)
      table.column(clothesUpdatedAt)
    })

    // 着用履歴テーブル
    try db?.run(wearHistoriesTable.create(ifNotExists: true) { table in
      table.column(wearId, primaryKey: true)
      table.column(wearClothingId)
      table.column(wearWornAt)
    })

    // 画像メタデータテーブル
    try db?.run(imageMetadataTable.create(ifNotExists: true) { table in
      table.column(imageId, primaryKey: true)
      table.column(imageClothingId)
      table.column(imageOriginalPath)
      table.column(imageMaskPath)
      table.column(imageOriginalUrl)
      table.column(imageMaskUrl)
      table.column(imageResultUrl)
    })

    // カテゴリテーブル
    try db?.run(categoriesTable.create(ifNotExists: true) { table in
      table.column(categoryId, primaryKey: true)
      table.column(categoryName)
      table.column(categoryCreatedAt)
      table.column(categoryUpdatedAt)
    })

    // ブランドテーブル
    try db?.run(brandsTable.create(ifNotExists: true) { table in
      table.column(brandId, primaryKey: true)
      table.column(brandName)
      table.column(brandCreatedAt)
      table.column(brandUpdatedAt)
    })

    print("✅ SQLite: テーブル作成完了")
  }

  func performMigrations() {
    guard let db = db else { return }

    // 新しいカラムの追加（エラーを無視）
    do {
      try db.run("ALTER TABLE clothes ADD COLUMN brand_id TEXT")
      print("✅ brand_id カラムを追加しました")
    } catch {
      print("ℹ️ brand_id カラムは既に存在します")
    }

    do {
      try db.run("ALTER TABLE clothes ADD COLUMN tag_ids TEXT DEFAULT '[]'")
      print("✅ tag_ids カラムを追加しました")
    } catch {
      print("ℹ️ tag_ids カラムは既に存在します")
    }

    do {
      try db.run("ALTER TABLE clothes ADD COLUMN wear_count INTEGER DEFAULT 0")
      print("✅ wear_count カラムを追加しました")
    } catch {
      print("ℹ️ wear_count カラムは既に存在します")
    }

    do {
      try db.run("ALTER TABLE clothes ADD COLUMN wear_limit INTEGER")
      print("✅ wear_limit カラムを追加しました")
    } catch {
      print("ℹ️ wear_limit カラムは既に存在します")
    }

    do {
      try db.run("ALTER TABLE clothes ADD COLUMN category_ids TEXT DEFAULT '[]'")
      print("✅ category_ids カラムを追加しました")
    } catch {
      print("ℹ️ category_ids カラムは既に存在します")
    }
  }
}
