import Foundation
import Supabase
import UIKit

/// Service for clothing image metadata (database operations)
final class ImageMetadataService {
    static let shared = ImageMetadataService()
    private let client: SupabaseClient
    private let localStorageService = LocalStorageService.shared

    private init(client: SupabaseClient = AuthService.shared.client) {
        self.client = client
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
            let updatedImages = await syncImagesWithLocalStorage(serverImages: serverImages, clothingId: clothingId, localImages: localImages)
            
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
    private func syncImagesWithLocalStorage(serverImages: [ClothingImage], clothingId: UUID, localImages: [ClothingImage]) async -> [ClothingImage] {
        var updatedImages = [ClothingImage]()
        
        for serverImage in serverImages {
            // マッチするローカル画像を検索
            if let localImage = localImages.first(where: { $0.id == serverImage.id }) {
                // ローカルパスを保持したサーバーイメージの新しいインスタンスを作成
                let updatedImage = ClothingImage(
                    id: serverImage.id,
                    clothingId: serverImage.clothingId,
                    userId: serverImage.userId,
                    originalUrl: serverImage.originalUrl,
                    maskUrl: serverImage.maskUrl,
                    resultUrl: serverImage.resultUrl,
                    originalLocalPath: localImage.originalLocalPath,
                    maskLocalPath: localImage.maskLocalPath,
                    resultLocalPath: localImage.resultLocalPath,
                    createdAt: serverImage.createdAt,
                    updatedAt: serverImage.updatedAt
                )
                
                var finalImage = updatedImage
                
                // 必要に応じて画像をダウンロード
                if updatedImage.originalLocalPath == nil, let urlString = updatedImage.originalUrl, let url = URL(string: urlString) {
                    if let localPath = await downloadImage(from: url, id: updatedImage.id, type: "original") {
                        finalImage = ClothingImage(
                            id: finalImage.id,
                            clothingId: finalImage.clothingId,
                            userId: finalImage.userId,
                            originalUrl: finalImage.originalUrl,
                            maskUrl: finalImage.maskUrl,
                            resultUrl: finalImage.resultUrl,
                            originalLocalPath: localPath,
                            maskLocalPath: finalImage.maskLocalPath,
                            resultLocalPath: finalImage.resultLocalPath,
                            createdAt: finalImage.createdAt,
                            updatedAt: finalImage.updatedAt
                        )
                    }
                }
                
                if finalImage.maskLocalPath == nil, let urlString = finalImage.maskUrl, let url = URL(string: urlString) {
                    if let localPath = await downloadImage(from: url, id: finalImage.id, type: "mask") {
                        finalImage = ClothingImage(
                            id: finalImage.id,
                            clothingId: finalImage.clothingId,
                            userId: finalImage.userId,
                            originalUrl: finalImage.originalUrl,
                            maskUrl: finalImage.maskUrl,
                            resultUrl: finalImage.resultUrl,
                            originalLocalPath: finalImage.originalLocalPath,
                            maskLocalPath: localPath,
                            resultLocalPath: finalImage.resultLocalPath,
                            createdAt: finalImage.createdAt,
                            updatedAt: finalImage.updatedAt
                        )
                    }
                }
                
                if finalImage.resultLocalPath == nil, let urlString = finalImage.resultUrl, let url = URL(string: urlString) {
                    if let localPath = await downloadImage(from: url, id: finalImage.id, type: "result") {
                        finalImage = ClothingImage(
                            id: finalImage.id,
                            clothingId: finalImage.clothingId,
                            userId: finalImage.userId,
                            originalUrl: finalImage.originalUrl,
                            maskUrl: finalImage.maskUrl,
                            resultUrl: finalImage.resultUrl,
                            originalLocalPath: finalImage.originalLocalPath,
                            maskLocalPath: finalImage.maskLocalPath,
                            resultLocalPath: localPath,
                            createdAt: finalImage.createdAt,
                            updatedAt: finalImage.updatedAt
                        )
                    }
                }
                
                updatedImages.append(finalImage)
            } else {
                // ローカルに存在しない新しい画像
                let newImage = serverImage
                
                // 新しい画像をダウンロード
                var originalLocalPath: String? = nil
                var maskLocalPath: String? = nil
                var resultLocalPath: String? = nil
                
                if let urlString = newImage.originalUrl, let url = URL(string: urlString) {
                    originalLocalPath = await downloadImage(from: url, id: newImage.id, type: "original")
                }
                
                if let urlString = newImage.maskUrl, let url = URL(string: urlString) {
                    maskLocalPath = await downloadImage(from: url, id: newImage.id, type: "mask")
                }
                
                if let urlString = newImage.resultUrl, let url = URL(string: urlString) {
                    resultLocalPath = await downloadImage(from: url, id: newImage.id, type: "result")
                }
                
                // 新しいインスタンスを作成してローカルパスを設定
                let finalImage = ClothingImage(
                    id: newImage.id,
                    clothingId: newImage.clothingId,
                    userId: newImage.userId,
                    originalUrl: newImage.originalUrl,
                    maskUrl: newImage.maskUrl,
                    resultUrl: newImage.resultUrl,
                    originalLocalPath: originalLocalPath,
                    maskLocalPath: maskLocalPath,
                    resultLocalPath: resultLocalPath,
                    createdAt: newImage.createdAt,
                    updatedAt: newImage.updatedAt
                )
                
                updatedImages.append(finalImage)
            }
        }
        
        // 更新された画像メタデータをローカルに保存
        localStorageService.saveImageMetadata(for: clothingId, imageMetadata: updatedImages)
        
        return updatedImages
    }
    
    /// URLから画像をダウンロードしてローカルに保存
    /// - Parameters:
    ///   - url: ダウンロードするURL
    ///   - id: 画像のID
    ///   - type: 画像タイプ (original/mask/result)
    /// - Returns: ローカル保存パス
    private func downloadImage(from url: URL, id: UUID, type: String) async -> String? {
        return await withCheckedContinuation { continuation in
            localStorageService.downloadAndSaveImage(from: url, id: id, type: type) { localPath, error in
                continuation.resume(returning: localPath)
            }
        }
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
        
        let imageId = UUID()
        let newImage = NewClothingImage(
            id: imageId,
            clothingID: clothingId,
            userID: user.id,
            originalURL: originalUrl,
            maskURL: maskUrl,
            resultURL: resultUrl,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        
        // サーバーに画像メタデータを保存
        _ = try await client
            .from("clothing_images")
            .insert(newImage)
            .execute()
        
        // ローカルにも画像メタデータを保存
        let newClothingImage = ClothingImage(
            id: imageId,
            clothingId: clothingId,
            userId: user.id,
            originalUrl: originalUrl,
            maskUrl: maskUrl,
            resultUrl: resultUrl,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        var localImages = localStorageService.loadImageMetadata(for: clothingId)
        localImages.append(newClothingImage)
        localStorageService.saveImageMetadata(for: clothingId, imageMetadata: localImages)
        
        // URLから画像をダウンロード
        if let url = URL(string: originalUrl) {
            _ = await downloadImage(from: url, id: imageId, type: "original")
        }
    }

    /// Update the mask URL for an existing image record
    /// - Parameters:
    ///   - imageId: The UUID of the image record
    ///   - maskUrl: New mask URL string
    func updateImageMask(imageId: UUID, maskUrl: String) async throws {
        // サーバー上のデータを更新
        _ = try await client
            .from("clothing_images")
            .update(["mask_url": maskUrl])
            .eq("id", value: imageId.uuidString)
            .execute()
        
        // ローカルデータも更新
        let response = try await client
            .from("clothing_images")
            .select("*")
            .eq("id", value: imageId.uuidString)
            .execute()
        
        if let image = try? response.decoded(to: [ClothingImage].self).first {
            // clothingIdはオプショナルでなくなったので直接使用可能
            let clothingId = image.clothingId
            var localImages = localStorageService.loadImageMetadata(for: clothingId)
            
            // 対象の画像を見つけて更新
            if let index = localImages.firstIndex(where: { $0.id == imageId }) {
                let oldImage = localImages[index]
                
                // 新しい画像メタデータを作成（maskUrlを更新）
                let updatedImage = ClothingImage(
                    id: oldImage.id,
                    clothingId: oldImage.clothingId,
                    userId: oldImage.userId,
                    originalUrl: oldImage.originalUrl,
                    maskUrl: maskUrl,  // 新しいmaskUrl
                    resultUrl: oldImage.resultUrl,
                    originalLocalPath: oldImage.originalLocalPath,
                    maskLocalPath: oldImage.maskLocalPath,
                    resultLocalPath: oldImage.resultLocalPath,
                    createdAt: oldImage.createdAt,
                    updatedAt: Date()
                )
                
                // 新しいURLから画像をダウンロード
                var finalImage = updatedImage
                if let url = URL(string: maskUrl) {
                    if let localPath = await downloadImage(from: url, id: imageId, type: "mask") {
                        finalImage = ClothingImage(
                            id: updatedImage.id,
                            clothingId: updatedImage.clothingId,
                            userId: updatedImage.userId,
                            originalUrl: updatedImage.originalUrl,
                            maskUrl: updatedImage.maskUrl,
                            resultUrl: updatedImage.resultUrl,
                            originalLocalPath: updatedImage.originalLocalPath,
                            maskLocalPath: localPath,  // 新しいローカルパス
                            resultLocalPath: updatedImage.resultLocalPath,
                            createdAt: updatedImage.createdAt,
                            updatedAt: updatedImage.updatedAt
                        )
                    }
                }
                
                // 配列を更新
                localImages[index] = finalImage
                localStorageService.saveImageMetadata(for: clothingId, imageMetadata: localImages)
            }
        }
    }

    /// Update the result URL for an existing image record
    /// - Parameters:
    ///   - imageId: The UUID of the image record
    ///   - resultUrl: New result URL string
    func updateImageResult(imageId: UUID, resultUrl: String) async throws {
        // サーバー上のデータを更新
        _ = try await client
            .from("clothing_images")
            .update(["result_url": resultUrl])
            .eq("id", value: imageId.uuidString)
            .execute()
        
        // ローカルデータも更新
        let response = try await client
            .from("clothing_images")
            .select("*")
            .eq("id", value: imageId.uuidString)
            .execute()
        
        if let image = try? response.decoded(to: [ClothingImage].self).first {
            let clothingId = image.clothingId
            var localImages = localStorageService.loadImageMetadata(for: clothingId)
            
            // 対象の画像を見つけて更新
            if let index = localImages.firstIndex(where: { $0.id == imageId }) {
                let oldImage = localImages[index]
                
                // 新しい画像メタデータを作成（resultUrlを更新）
                let updatedImage = ClothingImage(
                    id: oldImage.id,
                    clothingId: oldImage.clothingId,
                    userId: oldImage.userId,
                    originalUrl: oldImage.originalUrl,
                    maskUrl: oldImage.maskUrl,
                    resultUrl: resultUrl,  // 新しいresultUrl
                    originalLocalPath: oldImage.originalLocalPath,
                    maskLocalPath: oldImage.maskLocalPath,
                    resultLocalPath: oldImage.resultLocalPath,
                    createdAt: oldImage.createdAt,
                    updatedAt: Date()
                )
                
                // 新しいURLから画像をダウンロード
                var finalImage = updatedImage
                if let url = URL(string: resultUrl) {
                    if let localPath = await downloadImage(from: url, id: imageId, type: "result") {
                        finalImage = ClothingImage(
                            id: updatedImage.id,
                            clothingId: updatedImage.clothingId,
                            userId: updatedImage.userId,
                            originalUrl: updatedImage.originalUrl,
                            maskUrl: updatedImage.maskUrl,
                            resultUrl: updatedImage.resultUrl,
                            originalLocalPath: updatedImage.originalLocalPath,
                            maskLocalPath: updatedImage.maskLocalPath,
                            resultLocalPath: localPath,  // 新しいローカルパス
                            createdAt: updatedImage.createdAt,
                            updatedAt: updatedImage.updatedAt
                        )
                    }
                }
                
                // 配列を更新
                localImages[index] = finalImage
                localStorageService.saveImageMetadata(for: clothingId, imageMetadata: localImages)
            }
        }
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
        // サーバー上のデータを更新
        _ = try await client
            .from("clothing_images")
            .update([
                "mask_url": maskUrl,
                "result_url": resultUrl
            ])
            .eq("id", value: imageId.uuidString)
            .execute()
        
        // ローカルデータも更新
        let response = try await client
            .from("clothing_images")
            .select("*")
            .eq("id", value: imageId.uuidString)
            .execute()
        
        if let image = try? response.decoded(to: [ClothingImage].self).first {
            let clothingId = image.clothingId
            var localImages = localStorageService.loadImageMetadata(for: clothingId)
            
            // 対象の画像を見つけて更新
            if let index = localImages.firstIndex(where: { $0.id == imageId }) {
                let oldImage = localImages[index]
                
                // 新しい画像メタデータを作成（maskUrlとresultUrlを更新）
                let updatedImage = ClothingImage(
                    id: oldImage.id,
                    clothingId: oldImage.clothingId,
                    userId: oldImage.userId,
                    originalUrl: oldImage.originalUrl,
                    maskUrl: maskUrl,  // 新しいmaskUrl
                    resultUrl: resultUrl,  // 新しいresultUrl
                    originalLocalPath: oldImage.originalLocalPath,
                    maskLocalPath: oldImage.maskLocalPath,
                    resultLocalPath: oldImage.resultLocalPath,
                    createdAt: oldImage.createdAt,
                    updatedAt: Date()
                )
                
                // 新しい画像をダウンロード
                var finalImage = updatedImage
                
                // マスク画像をダウンロード
                if let maskUrlString = maskUrl, let url = URL(string: maskUrlString) {
                    if let localPath = await downloadImage(from: url, id: imageId, type: "mask") {
                        finalImage = ClothingImage(
                            id: finalImage.id,
                            clothingId: finalImage.clothingId,
                            userId: finalImage.userId,
                            originalUrl: finalImage.originalUrl,
                            maskUrl: finalImage.maskUrl,
                            resultUrl: finalImage.resultUrl,
                            originalLocalPath: finalImage.originalLocalPath,
                            maskLocalPath: localPath,  // 新しいローカルパス
                            resultLocalPath: finalImage.resultLocalPath,
                            createdAt: finalImage.createdAt,
                            updatedAt: finalImage.updatedAt
                        )
                    }
                }
                
                // 結果画像をダウンロード
                if let resultUrlString = resultUrl, let url = URL(string: resultUrlString) {
                    if let localPath = await downloadImage(from: url, id: imageId, type: "result") {
                        finalImage = ClothingImage(
                            id: finalImage.id,
                            clothingId: finalImage.clothingId,
                            userId: finalImage.userId,
                            originalUrl: finalImage.originalUrl,
                            maskUrl: finalImage.maskUrl,
                            resultUrl: finalImage.resultUrl,
                            originalLocalPath: finalImage.originalLocalPath,
                            maskLocalPath: finalImage.maskLocalPath,
                            resultLocalPath: localPath,  // 新しいローカルパス
                            createdAt: finalImage.createdAt,
                            updatedAt: finalImage.updatedAt
                        )
                    }
                }
                
                // 配列を更新
                localImages[index] = finalImage
                localStorageService.saveImageMetadata(for: clothingId, imageMetadata: localImages)
            }
        }
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
