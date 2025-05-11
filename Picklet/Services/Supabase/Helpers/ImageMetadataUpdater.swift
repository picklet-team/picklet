import Foundation
import Supabase

/// Helper class for updating image metadata
final class ImageMetadataUpdater {
  private let client: SupabaseClient
  private let localStorageService = LocalStorageService.shared

  init(client: SupabaseClient) {
    self.client = client
  }

  /// Update the mask URL for an existing image record
  func updateImageMask(imageId: UUID, maskUrl: String) async throws {
    // サーバー上のデータを更新
    _ = try await client
      .from("clothing_images")
      .update(["mask_url": maskUrl])
      .eq("id", value: imageId.uuidString)
      .execute()

    // ローカルデータを取得
    if let clothingData = try await fetchClothingData(for: imageId) {
      let clothingId = clothingData.clothingId
      var localImages = localStorageService.loadImageMetadata(for: clothingId)

      // 対象画像を見つけて新しいインスタンスに更新
      if let index = localImages.firstIndex(where: { $0.id == imageId }) {
        let oldImage = localImages[index]

        // 新しいインスタンスを作成して、マスクURLだけを更新
        let updatedImage = ClothingImage(
          id: oldImage.id,
          clothingId: oldImage.clothingId,
          userId: oldImage.userId,
          originalUrl: oldImage.originalUrl,
          maskUrl: maskUrl, // 新しいmaskUrl
          aimaskUrl: oldImage.aimaskUrl,
          resultUrl: oldImage.resultUrl,
          originalLocalPath: oldImage.originalLocalPath,
          maskLocalPath: oldImage.maskLocalPath,
          resultLocalPath: oldImage.resultLocalPath,
          createdAt: oldImage.createdAt,
          updatedAt: Date())

        // 配列を更新
        localImages[index] = updatedImage
        localStorageService.saveImageMetadata(for: clothingId, imageMetadata: localImages)
      }
    }
  }

  /// Update the result URL for an existing image record
  func updateImageResult(imageId: UUID, resultUrl: String) async throws {
    // サーバー上のデータを更新
    _ = try await client
      .from("clothing_images")
      .update(["result_url": resultUrl])
      .eq("id", value: imageId.uuidString)
      .execute()

    // ローカルデータを取得
    if let clothingData = try await fetchClothingData(for: imageId) {
      let clothingId = clothingData.clothingId
      var localImages = localStorageService.loadImageMetadata(for: clothingId)

      // 対象画像を見つけて新しいインスタンスに更新
      if let index = localImages.firstIndex(where: { $0.id == imageId }) {
        let oldImage = localImages[index]

        // 新しいインスタンスを作成して、結果URLだけを更新
        let updatedImage = ClothingImage(
          id: oldImage.id,
          clothingId: oldImage.clothingId,
          userId: oldImage.userId,
          originalUrl: oldImage.originalUrl,
          maskUrl: oldImage.maskUrl,
          aimaskUrl: oldImage.aimaskUrl,
          resultUrl: resultUrl, // 新しいresultUrl
          originalLocalPath: oldImage.originalLocalPath,
          maskLocalPath: oldImage.maskLocalPath,
          resultLocalPath: oldImage.resultLocalPath,
          createdAt: oldImage.createdAt,
          updatedAt: Date())

        // 配列を更新
        localImages[index] = updatedImage
        localStorageService.saveImageMetadata(for: clothingId, imageMetadata: localImages)
      }
    }
  }

  /// Update both mask and result URLs for an existing image record
  func updateImageMaskAndResult(
    imageId: UUID,
    maskUrl: String?,
    resultUrl: String?) async throws {
    // サーバー上のデータを更新
    _ = try await client
      .from("clothing_images")
      .update([
        "mask_url": maskUrl,
        "result_url": resultUrl
      ])
      .eq("id", value: imageId.uuidString)
      .execute()

    // ローカルデータを取得
    if let clothingData = try await fetchClothingData(for: imageId) {
      let clothingId = clothingData.clothingId
      var localImages = localStorageService.loadImageMetadata(for: clothingId)

      // 対象画像を見つけて新しいインスタンスに更新
      if let index = localImages.firstIndex(where: { $0.id == imageId }) {
        let oldImage = localImages[index]

        // 新しいインスタンスを作成して、URLを更新
        let updatedImage = ClothingImage(
          id: oldImage.id,
          clothingId: oldImage.clothingId,
          userId: oldImage.userId,
          originalUrl: oldImage.originalUrl,
          maskUrl: maskUrl ?? oldImage.maskUrl, // 新しいmaskUrlがあれば更新
          aimaskUrl: oldImage.aimaskUrl,
          resultUrl: resultUrl ?? oldImage.resultUrl, // 新しいresultUrlがあれば更新
          originalLocalPath: oldImage.originalLocalPath,
          maskLocalPath: oldImage.maskLocalPath,
          resultLocalPath: oldImage.resultLocalPath,
          createdAt: oldImage.createdAt,
          updatedAt: Date())

        // 配列を更新
        localImages[index] = updatedImage
        localStorageService.saveImageMetadata(for: clothingId, imageMetadata: localImages)
      }
    }
  }

  /// Update the AI mask URL for an existing image record
  func updateImageAIMask(imageId: UUID, aimaskUrl: String) async throws {
    // サーバー上のデータを更新
    _ = try await client
      .from("clothing_images")
      .update(["aimask_url": aimaskUrl])
      .eq("id", value: imageId.uuidString)
      .execute()

    // ローカルデータを取得
    if let clothingData = try await fetchClothingData(for: imageId) {
      let clothingId = clothingData.clothingId
      var localImages = localStorageService.loadImageMetadata(for: clothingId)

      // 対象画像を見つけて新しいインスタンスに更新
      if let index = localImages.firstIndex(where: { $0.id == imageId }) {
        let oldImage = localImages[index]

        // 新しいインスタンスを作成して、AIマスクURLだけを更新
        let updatedImage = ClothingImage(
          id: oldImage.id,
          clothingId: oldImage.clothingId,
          userId: oldImage.userId,
          originalUrl: oldImage.originalUrl,
          maskUrl: oldImage.maskUrl,
          aimaskUrl: aimaskUrl, // 新しいaimaskUrl
          resultUrl: oldImage.resultUrl,
          originalLocalPath: oldImage.originalLocalPath,
          maskLocalPath: oldImage.maskLocalPath,
          resultLocalPath: oldImage.resultLocalPath,
          createdAt: oldImage.createdAt,
          updatedAt: Date())

        // 配列を更新
        localImages[index] = updatedImage
        localStorageService.saveImageMetadata(for: clothingId, imageMetadata: localImages)
      }
    }
  }

  /// 画像IDからClothingImageデータを取得
  func fetchClothingData(for imageId: UUID) async throws -> ClothingImage? {
    // サーバーから画像データを取得
    let response = try await client
      .from("clothing_images")
      .select("*")
      .eq("id", value: imageId.uuidString)
      .execute()

    return try response.decoded(to: [ClothingImage].self).first
  }
}
