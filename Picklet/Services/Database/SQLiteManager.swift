import Foundation
import SQLite
import UIKit

class SQLiteManager {
  static let shared = SQLiteManager()

  // privateからinternalに変更
  var db: Connection?
  let documentsDirectory: URL
  let fileManager = FileManager.default

  // テーブル定義
  let clothesTable = Table("clothes")
  let wearHistoriesTable = Table("wear_histories")
  let imageMetadataTable = Table("image_metadata")
  let categoriesTable = Table("categories") // カテゴリテーブル
  let brandsTable = Table("brands") // ブランドテーブル

  // 完全修飾名を使用（SQLite.Expression）
  // Clothes テーブルのカラム
  let clothesId = SQLite.Expression<String>("id")
  let clothesName = SQLite.Expression<String>("name")
  let clothesCreatedAt = SQLite.Expression<Date>("created_at")
  let clothesUpdatedAt = SQLite.Expression<Date>("updated_at")

  // WearHistory テーブルのカラム
  let wearId = SQLite.Expression<String>("id")
  let wearClothingId = SQLite.Expression<String>("clothing_id")
  let wearWornAt = SQLite.Expression<Date>("worn_at")

  // ImageMetadata テーブルのカラム
  let imageId = SQLite.Expression<String>("id")
  let imageClothingId = SQLite.Expression<String>("clothing_id")
  let imageOriginalPath = SQLite.Expression<String?>("original_local_path")
  let imageMaskPath = SQLite.Expression<String?>("mask_local_path")
  let imageOriginalUrl = SQLite.Expression<String?>("original_url")
  let imageMaskUrl = SQLite.Expression<String?>("mask_url")
  let imageResultUrl = SQLite.Expression<String?>("result_url")

  // 新しいカラム定義
  let clothesPurchasePrice = SQLite.Expression<Double?>("purchase_price")
  let clothesFavoriteRating = SQLite.Expression<Int>("favorite_rating")
  let clothesColors = SQLite.Expression<String?>("colors") // JSON文字列として保存
  let clothesCategoryIds = SQLite.Expression<String?>("category_ids") // 追加

  // 削除予定の古いカラム（マイグレーション用）
  let clothesCategory = SQLite.Expression<String?>("category")
  let clothesColor = SQLite.Expression<String?>("color")

  // カテゴリテーブル
  let categoryId = SQLite.Expression<String>("id")
  let categoryName = SQLite.Expression<String>("name")
  let categoryCreatedAt = SQLite.Expression<Date>("created_at")
  let categoryUpdatedAt = SQLite.Expression<Date>("updated_at")

  // ブランドテーブル
  let brandId = SQLite.Expression<String>("id")
  let brandName = SQLite.Expression<String>("name")
  let brandCreatedAt = SQLite.Expression<Date>("created_at")
  let brandUpdatedAt = SQLite.Expression<Date>("updated_at")

  private init() {
    // App Groupのコンテナディレクトリを取得
    let groupIdentifier = "group.com.yourdomain.picklet"
    if let groupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier) {
      documentsDirectory = groupURL.appendingPathComponent("Documents")
    } else {
      documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    // Documentsディレクトリを作成（存在しない場合）
    if !fileManager.fileExists(atPath: documentsDirectory.path) {
      do {
        try fileManager.createDirectory(at: documentsDirectory, withIntermediateDirectories: true, attributes: nil)
        print("✅ Documentsディレクトリ作成: \(documentsDirectory.path)")
      } catch {
        print("❌ Documentsディレクトリ作成エラー: \(error)")
      }
    }

    setupDatabase()
    migrateFromLegacyStorage()
  }

  private func setupDatabase() {
    do {
      // データベースファイルのパス
      let dbPath = documentsDirectory.appendingPathComponent("picklet.sqlite3").path
      db = try Connection(dbPath)

      // テーブル作成
      createTables()

      // マイグレーション実行
      performMigrations()

      print("✅ SQLiteデータベース初期化完了: \(dbPath)")
    } catch {
      print("❌ SQLiteデータベース初期化エラー: \(error)")
    }
  }

