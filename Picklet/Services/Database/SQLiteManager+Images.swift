import Foundation
import SQLite
import UIKit

// MARK: - Image Management (Files + Metadata)
extension SQLiteManager {

  // MARK: - Image Files

  /// 画像を保存
  /// - Parameters:
  ///   - image: 保存する画像
  ///   - filename: ファイル名
  /// - Returns: 保存成功の可否
  func saveImage(_ image: UIImage, filename: String) -> Bool {
    let imageDirectory = documentsDirectory.appendingPathComponent("images")

    // imagesディレクトリが存在しない場合は作成
    if !fileManager.fileExists(atPath: imageDirectory.path) {
      do {
        try fileManager.createDirectory(at: imageDirectory,
                                       withIntermediateDirectories: true)  // nilを削除
      } catch {
        print("❌ imagesディレクトリ作成エラー: \(error)")
        return false
      }
    }

    let fileURL = imageDirectory.appendingPathComponent(filename)

    guard let data = image.jpegData(compressionQuality: 0.8) else {
      print("❌ 画像データ変換エラー")
      return false
    }

    do {
      try data.write(to: fileURL)
      print("✅ 画像保存成功: \(filename)")
      return true
    } catch {
      print("❌ 画像保存エラー: \(error)")
      return false
    }
  }

  /// 画像を読み込み
  /// - Parameter filename: ファイル名
  /// - Returns: 読み込んだ画像
  func loadImage(filename: String) -> UIImage? {
    let imageDirectory = documentsDirectory.appendingPathComponent("images")
    let fileURL = imageDirectory.appendingPathComponent(filename)

    guard fileManager.fileExists(atPath: fileURL.path) else {
      print("⚠️ 画像ファイルが存在しません: \(filename)")
      return nil
    }

    guard let image = UIImage(contentsOfFile: fileURL.path) else {
      print("❌ 画像読み込みエラー: \(filename)")
      return nil
    }

    return image
  }

  /// 画像を削除
  /// - Parameter filename: ファイル名
  /// - Returns: 削除成功の可否
  func deleteImage(filename: String) -> Bool {
    let imageDirectory = documentsDirectory.appendingPathComponent("images")
    let fileURL = imageDirectory.appendingPathComponent(filename)

    guard fileManager.fileExists(atPath: fileURL.path) else {
      print("⚠️ 削除対象の画像ファイルが存在しません: \(filename)")
      return true // 既に存在しないので成功とみなす
    }

    do {
      try fileManager.removeItem(at: fileURL)
      print("✅ 画像削除成功: \(filename)")
      return true
    } catch {
      print("❌ 画像削除エラー: \(error)")
      return false
    }
  }

  /// 全ての画像ファイルをクリア
  func clearAllImages() {
    let imageDirectory = documentsDirectory.appendingPathComponent("images")
    if fileManager.fileExists(atPath: imageDirectory.path) {
      do {
        try fileManager.removeItem(at: imageDirectory)
        print("✅ 全ての画像ファイルを削除")
      } catch {
        print("❌ 画像ファイル削除エラー: \(error)")
      }
    }
  }

  // MARK: - Image Metadata

  /// 画像メタデータを保存
  func saveImageMetadata(_ images: [ClothingImage], for clothingId: UUID) {
    do {
      // 既存のメタデータを削除
      let existingImages = imageMetadataTable.filter(imageClothingId == clothingId.uuidString)
      try db?.run(existingImages.delete())

      // 新しいメタデータを挿入
      for image in images {
        let insert = imageMetadataTable.insert([
          imageId <- image.id.uuidString,
          imageClothingId <- clothingId.uuidString,
          imageOriginalPath <- image.originalLocalPath,
          imageMaskPath <- image.maskLocalPath,
          imageOriginalUrl <- image.originalUrl,
          imageMaskUrl <- image.maskUrl,
          imageResultUrl <- image.resultUrl
        ])

        try db?.run(insert)
      }

      print("✅ SQLite: 画像メタデータ保存完了 - \(clothingId) (\(images.count)件)")
    } catch {
      print("❌ SQLite: 画像メタデータ保存エラー - \(error)")
    }
  }

  /// 画像メタデータを読み込み
  func loadImageMetadata(for clothingId: UUID) -> [ClothingImage] {
    do {
      var images: [ClothingImage] = []
      let query = imageMetadataTable.filter(imageClothingId == clothingId.uuidString)

      // タイプの問題を修正
      guard let db = db else { return [] }

      for row in try db.prepare(query) {
        // 引数順序を正しく修正
        let image = ClothingImage(
          id: UUID(uuidString: row[imageId])!,
          clothingId: UUID(uuidString: row[imageClothingId])!,
          originalUrl: row[imageOriginalUrl],        // originalUrlが先
          maskUrl: row[imageMaskUrl],                // maskUrlが後
          resultUrl: row[imageResultUrl],            // resultUrl
          originalLocalPath: row[imageOriginalPath], // originalLocalPath
          maskLocalPath: row[imageMaskPath]          // maskLocalPath
        )
        images.append(image)
      }

      return images
    } catch {
      print("❌ SQLite: 画像メタデータ読み込みエラー - \(error)")
      return []
    }
  }

  /// 画像メタデータを削除
  func deleteImageMetadata(for clothingId: UUID) {
    do {
      let images = imageMetadataTable.filter(imageClothingId == clothingId.uuidString)
      try db?.run(images.delete())
      print("✅ SQLite: 画像メタデータ削除完了 - \(clothingId)")
    } catch {
      print("❌ SQLite: 画像メタデータ削除エラー - \(error)")
    }
  }

  /// 全ての画像メタデータを削除
  func clearAllImageMetadata() {
    do {
      try db?.run(imageMetadataTable.delete())
      print("✅ SQLite: 全画像メタデータ削除完了")
    } catch {
      print("❌ SQLite: 全画像メタデータ削除エラー - \(error)")
    }
  }
}
