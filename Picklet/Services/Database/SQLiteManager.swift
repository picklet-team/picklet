import Foundation
import SQLite
import UIKit

class SQLiteManager {
  static let shared = SQLiteManager()

  var db: Connection?
  let documentsDirectory: URL
  let fileManager = FileManager.default

  // テーブル定義
  let clothesTable = Table("clothes")
  let wearHistoriesTable = Table("wear_histories")
  let imageMetadataTable = Table("image_metadata")

  // 3つの別々の参照データテーブル
  let categoriesTable = Table("categories")
  let brandsTable = Table("brands")
  let tagsTable = Table("tags")

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
  let clothesColors = SQLite.Expression<String?>("colors")
  let clothesCategoryIds = SQLite.Expression<String?>("category_ids")
  let clothesBrandId = SQLite.Expression<String?>("brand_id")
  let clothesTagIds = SQLite.Expression<String?>("tag_ids")
  let clothesWearCount = SQLite.Expression<Int>("wear_count")
  let clothesWearLimit = SQLite.Expression<Int?>("wear_limit")

  // 共通の参照データカラム定義（3つのテーブルで共通使用）
  let referenceId = SQLite.Expression<String>("id")
  let referenceIcon = SQLite.Expression<String>("icon")
  let referenceName = SQLite.Expression<String>("name")
  let referenceCreatedAt = SQLite.Expression<Date>("created_at")
  let referenceUpdatedAt = SQLite.Expression<Date>("updated_at")

  // レガシー互換性のためのカラム定義
  let categoryId = SQLite.Expression<String>("id")
  let categoryName = SQLite.Expression<String>("name")
  let categoryCreatedAt = SQLite.Expression<Date>("created_at")
  let categoryUpdatedAt = SQLite.Expression<Date>("updated_at")
  let categoryIcon = SQLite.Expression<String>("icon")

  let brandId = SQLite.Expression<String>("id")
  let brandName = SQLite.Expression<String>("name")
  let brandCreatedAt = SQLite.Expression<Date>("created_at")
  let brandUpdatedAt = SQLite.Expression<Date>("updated_at")
  let brandIcon = SQLite.Expression<String>("icon")

  let tagId = SQLite.Expression<String>("id")
  let tagName = SQLite.Expression<String>("name")
  let tagCreatedAt = SQLite.Expression<Date>("created_at")
  let tagUpdatedAt = SQLite.Expression<Date>("updated_at")
  let tagIcon = SQLite.Expression<String>("icon")

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
}
