import Foundation
import SQLite

// MARK: - Legacy Migration

extension SQLiteManager {
  /// レガシーストレージからSQLiteに移行
  func migrateFromLegacyStorage() {
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

  func migrateLegacyWearHistories() {
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

  func migrateLegacyClothingData() {
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

  func migrateLegacyImageMetadata() {
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

  func clearLegacyFiles() {
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
