import Foundation
import Supabase

/// Service for clothing image metadata (database operations)
final class ImageMetadataService {
    static let shared = ImageMetadataService()
    private let client: SupabaseClient

    private init(client: SupabaseClient = AuthService.shared.client) {
        self.client = client
    }

    private var currentUser: User? {
        AuthService.shared.currentUser
    }

    /// Fetch metadata records for a specific clothing item
    /// - Parameter clothingId: The UUID of the clothing
    /// - Returns: Array of ClothingImage metadata
    func fetchImages(for clothingId: UUID) async throws -> [ClothingImage] {
        let response = try await client
            .from("clothing_images")
            .select("*")
            .eq("clothing_id", value: clothingId.uuidString)
            .execute()
        return try response.decoded(to: [ClothingImage].self)
    }

    /// Add a new image metadata record
    /// - Parameters:
    ///   - clothingId: The UUID of the clothing
    ///   - originalUrl: URL string of the original image
    ///   - maskUrl: Optional URL string of the mask image
    ///   - resultUrl: Optional URL string of the result image
    func addImage(
        for clothingId: UUID,
        originalUrl: String,
        maskUrl: String? = nil,
        resultUrl: String? = nil
    ) async throws {
        guard let user = currentUser else {
            throw NSError(
                domain: "auth", code: 401,
                userInfo: [NSLocalizedDescriptionKey: "ユーザーが未ログインです"]
            )
        }
        let newImage = NewClothingImage(
            id: UUID(),
            clothingID: clothingId,
            userID: user.id,
            originalURL: originalUrl,
            maskURL: maskUrl,
            resultURL: resultUrl,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        _ = try await client
            .from("clothing_images")
            .insert(newImage)
            .execute()
    }

    /// Update the mask URL for an existing image record
    /// - Parameters:
    ///   - imageId: The UUID of the image record
    ///   - maskUrl: New mask URL string
    func updateImageMask(imageId: UUID, maskUrl: String) async throws {
        _ = try await client
            .from("clothing_images")
            .update(["mask_url": maskUrl])
            .eq("id", value: imageId.uuidString)
            .execute()
    }

    /// Update the result URL for an existing image record
    /// - Parameters:
    ///   - imageId: The UUID of the image record
    ///   - resultUrl: New result URL string
    func updateImageResult(imageId: UUID, resultUrl: String) async throws {
        _ = try await client
            .from("clothing_images")
            .update(["result_url": resultUrl])
            .eq("id", value: imageId.uuidString)
            .execute()
    }

    /// Update both mask and result URLs for an existing image record
    /// - Parameters:
    ///   - imageId: The UUID of the image record
    ///   - maskUrl: Optional new mask URL
    ///   - resultUrl: Optional new result URL
    func updateImageMaskAndResult(
        imageId: UUID,
        maskUrl: String?,
        resultUrl: String?
    ) async throws {
        _ = try await client
            .from("clothing_images")
            .update([
                "mask_url": maskUrl,
                "result_url": resultUrl
            ])
            .eq("id", value: imageId.uuidString)
            .execute()
    }
}

// MARK: - Internal Models

private struct NewClothingImage: Encodable {
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
