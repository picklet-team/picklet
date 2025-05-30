//
//  ImageLoaderService.swift
//  Picklet
//
//  Created by al dente on 2025/05/10.
//

import SwiftUI
import UIKit

/// 画像読み込みを一元管理するサービス（SQLite対応）
class ImageLoaderService {
  static let shared = ImageLoaderService()

  private let dataManager = SQLiteManager.shared
  private var memoryCache = NSCache<NSUUID, UIImage>()

  private init() {
    // メモリキャッシュの設定
    memoryCache.countLimit = 50 // 最大50枚まで
    memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50MB まで
  }

  /// 服IDから最初の画像を読み込む（SQLite対応）
  /// - Parameter clothingId: 服のID
  /// - Returns: 読み込んだ画像（成功した場合）
  func loadFirstImageForClothing(_ clothingId: UUID) -> UIImage? {
    // メモリキャッシュをチェック
    if let cachedImage = memoryCache.object(forKey: clothingId as NSUUID) {
      print("✅ メモリキャッシュから画像を読み込み: \(clothingId)")
      return cachedImage
    }

    // SQLiteからメタデータを取得
    let metadata = dataManager.loadImageMetadata(for: clothingId)

    // 最初のメタデータをチェック
    if let firstImage = metadata.first {
      // ローカルパスをチェック
      if let localPath = firstImage.originalLocalPath,
         let image = dataManager.loadImage(filename: localPath) {
        print("✅ ローカルストレージから画像を読み込み: \(localPath)")

        // メモリキャッシュに追加（画像サイズをコストとして設定）
        let cost = Int(image.size.width * image.size.height * 4) // RGBA
        memoryCache.setObject(image, forKey: clothingId as NSUUID, cost: cost)

        return image
      }
    }

    print("⚠️ 画像が見つかりませんでした: \(clothingId)")
    return nil
  }

  /// 画像を保存し、メタデータを更新する（SQLite対応）
  /// - Parameters:
  ///   - image: 保存する画像
  ///   - clothingId: 服のID
  ///   - imageId: 画像ID (nilの場合は新しいUUIDを生成)
  /// - Returns: 保存が成功したかどうか
  func saveImage(_ image: UIImage, for clothingId: UUID, imageId: UUID? = nil) -> Bool {
    let id = imageId ?? UUID()

    // 画像をローカルに保存（ファイル名を生成）
    let filename = "\(id.uuidString)_original.jpg"
    guard dataManager.saveImage(image, filename: filename) else {
      print("❌ 画像の保存に失敗しました")
      return false
    }

    // SQLiteからメタデータを取得
    var metadata = dataManager.loadImageMetadata(for: clothingId)

    // 既存の画像メタデータを更新するか、新しく追加するか
    if let index = metadata.firstIndex(where: { $0.id == id }) {
      // 既存のメタデータを更新
      var updatedImage = metadata[index]

      // 構造体の初期化順序がおかしいようです。Clothingクラスでの定義順に合わせます
      updatedImage = ClothingImage(
        id: updatedImage.id,
        clothingId: updatedImage.clothingId,       // 追加
        originalUrl: updatedImage.originalUrl,     // originalUrlが先
        maskUrl: updatedImage.maskUrl,             // maskUrlが後
        resultUrl: updatedImage.resultUrl,         // resultUrl
        originalLocalPath: filename,               // originalLocalPath
        maskLocalPath: updatedImage.maskLocalPath  // maskLocalPath
      )
      metadata[index] = updatedImage
    } else {
      // 新しいメタデータを追加
      let newImageMetadata = ClothingImage(
        id: id,
        clothingId: clothingId,                  // 追加
        originalUrl: nil,                        // originalUrlが先
        maskUrl: nil,                            // maskUrlが後
        resultUrl: nil,                          // resultUrl
        originalLocalPath: filename,             // originalLocalPath
        maskLocalPath: nil                       // maskLocalPath
      )
      metadata.append(newImageMetadata)
    }

    // SQLiteにメタデータを保存
    dataManager.saveImageMetadata(metadata, for: clothingId)

    // メモリキャッシュに追加
    let cost = Int(image.size.width * image.size.height * 4)
    memoryCache.setObject(image, forKey: clothingId as NSUUID, cost: cost)

    print("💾 画像をSQLite対応で保存しました: \(filename)")
    return true
  }

