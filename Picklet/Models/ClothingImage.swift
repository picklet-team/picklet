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
  let userId: UUID?
  let originalUrl: String?
  let maskUrl: String?
  let resultUrl: String?

  // ローカル保存パス
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
    case resultUrl = "result_url"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
    // ローカルパスはAPIレスポンスにないのでコーディングキーは定義しない
  }

  // サーバーからのデータを変換するイニシャライザ
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(UUID.self, forKey: .id)
    clothingId = try container.decode(UUID.self, forKey: .clothingId)
    userId = try container.decodeIfPresent(UUID.self, forKey: .userId)
    originalUrl = try container.decodeIfPresent(String.self, forKey: .originalUrl)
    maskUrl = try container.decodeIfPresent(String.self, forKey: .maskUrl)
    resultUrl = try container.decodeIfPresent(String.self, forKey: .resultUrl)

    // 日付文字列をDateに変換
    let dateFormatter = ISO8601DateFormatter()

    if let createdAtString = try container.decodeIfPresent(String.self, forKey: .createdAt),
       let date = dateFormatter.date(from: createdAtString) {
      createdAt = date
    } else {
      createdAt = Date()
    }

    if let updatedAtString = try container.decodeIfPresent(String.self, forKey: .updatedAt),
       let date = dateFormatter.date(from: updatedAtString) {
      updatedAt = date
    } else {
      updatedAt = Date()
    }

    // ローカルパスは初期値としてnilを設定
    originalLocalPath = nil
    maskLocalPath = nil
    resultLocalPath = nil
  }

  // カスタムイニシャライザ（ローカルデータ用）
  init(
    id: UUID = UUID(),
    clothingId: UUID,
    userId: UUID? = nil,
    originalUrl: String? = nil,
    maskUrl: String? = nil,
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
    self.resultUrl = resultUrl
    self.originalLocalPath = originalLocalPath
    self.maskLocalPath = maskLocalPath
    self.resultLocalPath = resultLocalPath
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

  // エンコード用メソッド
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(clothingId, forKey: .clothingId)
    try container.encodeIfPresent(userId, forKey: .userId)
    try container.encodeIfPresent(originalUrl, forKey: .originalUrl)
    try container.encodeIfPresent(maskUrl, forKey: .maskUrl)
    try container.encodeIfPresent(resultUrl, forKey: .resultUrl)

    // 日付をISO8601形式の文字列に変換
    let dateFormatter = ISO8601DateFormatter()
    let createdAtString = dateFormatter.string(from: createdAt)
    let updatedAtString = dateFormatter.string(from: updatedAt)

    try container.encode(createdAtString, forKey: .createdAt)
    try container.encode(updatedAtString, forKey: .updatedAt)

    // ローカルパスはAPIに送信しないのでエンコードしない
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
      resultUrl: resultUrl,
      originalLocalPath: originalLocalPath ?? self.originalLocalPath,
      maskLocalPath: maskLocalPath ?? self.maskLocalPath,
      resultLocalPath: resultLocalPath ?? self.resultLocalPath,
      createdAt: createdAt,
      updatedAt: updatedAt)
  }
}
