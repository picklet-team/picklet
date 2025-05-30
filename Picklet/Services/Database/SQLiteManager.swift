import Foundation
import SQLite
import UIKit

class SQLiteManager {
  static let shared = SQLiteManager()

  // privateからinternalに変更
  internal var db: Connection?
  internal let documentsDirectory: URL
  internal let fileManager = FileManager.default  // privateからinternalに変更

  // テーブル定義
  internal let clothesTable = Table("clothes")
  internal let wearHistoriesTable = Table("wear_histories")
  internal let imageMetadataTable = Table("image_metadata")

  // 完全修飾名（SQLite.Expression）を使用
  // Clothes テーブルのカラム
  internal let clothesId = SQLite.Expression<String>("id")
  internal let clothesName = SQLite.Expression<String>("name")
  internal let clothesCategory = SQLite.Expression<String>("category")
  internal let clothesColor = SQLite.Expression<String>("color")
  internal let clothesCreatedAt = SQLite.Expression<Date>("created_at")
  internal let clothesUpdatedAt = SQLite.Expression<Date>("updated_at")

  // WearHistory テーブルのカラム
  internal let wearId = SQLite.Expression<String>("id")
  internal let wearClothingId = SQLite.Expression<String>("clothing_id")
  internal let wearWornAt = SQLite.Expression<Date>("worn_at")

  // ImageMetadata テーブルのカラム
  internal let imageId = SQLite.Expression<String>("id")
  internal let imageClothingId = SQLite.Expression<String>("clothing_id")
  internal let imageOriginalPath = SQLite.Expression<String?>("original_local_path")
  internal let imageMaskPath = SQLite.Expression<String?>("mask_local_path")
  internal let imageOriginalUrl = SQLite.Expression<String?>("original_url")
  internal let imageMaskUrl = SQLite.Expression<String?>("mask_url")
  internal let imageResultUrl = SQLite.Expression<String?>("result_url")

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

      print("✅ SQLiteデータベース初期化完了: \(dbPath)")
    } catch {
      print("❌ SQLiteデータベース初期化エラー: \(error)")
    }
  }

  private func createTables() {
    do {
      // Clothesテーブル
      try db?.run(clothesTable.create(ifNotExists: true) { t in
        t.column(clothesId, primaryKey: true)
        t.column(clothesName)
        t.column(clothesCategory)
        t.column(clothesColor)
        t.column(clothesCreatedAt)
        t.column(clothesUpdatedAt)
      })

      // WearHistoriesテーブル
      try db?.run(wearHistoriesTable.create(ifNotExists: true) { t in
        t.column(wearId, primaryKey: true)
        t.column(wearClothingId)
        t.column(wearWornAt)
        t.foreignKey(wearClothingId, references: clothesTable, clothesId, delete: .cascade)
      })

      // ImageMetadataテーブル
      try db?.run(imageMetadataTable.create(ifNotExists: true) { t in
        t.column(imageId, primaryKey: true)
        t.column(imageClothingId)
        t.column(imageOriginalPath)
        t.column(imageMaskPath)
        t.column(imageOriginalUrl)
        t.column(imageMaskUrl)
        t.column(imageResultUrl)
        t.foreignKey(imageClothingId, references: clothesTable, clothesId, delete: .cascade)
      })

      print("✅ SQLiteテーブル作成完了")
    } catch {
      print("❌ SQLiteテーブル作成エラー: \(error)")
    }
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
