import Foundation
import Supabase
import UIKit

// We need to properly import the helper files within the Xcode project structure
// without adding module qualifiers since they're part of the same module

/// Service for clothing image metadata (database operations)
/// Handles synchronization between local storage and remote database
final class ImageMetadataService {
  static let shared = ImageMetadataService()
  private let client: SupabaseClient
  private let localStorageService = LocalStorageService.shared
  private let updater: ImageMetadataUpdater

  private init(client: SupabaseClient = AuthService.shared.client) {
    self.client = client
    updater = ImageMetadataUpdater(client: client)
  }

  private var currentUser: User? {
    AuthService.shared.currentUser
  }

  /// オフラインファーストアプローチで画像メタデータを取得
  /// 1. まずローカルストレージから取得
  /// 2. サーバーから取得して更新
  /// - Parameter clothingId: 服のID
  /// - Returns: 画像メタデータの配列
  func fetchImages(for clothingId: UUID) async throws -> [ClothingImage] {
    // まずローカルからデータを取得
    let localImages = localStorageService.loadImageMetadata(for: clothingId)

    do {
      // サーバーからのデータ取得を試みる
      let serverImages = try await fetchImagesFromServer(for: clothingId)

      // サーバーからのデータとローカルデータをマージ
      let updatedImages = await syncImagesWithLocalStorage(
        serverImages: serverImages,
        clothingId: clothingId,
        localImages: localImages)

      return updatedImages
    } catch {
      print("🌐 サーバーからのデータ取得に失敗、ローカルデータを使用: \(error.localizedDescription)")
      if localImages.isEmpty {
        throw error // ローカルデータも無ければエラーを投げる
      }
      return localImages
    }
  }

  /// サーバーから画像メタデータを取得
  /// - Parameter clothingId: 服のID
  /// - Returns: 画像メタデータの配列
  private func fetchImagesFromServer(for clothingId: UUID) async throws -> [ClothingImage] {
    let response = try await client
      .from("clothing_images")
      .select("*")
      .eq("clothing_id", value: clothingId.uuidString)
      .execute()
    return try response.decoded(to: [ClothingImage].self)
  }

  /// サーバーとローカルの画像データを同期
  /// - Parameters:
  ///   - serverImages: サーバーから取得した画像メタデータ
  ///   - clothingId: 服のID
  ///   - localImages: ローカルの画像メタデータ
  /// - Returns: 更新された画像メタデータ
  private func syncImagesWithLocalStorage(
    serverImages: [ClothingImage],
    clothingId: UUID,
    localImages: [ClothingImage]) async -> [ClothingImage] {
    var updatedImages = [ClothingImage]()

    for serverImage in serverImages {
      if let localImage = localImages.first(where: { $0.id == serverImage.id }) {
        // 既存の画像を更新
        let updatedImage = await updateExistingImage(serverImage: serverImage, localImage: localImage)
        updatedImages.append(updatedImage)
      } else {
        // 新しい画像を追加
        let newImage = await downloadNewImage(serverImage: serverImage)
        updatedImages.append(newImage)
      }
    }

    // 更新された画像メタデータをローカルに保存
    localStorageService.saveImageMetadata(for: clothingId, imageMetadata: updatedImages)

    return updatedImages
  }

  /// 既存のローカル画像を更新
  private func updateExistingImage(serverImage: ClothingImage, localImage: ClothingImage) async -> ClothingImage {
    // ローカルパスを保持したサーバーイメージの新しいインスタンスを作成
    let updatedImage = ClothingImage(
      id: serverImage.id,
      clothingId: serverImage.clothingId,
      userId: serverImage.userId,
      originalUrl: serverImage.originalUrl,
      maskUrl: serverImage.maskUrl,
      aimaskUrl: serverImage.aimaskUrl,
      resultUrl: serverImage.resultUrl,
      originalLocalPath: localImage.originalLocalPath,
      maskLocalPath: localImage.maskLocalPath,
      resultLocalPath: localImage.resultLocalPath,
      createdAt: serverImage.createdAt,
      updatedAt: serverImage.updatedAt)

    // 必要に応じて各画像をダウンロード
    let finalImage = await downloadMissingImages(for: updatedImage)
    return finalImage
  }

  /// 画像が存在しない場合にダウンロードして更新
  private func downloadMissingImages(for image: ClothingImage) async -> ClothingImage {
    var finalImage = image

    // オリジナル画像のダウンロード
    if finalImage.originalLocalPath == nil,
       let urlString = finalImage.originalUrl,
       let url = URL(string: urlString) {
      if let localPath = await downloadImage(from: url, id: finalImage.id, type: "original") {
        finalImage = finalImage.updatingLocalPath(originalLocalPath: localPath)
      }
    }

    // マスク画像のダウンロード
    if finalImage.maskLocalPath == nil,
       let urlString = finalImage.maskUrl,
       let url = URL(string: urlString) {
      if let localPath = await downloadImage(from: url, id: finalImage.id, type: "mask") {
        finalImage = finalImage.updatingLocalPath(maskLocalPath: localPath)
      }
    }

    // 結果画像のダウンロード
    if finalImage.resultLocalPath == nil,
       let urlString = finalImage.resultUrl,
       let url = URL(string: urlString) {
      if let localPath = await downloadImage(from: url, id: finalImage.id, type: "result") {
        finalImage = finalImage.updatingLocalPath(resultLocalPath: localPath)
      }
    }

    return finalImage
  }

