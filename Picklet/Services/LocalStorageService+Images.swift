import Foundation
import UIKit

// MARK: - Image Management
extension LocalStorageService {

  /// 画像を保存
  /// - Parameters:
  ///   - image: 保存する画像
  ///   - filename: ファイル名
  /// - Returns: 保存成功の可否
  func saveImage(_ image: UIImage, filename: String) -> Bool {
    let fileURL = imagesDirectory.appendingPathComponent(filename)

    guard let data = image.jpegData(compressionQuality: 0.8) else {
      print("❌ 画像データ変換エラー: \(filename)")
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
    let fileURL = imagesDirectory.appendingPathComponent(filename)

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
    let fileURL = imagesDirectory.appendingPathComponent(filename)

    guard fileManager.fileExists(atPath: fileURL.path) else {
      print("⚠️ 削除対象の画像ファイルが存在しません: \(filename)")
      return true // 既に存在しないので成功とする
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

  /// 画像メタデータを保存
  /// - Parameter images: 画像メタデータの配列
  /// - Parameter clothingId: 衣類ID
  func saveImageMetadata(_ images: [ClothingImage], for clothingId: UUID) {
    let encoder = JSONEncoder()
    do {
      let data = try encoder.encode(images)
      userDefaults.set(data, forKey: "clothingImages_\(clothingId.uuidString)")
      userDefaults.synchronize()
      print("✅ 画像メタデータ保存: \(clothingId) - \(images.count)件")
    } catch {
      print("❌ 画像メタデータ保存エラー: \(error)")
    }
  }

  /// 画像メタデータを読み込み
  /// - Parameter clothingId: 衣類ID
  /// - Returns: 画像メタデータの配列
  func loadImageMetadata(for clothingId: UUID) -> [ClothingImage] {
    guard let data = userDefaults.data(forKey: "clothingImages_\(clothingId.uuidString)") else {
      return []
    }

    do {
      let images = try JSONDecoder().decode([ClothingImage].self, from: data)
      return images
    } catch {
      print("❌ 画像メタデータ読み込みエラー: \(error)")
      return []
    }
  }

  /// 画像メタデータを削除
  /// - Parameter clothingId: 衣類ID
  func deleteImageMetadata(for clothingId: UUID) {
    userDefaults.removeObject(forKey: "clothingImages_\(clothingId.uuidString)")
    userDefaults.synchronize()
    print("✅ 画像メタデータ削除: \(clothingId)")
  }

  /// 全ての画像とメタデータをクリア
  func clearAllImages() {
    // 画像ディレクトリの中身を削除
    do {
      let imageFiles = try fileManager.contentsOfDirectory(at: imagesDirectory, includingPropertiesForKeys: nil)
      for fileURL in imageFiles {
        try fileManager.removeItem(at: fileURL)
      }
      print("✅ 全ての画像ファイルを削除")
    } catch {
      print("❌ 画像ファイル削除エラー: \(error)")
    }

    // 画像メタデータも削除
    let keys = userDefaults.dictionaryRepresentation().keys
    for key in keys {
      if key.hasPrefix("clothingImages_") {
        userDefaults.removeObject(forKey: key)
      }
    }
    userDefaults.synchronize()
    print("✅ 全ての画像メタデータを削除")
  }
}
