//
//  ImageLoaderService.swift
//  Picklet
//
//  Created by al dente on 2025/05/10.
//

import SwiftUI
import UIKit

/// 画像読み込みを一元管理するサービス（ローカルストレージ専用）
class ImageLoaderService {
  static let shared = ImageLoaderService()

  private let localStorageService = LocalStorageService.shared
  private var memoryCache = NSCache<NSUUID, UIImage>()

  private init() {}

  /// 服IDから最初の画像を読み込む（ローカルストレージのみ）
  /// - Parameter clothingId: 服のID
  /// - Returns: 読み込んだ画像（成功した場合）
  func loadFirstImageForClothing(_ clothingId: UUID) -> UIImage? {
    // メモリキャッシュをチェック
    if let cachedImage = memoryCache.object(forKey: clothingId as NSUUID) {
      print("✅ メモリキャッシュから画像を読み込み: \(clothingId)")
      return cachedImage
    }

    // ローカルストレージからメタデータを取得
    let metadata = localStorageService.loadImageMetadata(for: clothingId)

    // 最初のメタデータをチェック
    if let firstImage = metadata.first {
      // ローカルパスをチェック
      if let localPath = firstImage.originalLocalPath,
         let image = localStorageService.loadImage(from: localPath) {
        print("✅ ローカルストレージから画像を読み込み: \(localPath)")
        // メモリキャッシュに追加
        memoryCache.setObject(image, forKey: clothingId as NSUUID)
        return image
      }
    }

    print("⚠️ 画像が見つかりませんでした: \(clothingId)")
    return nil
  }

  /// 画像を保存し、メタデータを更新する
  /// - Parameters:
  ///   - image: 保存する画像
  ///   - clothingId: 服のID
  ///   - imageId: 画像ID (nilの場合は新しいUUIDを生成)
  /// - Returns: 保存が成功したかどうか
  func saveImage(_ image: UIImage, for clothingId: UUID, imageId: UUID? = nil) -> Bool {
    let id = imageId ?? UUID()

    // 画像をローカルに保存
    guard let savedPath = localStorageService.saveImage(image, id: id, type: "original") else {
      print("❌ 画像の保存に失敗しました")
      return false
    }

    // メタデータを更新
    var metadata = localStorageService.loadImageMetadata(for: clothingId)

    // 既存の画像メタデータを更新するか、新しく追加するか
    if let index = metadata.firstIndex(where: { $0.id == id }) {
      metadata[index] = metadata[index].updatingLocalPath(originalLocalPath: savedPath)
    } else {
      let newImageMetadata = ClothingImage(id: id, originalLocalPath: savedPath)
      metadata.append(newImageMetadata)
    }

    // メタデータを保存
    localStorageService.saveImageMetadata(for: clothingId, imageMetadata: metadata)

    // メモリキャッシュに追加
    memoryCache.setObject(image, forKey: clothingId as NSUUID)

    print("💾 画像をローカルに保存しました: \(savedPath)")
    return true
  }

  /// EditableImageSet配列からClothing IDに関連する最初の画像を取得する
  /// - Parameters:
  ///   - clothingId: 服のID
  ///   - imageSetsMap: EditableImageSetのマップ
  /// - Returns: 見つかった場合はUIImage、見つからない場合はnil
  func getFirstImageFromImageSetsMap(clothingId: UUID, imageSetsMap: [UUID: [EditableImageSet]]) -> UIImage? {
    if let imageSets = imageSetsMap[clothingId], let firstSet = imageSets.first {
      // システムの写真アイコンでなければ返す
      if firstSet.original != UIImage(systemName: "photo") {
        return firstSet.original
      }
    }
    return nil
  }

  /// メモリキャッシュを消去する
  func clearMemoryCache() {
    memoryCache.removeAllObjects()
    print("🧹 画像メモリキャッシュを消去しました")
  }
}
