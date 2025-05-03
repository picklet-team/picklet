//
//  ClothingImage.swift
//  MyApp
//
//  Created by al dente on 2025/04/27.
//

import Foundation

struct ClothingImage: Identifiable, Codable {
  let id: UUID
  let clothingID: UUID
  let userID: UUID
  let originalURL: String
  let maskURL: String?
  let resultURL: String?
  let createdAt: String
  let updatedAt: String

  enum CodingKeys: String, CodingKey {
    case id
    case clothingID = "clothing_id"
    case userID = "user_id"
    case originalURL = "original_url"
    case maskURL = "mask_url"
    case resultURL = "result_url"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
  }
}
