//
//  ImageLoaderService.swift
//  Picklet
//
//  Created by al dente on 2025/05/10.
//

import Combine
import SwiftUI
import UIKit

/// 画像読み込みを一元管理するサービス
class ImageLoaderService {
  static let shared = ImageLoaderService()

  private let localStorageService = LocalStorageService.shared

  private init() {}

  /// URLから画像を読み込む
  /// - Parameter urlString: 画像URL文字列
  /// - Returns: 読み込んだ画像（成功した場合）
  func loadFromURL(_ urlString: String) async -> UIImage? {
    guard let url = URL(string: urlString) else {
      print("❌ 無効なURL: \(urlString)")
      return nil
    }

    do {
      let (data, _) = try await URLSession.shared.data(from: url)
      if let image = UIImage(data: data) {
        print("✅ URLから画像を非同期にロード: \(urlString)")
        return image
      }
    } catch {
      print("❌ 画像ダウンロードエラー: \(urlString) - \(error.localizedDescription)")
    }

    return nil
  }

  /// 服IDから最初の画像を読み込む（ローカルストレージ優先）
  /// - Parameter clothingId: 服のID
  /// - Returns: 読み込んだ画像（成功した場合）
  func loadFirstImageForClothing(_ clothingId: UUID) -> UIImage? {
    // ローカルストレージからメタデータを取得
    let metadata = localStorageService.loadImageMetadata(for: clothingId)
    
    // 最初のメタデータをチェック
    if let firstImage = metadata.first {
      // まずローカルパスをチェック
      if let localPath = firstImage.originalLocalPath, 
         let image = localStorageService.loadImage(from: localPath) {
        print("✅ ローカルストレージから画像を読み込み: \(localPath)")
        return image
      }
      
      // ローカルに画像がない場合はURLをチェック
      if let originalUrl = firstImage.originalUrl,
         URL(string: originalUrl) != nil {  // 未使用のオプショナルバインディングを修正
        // この部分は非同期のためUIUpdateブロックでの使用に注意
        // 同期的に使いたい場合は別途キャッシュ機構が必要
        print("⚠️ URLからの同期読み込みは最適ではありません: \(originalUrl)")
        return nil
      }
    }
    
    print("⚠️ 画像が見つかりませんでした: \(clothingId)")
    return nil
  }

  /// 服IDから最初の画像を非同期で読み込む
  /// - Parameter clothingId: 服のID
  /// - Returns: 読み込んだ画像（成功した場合）
  func loadFirstImageForClothingAsync(_ clothingId: UUID) async -> UIImage? {
    // ローカルストレージからメタデータを取得
    let metadata = localStorageService.loadImageMetadata(for: clothingId)

    // 最初のメタデータをチェック
    if let firstImage = metadata.first {
      // まずローカルパスをチェック
      if let localPath = firstImage.originalLocalPath,
         let image = localStorageService.loadImage(from: localPath) {
        print("✅ ローカルストレージから画像を読み込み: \(localPath)")
        return image
      }

      // ローカルに画像がない場合はURLをチェック
      if let originalUrl = firstImage.originalUrl {
        let image = await loadFromURL(originalUrl)

        // ダウンロードした画像をローカルに保存
        if let image = image,
           let savedPath = localStorageService.saveImage(image, id: firstImage.id, type: "original") {
          print("💾 ダウンロードした画像をローカルに保存: \(savedPath)")

          // メタデータを更新
          var updatedMetadata = metadata
          if let index = updatedMetadata.firstIndex(where: { $0.id == firstImage.id }) {
            updatedMetadata[index] = firstImage.updatingLocalPath(originalLocalPath: savedPath)
            localStorageService.saveImageMetadata(for: clothingId, imageMetadata: updatedMetadata)
          }
        }

        return image
      }
    }

    print("⚠️ 画像が見つかりませんでした: \(clothingId)")
    return nil
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
}
