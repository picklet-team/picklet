import Foundation
import SQLite
import UIKit

// MARK: - Core Database Setup and Migration

extension SQLiteManager {
  func setupDatabase() {
    do {
      let path = documentsDirectory.appendingPathComponent("picklet.sqlite3").path
      db = try Connection(path)
      print("✅ データベース接続成功: \(path)")

      try createTables()
      performMigrations()
    } catch {
      print("❌ データベース初期化エラー: \(error)")
    }
  }

  func createTables() throws {
    // Clothes テーブル作成
    try db?.run(clothesTable.create(ifNotExists: true) { table in
      table.column(clothesId, primaryKey: true)
      table.column(clothesName)
      table.column(clothesCreatedAt)
      table.column(clothesUpdatedAt)
      table.column(clothesPurchasePrice)
      table.column(clothesFavoriteRating)
      table.column(clothesColors)
      table.column(clothesCategoryIds)
      table.column(clothesBrandId)
      table.column(clothesTagIds)
      table.column(clothesWearCount)
      table.column(clothesWearLimit)
    })
    print("✅ Clothesテーブル作成完了")

    // WearHistories テーブル作成
    try db?.run(wearHistoriesTable.create(ifNotExists: true) { table in
      table.column(wearId, primaryKey: true)
      table.column(wearClothingId)
      table.column(wearWornAt)
    })
    print("✅ WearHistoriesテーブル作成完了")

    // ImageMetadata テーブル作成
    try db?.run(imageMetadataTable.create(ifNotExists: true) { table in
      table.column(imageId, primaryKey: true)
      table.column(imageClothingId)
      table.column(imageOriginalPath)
      table.column(imageMaskPath)
      table.column(imageOriginalUrl)
      table.column(imageMaskUrl)
      table.column(imageResultUrl)
    })
    print("✅ ImageMetadataテーブル作成完了")

    // Categoriesテーブル作成（is_defaultカラム削除）
    try db?.run(categoriesTable.create(ifNotExists: true) { table in
      table.column(categoryId, primaryKey: true)
      table.column(categoryName)
      table.column(categoryIcon, defaultValue: "🏷️")
      // is_defaultカラムを削除
    })
    print("✅ Categoriesテーブル作成完了")

    // Brandsテーブル作成（is_defaultカラム削除）
    try db?.run(brandsTable.create(ifNotExists: true) { table in
      table.column(brandId, primaryKey: true)
      table.column(brandName)
      table.column(brandIcon, defaultValue: "⭐")
      // is_defaultカラムを削除
    })
    print("✅ Brandsテーブル作成完了")

    // Tagsテーブル作成（is_defaultカラム削除）
    try db?.run(tagsTable.create(ifNotExists: true) { table in
      table.column(tagId, primaryKey: true)
      table.column(tagName)
      table.column(tagIcon, defaultValue: "#️⃣")
      // is_defaultカラムを削除
    })
    print("✅ Tagsテーブル作成完了")

    // 既存テーブルにiconカラムを追加（マイグレーション）
    addIconColumnsIfNeeded()
  }

  func performMigrations() {
    // 既存のマイグレーション処理
    addIconColumnsIfNeeded()
    removeIsDefaultColumnsIfNeeded() // is_defaultカラム削除マイグレーション
  }

  private func addIconColumnsIfNeeded() {
    do {
      // Categoriesテーブルにiconカラムを追加
      try db?.run("ALTER TABLE categories ADD COLUMN icon TEXT DEFAULT '🏷️'")
      print("✅ categoriesテーブルにiconカラムを追加")
    } catch {
      print("ℹ️ categoriesテーブルのiconカラムは既に存在します")
    }

    do {
      // Brandsテーブルにiconカラムを追加
      try db?.run("ALTER TABLE brands ADD COLUMN icon TEXT DEFAULT '⭐'")
      print("✅ brandsテーブルにiconカラムを追加")
    } catch {
      print("ℹ️ brandsテーブルのiconカラムは既に存在します")
    }

    do {
      // Tagsテーブルにiconカラムを追加
      try db?.run("ALTER TABLE tags ADD COLUMN icon TEXT DEFAULT '#️⃣'")
      print("✅ tagsテーブルにiconカラムを追加")
    } catch {
      print("ℹ️ tagsテーブルのiconカラムは既に存在します")
    }
  }

  private func removeIsDefaultColumnsIfNeeded() {
    // SQLiteでは直接カラム削除ができないため、テーブル再作成で対応
    // 本格的な運用時は慎重に実装する必要がありますが、
    // 開発段階では既存データを削除して再作成することも可能

    #if DEBUG
    // 開発段階では既存テーブルを削除して再作成
    do {
      try db?.run("DROP TABLE IF EXISTS categories")
      try db?.run("DROP TABLE IF EXISTS brands")
      try db?.run("DROP TABLE IF EXISTS tags")
      print("🔄 参照データテーブルを再作成")

      // テーブルを再作成
      try createReferenceDataTables()
    } catch {
      print("❌ テーブル再作成エラー: \(error)")
    }
    #endif
  }

  private func createReferenceDataTables() throws {
    // 前述のcreateTablesから該当部分を抜粋
    try db?.run(categoriesTable.create(ifNotExists: true) { table in
      table.column(categoryId, primaryKey: true)
      table.column(categoryName)
      table.column(categoryIcon, defaultValue: "🏷️")
    })

    try db?.run(brandsTable.create(ifNotExists: true) { table in
      table.column(brandId, primaryKey: true)
      table.column(brandName)
      table.column(brandIcon, defaultValue: "⭐")
    })

    try db?.run(tagsTable.create(ifNotExists: true) { table in
      table.column(tagId, primaryKey: true)
      table.column(tagName)
      table.column(tagIcon, defaultValue: "#️⃣")
    })
  }
}
