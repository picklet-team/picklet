//
//  OfflineImageMetadataService.swift
//  Picklet
//
//  Created on 2025/05/10.
//

import Foundation
import UIKit

/// 画像メタデータを管理するオフライン専用サービス
class PickletOfflineImageMetadataService {
  static let shared = PickletOfflineImageMetadataService()

  private let localStorageService = LocalStorageService.shared

  private init() {
    print("🧩 オフラインImageMetadataServiceを初期化")
  }

  /// 指定した服に関連する画像メタデータを取得
  /// - Parameter clothingId: 服のID
  /// - Returns: 画像メタデータの配列
  func fetchImages(for clothingId: UUID) -> [ClothingImage] {
    print("🔍 ID=\(clothingId)の画像メタデータを取得")
    return localStorageService.loadImageMetadata(for: clothingId)
  }

  /// 新しい画像メタデータを追加
  /// - Parameters:
  ///   - clothingId: 服のID
  ///   - imageId: 画像ID（指定しない場合は新規生成）
  ///   - localPath: ローカル保存パス
  /// - Returns: 追加された画像メタデータ
  @discardableResult
  func addImage(for clothingId: UUID,
                imageId: UUID = UUID(),
                localPath: String) -> ClothingImage {
    print("➕ 画像メタデータを追加: 服ID=\(clothingId), 画像ID=\(imageId)")

    // 新しい画像メタデータを作成
    let newImage = ClothingImage(
      id: imageId,
      clothingId: clothingId,
      originalLocalPath: localPath,
      createdAt: Date(),
      updatedAt: Date())

    // 既存のメタデータに追加
    var metadata = localStorageService.loadImageMetadata(for: clothingId)
    metadata.append(newImage)

    // 保存
    LocalStorageService.shared.saveImageMetadata(metadata, for: clothingId)

    return newImage
  }

  /// 画像メタデータを更新
  /// - Parameters:
  ///   - imageId: 更新する画像のID
  ///   - clothingId: 服のID
  ///   - updates: 更新するパラメータのクロージャ
  /// - Returns: 成功したかどうか
  @discardableResult
  func updateImage(imageId: UUID, clothingId: UUID, updates: (inout ClothingImage) -> Void) -> Bool {
    print("🔄 画像メタデータを更新: ID=\(imageId)")

    // 既存のメタデータを取得
    var metadata = localStorageService.loadImageMetadata(for: clothingId)

    // 対象の画像を見つける
    guard let index = metadata.firstIndex(where: { $0.id == imageId }) else {
      print("❌ 更新対象の画像メタデータが見つかりません: ID=\(imageId)")
      return false
    }

    // コピーを作成して更新
    var updatedImage = metadata[index]
    updates(&updatedImage)

    // 更新日時を設定
    updatedImage = ClothingImage(
      id: updatedImage.id,
      clothingId: updatedImage.clothingId,
      originalLocalPath: updatedImage.originalLocalPath,
      maskLocalPath: updatedImage.maskLocalPath,
      resultLocalPath: updatedImage.resultLocalPath,
      createdAt: updatedImage.createdAt,
      updatedAt: Date())

    // 更新したものを配列に戻す
    metadata[index] = updatedImage

    // 保存
    LocalStorageService.shared.saveImageMetadata(metadata, for: clothingId)
    return true
  }

  /// マスク画像のパスを更新
  /// - Parameters:
  ///   - imageId: 画像ID
  ///   - clothingId: 服ID
  ///   - maskPath: マスク画像のローカルパス
  /// - Returns: 成功したかどうか
  @discardableResult
  func updateImageMask(imageId: UUID, clothingId: UUID, maskPath: String) -> Bool {
    return updateImage(imageId: imageId, clothingId: clothingId) { image in
      image = image.updatingLocalPath(maskLocalPath: maskPath)
    }
  }

  /// 画像を削除
  /// - Parameters:
  ///   - imageId: 画像ID
  ///   - clothingId: 服ID
  /// - Returns: 成功したかどうか
  @discardableResult
  func deleteImage(imageId: UUID, clothingId: UUID) -> Bool {
    print("🗑️ 画像メタデータを削除: ID=\(imageId)")

    // 既存のメタデータを取得
    var metadata = localStorageService.loadImageMetadata(for: clothingId)

    // 対象の画像を削除
    let initialCount = metadata.count
    metadata.removeAll { $0.id == imageId }

    // 何も削除されていなければ失敗
    if metadata.count == initialCount {
      print("❌ 削除対象の画像メタデータが見つかりません: ID=\(imageId)")
      return false
    }

    // 保存
    LocalStorageService.shared.saveImageMetadata(metadata, for: clothingId)
    return true
  }
}