  private func createTables() {
    do {
      // 衣類テーブル
      try db?.run(clothesTable.create(ifNotExists: true) { t in
        t.column(clothesId, primaryKey: true)
        t.column(clothesName)
        t.column(clothesPurchasePrice)
        t.column(clothesFavoriteRating)
        t.column(clothesColors)
        t.column(clothesCategoryIds) // 追加: カテゴリIDの配列（JSON文字列）
        t.column(clothesCreatedAt)
        t.column(clothesUpdatedAt)
      })

      // カテゴリテーブル
      try db?.run(categoriesTable.create(ifNotExists: true) { t in
        t.column(categoryId, primaryKey: true)
        t.column(categoryName)
        t.column(categoryCreatedAt)
        t.column(categoryUpdatedAt)
        // is_defaultカラムを削除
      })

      // ブランドテーブル
      try db?.run(brandsTable.create(ifNotExists: true) { t in
        t.column(brandId, primaryKey: true)
        t.column(brandName)
        t.column(brandCreatedAt)
        t.column(brandUpdatedAt)
      })

      print("✅ SQLite: テーブル作成完了")
    } catch {
      print("❌ SQLite: テーブル作成エラー - \(error)")
    }
  }

  private func performMigrations() {
    guard let db = db else { return }

    // カテゴリIDカラムの追加（既存テーブルに存在しない場合）
    do {
      try db.run(clothesTable.addColumn(clothesCategoryIds, defaultValue: nil))
      print("✅ category_ids カラムを追加しました")
    } catch {
      // カラムが既に存在する場合はエラーを無視
      if error.localizedDescription.contains("duplicate column name") ||
         error.localizedDescription.contains("already exists") {
        print("ℹ️ category_ids カラムは既に存在します")
      } else {
        print("⚠️ category_ids カラム追加エラー: \(error)")
      }
    }
  }

  private func migrateClothingTable() throws {
    // テーブルが存在しない場合は新しい構造で作成
    // 1. 既存データをバックアップ
    let existingData = try backupExistingClothingData()

    // 2. 古いテーブルを削除
    try db?.run(clothesTable.drop(ifExists: true))

    // 3. 新しい構造でテーブルを作成
    try db?.run(clothesTable.create { t in
      t.column(clothesId, primaryKey: true)
      t.column(clothesName)
      t.column(clothesPurchasePrice)
      t.column(clothesFavoriteRating, defaultValue: 3)
      t.column(clothesColors, defaultValue: "[]")
      t.column(clothesCategoryIds) // 追加: カテゴリIDの配列（JSON文字列）
      t.column(clothesCreatedAt)
      t.column(clothesUpdatedAt)
    })

    // 4. データを新しい構造で復元
    try restoreClothingData(existingData)
  }

  private func backupExistingClothingData() throws -> [(id: String, name: String, createdAt: Date, updatedAt: Date)] {
    var backup: [(id: String, name: String, createdAt: Date, updatedAt: Date)] = []

    do {
      guard let db = db else { return backup }

      for row in try db.prepare(clothesTable) {
        backup.append((
          id: row[clothesId],
          name: row[clothesName],
          createdAt: row[clothesCreatedAt],
          updatedAt: row[clothesUpdatedAt]
        ))
      }
    } catch {
      print("⚠️ SQLite: 既存データバックアップ時のエラー - \(error)")
    }

    return backup
  }

  private func restoreClothingData(_ data: [(id: String, name: String, createdAt: Date, updatedAt: Date)]) throws {
    for item in data {
      try db?.run(clothesTable.insert(
        clothesId <- item.id,
        clothesName <- item.name,
        clothesPurchasePrice <- nil,
        clothesFavoriteRating <- 3,
        clothesColors <- "[]",
        clothesCategoryIds <- nil, // 修正済み
        clothesCreatedAt <- item.createdAt,
        clothesUpdatedAt <- item.updatedAt
      ))
    }
    print("✅ SQLite: \(data.count)件のデータを復元完了")
  }