  /// 新しい画像をダウンロードして追加
  private func downloadNewImage(serverImage: ClothingImage) async -> ClothingImage {
    var originalLocalPath: String?
    var maskLocalPath: String?
    var resultLocalPath: String?

    // 各URLからファイルをダウンロード
    if let urlString = serverImage.originalUrl, let url = URL(string: urlString) {
      originalLocalPath = await downloadImage(from: url, id: serverImage.id, type: "original")
    }

    if let urlString = serverImage.maskUrl, let url = URL(string: urlString) {
      maskLocalPath = await downloadImage(from: url, id: serverImage.id, type: "mask")
    }

    if let urlString = serverImage.resultUrl, let url = URL(string: urlString) {
      resultLocalPath = await downloadImage(from: url, id: serverImage.id, type: "result")
    }

    // 新しいインスタンスを作成してローカルパスを設定
    return ClothingImage(
      id: serverImage.id,
      clothingId: serverImage.clothingId,
      userId: serverImage.userId,
      originalUrl: serverImage.originalUrl,
      maskUrl: serverImage.maskUrl,
      aimaskUrl: serverImage.aimaskUrl,
      resultUrl: serverImage.resultUrl,
      originalLocalPath: originalLocalPath,
      maskLocalPath: maskLocalPath,
      resultLocalPath: resultLocalPath,
      createdAt: serverImage.createdAt,
      updatedAt: serverImage.updatedAt)
  }

  /// URLから画像をダウンロードしてローカルに保存
  private func downloadImage(from url: URL, id: UUID, type: String) async -> String? {
    return await withCheckedContinuation { continuation in
      localStorageService.downloadAndSaveImage(from: url, id: id, type: type) { localPath, _ in
        continuation.resume(returning: localPath)
      }
    }
  }

  /// Add a new image metadata record
  func addImage(
    for clothingId: UUID,
    originalUrl: String,
    aimaskUrl: String? = nil,
    maskUrl: String? = nil,
    resultUrl: String? = nil) async throws {
    guard let user = currentUser else {
      throw NSError(
        domain: "auth", code: 401,
        userInfo: [NSLocalizedDescriptionKey: "ユーザーが未ログインです"])
    }

    let imageId = UUID()
    let newImage = NewClothingImage(
      id: imageId,
      clothingID: clothingId,
      userID: user.id,
      originalURL: originalUrl,
      aimaskURL: aimaskUrl,
      maskURL: maskUrl,
      resultURL: resultUrl,
      createdAt: ISO8601DateFormatter().string(from: Date()))

    // サーバーに画像メタデータを保存
    _ = try await client
      .from("clothing_images")
      .insert(newImage)
      .execute()

    // ローカルにも画像メタデータを保存
    let newClothingImage = ClothingImage(
      id: imageId,
      clothingId: clothingId,
      userId: String(describing: user.id),  // Explicitly convert user.id to String
      originalUrl: originalUrl,
      maskUrl: maskUrl,
      aimaskUrl: aimaskUrl,
      resultUrl: resultUrl,
      createdAt: Date(),
      updatedAt: Date())

    var localImages = localStorageService.loadImageMetadata(for: clothingId)
    localImages.append(newClothingImage)
    localStorageService.saveImageMetadata(for: clothingId, imageMetadata: localImages)

    // URLから画像をダウンロード
    if let url = URL(string: originalUrl) {
      _ = await downloadImage(from: url, id: imageId, type: "original")
    }
  }

  /// Update the mask URL for an existing image record
  func updateImageMask(imageId: UUID, maskUrl: String) async throws {
    try await updater.updateImageMask(imageId: imageId, maskUrl: maskUrl)
  }

  /// Update the result URL for an existing image record
  func updateImageResult(imageId: UUID, resultUrl: String) async throws {
    try await updater.updateImageResult(imageId: imageId, resultUrl: resultUrl)
  }

  /// Update both mask and result URLs for an existing image record
  func updateImageMaskAndResult(
    imageId: UUID,
    maskUrl: String?,
    resultUrl: String?) async throws {
    try await updater.updateImageMaskAndResult(
      imageId: imageId,
      maskUrl: maskUrl,
      resultUrl: resultUrl)
  }

  /// Update the AI mask URL for an existing image record
  func updateImageAIMask(imageId: UUID, aimaskUrl: String) async throws {
    try await updater.updateImageAIMask(imageId: imageId, aimaskUrl: aimaskUrl)
  }

  /// Function to get image from an existing record
  func getImage(imageId: UUID) async throws -> ClothingImage? {
    // サーバー上のデータを検索
    do {
      // 単一の画像を取得するクエリを実行
      let response = try await client
        .from("clothing_images")
        .select("*")
        .eq("id", value: imageId.uuidString)
        .execute()

      // レスポンスをデコード
      let images = try response.decoded(to: [ClothingImage].self)

      // 画像が見つかった場合
      guard let image = images.first else {
        // 見つからない場合はnilを返す
        return nil
      }

      // clothingIdは既にnon-optional型なので、強制アンラップは不要
      let clothingId = image.clothingId

      // サーバーから関連する全ての画像を取得
      do {
        let allImages = try await fetchImagesFromServer(for: clothingId)

        // 元の画像IDに一致する画像を探すためのループ
        for enrichedImage in allImages {
          // UUIDをString型に明示的に変換して比較
          let enrichedIdString: String = enrichedImage.id.uuidString
          let searchIdString: String = imageId.uuidString
          if enrichedIdString == searchIdString {
            return enrichedImage
          }
        }

        // 一致する画像が見つからない場合は元の画像を返す
        return image
      } catch {
        // 関連画像の取得に失敗した場合は元の画像を返す
        print("関連画像の取得に失敗: \(error.localizedDescription)")
        return image
      }
    } catch {
      // API呼び出しに失敗した場合
      print("画像の取得に失敗: \(error.localizedDescription)")
      throw error
    }
  }
}