  /// 複数の画像を一括で読み込む
  /// - Parameter clothingId: 服のID
  /// - Returns: 読み込んだ画像の配列
  func loadAllImagesForClothing(_ clothingId: UUID) -> [UIImage] {
    let metadata = dataManager.loadImageMetadata(for: clothingId)
    var images: [UIImage] = []

    for imageMetadata in metadata {
      if let localPath = imageMetadata.originalLocalPath,
         let image = dataManager.loadImage(filename: localPath) {
        images.append(image)
      }
    }

    print("✅ \(clothingId)の画像を\(images.count)枚読み込み")
    return images
  }

  /// EditableImageSet配列からClothing IDに関連する最初の画像を取得する
  /// - Parameters:
  ///   - clothingId: 服のID
  ///   - imageSetsMap: EditableImageSetのマップ
  /// - Returns: 見つかった場合はUIImage、見つからない場合はnil
  func getFirstImageFromImageSetsMap(clothingId: UUID, imageSetsMap: [UUID: [EditableImageSet]]) -> UIImage? {
    if let imageSets = imageSetsMap[clothingId], let firstSet = imageSets.first {
      // システムの写真アイコンでなければ返す
      let defaultPhotoImage = UIImage(systemName: "photo")
      if firstSet.original != defaultPhotoImage {
        return firstSet.original
      }
    }
    return nil
  }

  /// 画像を削除（ファイルとメタデータ両方）
  /// - Parameters:
  ///   - imageId: 削除する画像のID
  ///   - clothingId: 服のID
  /// - Returns: 削除が成功したかどうか
  func deleteImage(imageId: UUID, from clothingId: UUID) -> Bool {
    // メタデータを取得
    var metadata = dataManager.loadImageMetadata(for: clothingId)

    // 削除対象の画像を探す
    guard let imageIndex = metadata.firstIndex(where: { $0.id == imageId }),
          let localPath = metadata[imageIndex].originalLocalPath else {
      print("⚠️ 削除対象の画像が見つかりません: \(imageId)")
      return false
    }

    // ファイルを削除
    if !dataManager.deleteImage(filename: localPath) {
      print("❌ 画像ファイル削除に失敗: \(localPath)")
      return false
    }

    // メタデータから削除
    metadata.remove(at: imageIndex)
    dataManager.saveImageMetadata(metadata, for: clothingId)

    // メモリキャッシュからも削除
    memoryCache.removeObject(forKey: clothingId as NSUUID)

    print("✅ 画像を削除しました: \(imageId)")
    return true
  }

  /// 服に関連する全ての画像を削除
  /// - Parameter clothingId: 服のID
  func deleteAllImages(for clothingId: UUID) {
    let metadata = dataManager.loadImageMetadata(for: clothingId)

    // 全ての画像ファイルを削除
    for imageMetadata in metadata {
      if let localPath = imageMetadata.originalLocalPath {
        _ = dataManager.deleteImage(filename: localPath)
      }
      if let maskPath = imageMetadata.maskLocalPath {
        _ = dataManager.deleteImage(filename: maskPath)
      }
    }

    // メタデータを削除
    dataManager.deleteImageMetadata(for: clothingId)

    // メモリキャッシュからも削除
    memoryCache.removeObject(forKey: clothingId as NSUUID)

    print("✅ \(clothingId)の全画像を削除しました")
  }

  /// メモリキャッシュを消去する
  func clearMemoryCache() {
    memoryCache.removeAllObjects()
    print("🧹 画像メモリキャッシュを消去しました")
  }

  /// メモリキャッシュの使用状況を取得
  func getCacheInfo() -> (count: Int, totalCost: Int) {
    return (count: memoryCache.countLimit, totalCost: memoryCache.totalCostLimit)
  }
}
