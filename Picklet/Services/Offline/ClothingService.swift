//
//  ClothingService.swift
//  Picklet
//
//  Created on 2025/05/10.
//

import Foundation
import SwiftUI

/// オフラインで衣類データを管理するサービス
class ClothingService {
  static let shared = ClothingService()

  // LocalStorageServiceの代わりにSQLiteManagerを使用
  private let dataManager = SQLiteManager.shared

  private init() {
    // ファイル読み込みの初期化など必要であればここで
    print("🧩 オフラインClothingServiceを初期化")
  }

  // MARK: - 服データ操作

  /// すべての服を取得する
  /// - Returns: 服の配列
  func fetchClothes() -> [Clothing] {
    print("📋 すべての服を取得")
    return dataManager.loadAllClothing()
  }

  /// 新しい服を追加する
  /// - Parameter clothing: 追加する服
  /// - Returns: 追加が成功したかどうか
  @discardableResult
  func addClothing(_ clothing: Clothing) -> Bool {
    print("➕ 新しい服を追加: \(clothing.id)")
    return dataManager.saveClothing(clothing)
  }

  /// 既存の服を更新する
  /// - Parameter clothing: 更新する服
  /// - Returns: 更新が成功したかどうか
  @discardableResult
  func updateClothing(_ clothing: Clothing) -> Bool {
    print("🔄 服を更新: \(clothing.id)")
    return dataManager.saveClothing(clothing)
  }

  /// 服を削除する
  /// - Parameter clothing: 削除する服
  /// - Returns: 削除が成功したかどうか
  @discardableResult
  func deleteClothing(_ clothing: Clothing) -> Bool {
    print("🗑️ 服を削除: \(clothing.id)")
    return deleteClothingById(clothing.id)
  }

  /// IDで服を削除する
  /// - Parameter id: 削除する服のID
  /// - Returns: 削除が成功したかどうか
  @discardableResult
  func deleteClothingById(_ id: UUID) -> Bool {
    print("🗑️ IDで服を削除: \(id)")
    return dataManager.deleteClothing(id: id)
  }

  /// IDで服を取得する
  /// - Parameter id: 取得する服のID
  /// - Returns: 見つかった服、見つからない場合はnil
  func getClothingById(_ id: UUID) -> Clothing? {
    print("🔍 IDで服を検索: \(id)")
    return dataManager.loadClothing(id: id)
  }
}