  /// レガシーストレージからSQLiteに移行
  private func migrateFromLegacyStorage() {
    let migrationKey = "sqlite_migration_completed"
    let userDefaults = UserDefaults.standard

    // 既に移行済みの場合はスキップ
    if userDefaults.bool(forKey: migrationKey) {
      return
    }

    print("🔄 レガシーストレージからSQLiteに移行開始...")

    // UserDefaultsから着用履歴を移行
    migrateLegacyWearHistories()

    // JSONファイルから衣類データを移行
    migrateLegacyClothingData()

    // UserDefaultsから画像メタデータを移行
    migrateLegacyImageMetadata()

    // 移行完了フラグを設定
    userDefaults.set(true, forKey: migrationKey)
    userDefaults.synchronize()

    print("✅ レガシーストレージからSQLiteに移行完了")
  }

  private func migrateLegacyWearHistories() {
    let userDefaults = UserDefaults.standard
    guard let data = userDefaults.data(forKey: "wear_histories") else { return }

    do {
      let histories = try JSONDecoder().decode([WearHistory].self, from: data)
      if !histories.isEmpty {
        saveWearHistories(histories)
        print("📅 着用履歴移行完了: \(histories.count)件")
      }
    } catch {
      print("❌ 着用履歴移行エラー: \(error)")
    }
  }

  private func migrateLegacyClothingData() {
    let clothingDirectory = documentsDirectory.appendingPathComponent("clothing")
    guard fileManager.fileExists(atPath: clothingDirectory.path) else { return }

    do {
      let fileURLs = try fileManager.contentsOfDirectory(at: clothingDirectory, includingPropertiesForKeys: nil)
      var migratedCount = 0

      for fileURL in fileURLs where fileURL.pathExtension == "json" {
        do {
          let data = try Data(contentsOf: fileURL)
          let decoder = JSONDecoder()
          decoder.dateDecodingStrategy = .iso8601
          let clothing = try decoder.decode(Clothing.self, from: data)

          if saveClothing(clothing) {
            migratedCount += 1
          }
        } catch {
          print("❌ 衣類ファイル移行エラー (\(fileURL.lastPathComponent)): \(error)")
        }
      }

      if migratedCount > 0 {
        print("📦 衣類データ移行完了: \(migratedCount)件")
      }
    } catch {
      print("❌ 衣類ディレクトリ読み込みエラー: \(error)")
    }
  }

  private func migrateLegacyImageMetadata() {
    let userDefaults = UserDefaults.standard
    let clothingIds = loadAllClothing().map { $0.id }
    var migratedCount = 0

    for clothingId in clothingIds {
      guard let data = userDefaults.data(forKey: "clothingImages_\(clothingId.uuidString)") else { continue }

      do {
        let images = try JSONDecoder().decode([ClothingImage].self, from: data)
        if !images.isEmpty {
          saveImageMetadata(images, for: clothingId)
          migratedCount += images.count
        }
      } catch {
        print("❌ 画像メタデータ移行エラー (\(clothingId)): \(error)")
      }
    }

    if migratedCount > 0 {
      print("🖼️ 画像メタデータ移行完了: \(migratedCount)件")
    }
  }

  /// アプリデータを完全にクリア
  func clearAllData() {
    print("🗑️ 全データクリア開始...")

    // SQLiteデータをクリア
    clearAllClothing()
    clearAllImageMetadata()
    clearWearHistories()

    // 画像ファイルをクリア
    clearAllImages()

    // レガシーファイルもクリア（念のため）
    clearLegacyFiles()

    print("✅ 全データクリア完了")
  }

  private func clearLegacyFiles() {
    let clothingDirectory = documentsDirectory.appendingPathComponent("clothing")
    if fileManager.fileExists(atPath: clothingDirectory.path) {
      try? fileManager.removeItem(at: clothingDirectory)
    }

    // UserDefaultsのレガシーキーもクリア
    let userDefaults = UserDefaults.standard
    userDefaults.removeObject(forKey: "wear_histories")
    userDefaults.removeObject(forKey: "clothing_id_list")

    // clothingImages_* キーを全て削除
    let keys = userDefaults.dictionaryRepresentation().keys
    for key in keys {
      if key.hasPrefix("clothingImages_") {
        userDefaults.removeObject(forKey: key)
      }
    }

    userDefaults.synchronize()
  }
}
