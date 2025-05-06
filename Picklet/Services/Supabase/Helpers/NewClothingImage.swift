import Foundation

/// Model for creating a new clothing image record in the database
struct NewClothingImage: Encodable {
  let id: UUID
  let clothingID: UUID
  let userID: UUID
  let originalURL: String
  let maskURL: String?
  let resultURL: String?
  let createdAt: String

  enum CodingKeys: String, CodingKey {
    case id
    case clothingID = "clothing_id"
    case userID = "user_id"
    case originalURL = "original_url"
    case maskURL = "mask_url"
    case resultURL = "result_url"
    case createdAt = "created_at"
  }
}
