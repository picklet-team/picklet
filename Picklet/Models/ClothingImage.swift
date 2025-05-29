//
//  ClothingImage.swift
//  Picklet
//
//  Created by al dente on 2025/04/27.
//

import Foundation

struct ClothingImage: Identifiable, Codable {
  let id: UUID
  let clothingId: UUID
  let userId: String?

  // クラウドストレージのURL（Supabase用）
  var originalUrl: String?
  var maskUrl: String?
  var aimaskUrl: String?
  var resultUrl: String?

  // ローカル保存パス（オフライン専用）
  var originalLocalPath: String?
  var maskLocalPath: String?
  var resultLocalPath: String?

  let createdAt: Date
  let updatedAt: Date

  enum CodingKeys: String, CodingKey {
    case id
    case clothingId = "clothing_id"
    case userId = "user_id"
    case originalUrl = "original_url"
    case maskUrl = "mask_url"
    case aimaskUrl = "aimask_url"
    case resultUrl = "result_url"
    case originalLocalPath = "original_local_path"
    case maskLocalPath = "mask_local_path"
    case resultLocalPath = "result_local_path"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
  }

  // カスタムイニシャライザ（ローカルデータ用）
  init(
    id: UUID = UUID(),
    clothingId: UUID = UUID(),
    userId: String? = nil,
    originalUrl: String? = nil,
    maskUrl: String? = nil,
    aimaskUrl: String? = nil,
    resultUrl: String? = nil,
    originalLocalPath: String? = nil,
    maskLocalPath: String? = nil,
    resultLocalPath: String? = nil,
    createdAt: Date = Date(),
    updatedAt: Date = Date()) {
    self.id = id
    self.clothingId = clothingId
    self.userId = userId
    self.originalUrl = originalUrl
    self.maskUrl = maskUrl
    self.aimaskUrl = aimaskUrl
    self.resultUrl = resultUrl
    self.originalLocalPath = originalLocalPath
    self.maskLocalPath = maskLocalPath
    self.resultLocalPath = resultLocalPath
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

  /// ローカルパスを更新した新しいインスタンスを返す
  /// - Parameters:
  ///   - originalLocalPath: 更新するオリジナル画像のローカルパス
  ///   - maskLocalPath: 更新するマスク画像のローカルパス
  ///   - resultLocalPath: 更新する結果画像のローカルパス
  /// - Returns: 更新された新しい ClothingImage インスタンス
  func updatingLocalPath(
    originalLocalPath: String? = nil,
    maskLocalPath: String? = nil,
    resultLocalPath: String? = nil) -> ClothingImage {
    return ClothingImage(
      id: id,
      clothingId: clothingId,
      userId: userId,
      originalUrl: originalUrl,
      maskUrl: maskUrl,
      aimaskUrl: aimaskUrl,
      resultUrl: resultUrl,
      originalLocalPath: originalLocalPath ?? self.originalLocalPath,
      maskLocalPath: maskLocalPath ?? self.maskLocalPath,
      resultLocalPath: resultLocalPath ?? self.resultLocalPath,
      createdAt: createdAt,
      updatedAt: updatedAt)
  }
}
