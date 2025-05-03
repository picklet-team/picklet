import Foundation
import Storage
import Supabase
import UIKit

/// Supabase Storage を扱う汎用イメージサービス
final class ImageStorageService {
    /// デフォルトバケット名を使うシングルトン
    static let shared = ImageStorageService()
    
    private let client: SupabaseClient
    /// デフォルトバケット名
    private let defaultBucketName: String
    
    /// 内部用イニシャライザ
    private init(defaultBucketName: String = "originals",
                 client: SupabaseClient = AuthService.shared.client) {
        self.defaultBucketName = defaultBucketName
        self.client = client
    }
    
    /// カスタムバケット向けのイニシャライザ
    convenience init(bucketName: String) {
        self.init(defaultBucketName: bucketName)
    }
    
    /// 画像をアップロードし、公開 URL を返す
    /// - Parameters:
    ///   - image: アップロードする UIImage
    ///   - filename: ストレージ上のファイル名（拡張子なし）
    ///   - bucketName: 使用するバケット名。未指定時はデフォルトバケットを使う
    /// - Throws: 画像変換／アップロード／設定取得エラー
    /// - Returns: 公開 URL string
    func uploadImage(
        _ image: UIImage,
        for filename: String,
        bucketName: String? = nil
    ) async throws -> String {
        let resized = image.resized(toMaxPixel: 800)
        guard let data = resized.jpegData(compressionQuality: 0.6) else {
            throw NSError(domain: "upload", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "画像の変換に失敗しました"])
        }
        let bucket = bucketName ?? defaultBucketName
        let path = "\(filename).jpg"
        _ = try await client.storage
            .from(bucket)
            .upload(path, data: data,
                    options: FileOptions(contentType: "image/jpeg"))
        guard let baseURL = Bundle.main
                .object(forInfoDictionaryKey: "SUPABASE_URL") as? String
        else {
            throw NSError(domain: "config", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "Supabase URLが見つかりません"])
        }
        return "\(baseURL)/storage/v1/object/public/\(bucket)/\(path)"
    }
    
//    /// 指定バケット内のパスからオブジェクト一覧を取得し、URL 配列として返す
//    /// - Parameters:
//    ///   - path: バケット内のリスト対象パス（例: ユーザID）
//    ///   - bucketName: 使用するバケット名。未指定時はデフォルトバケットを使う
//    /// - Returns: 取得したオブジェクトの公開 URL 一覧
//    func listImageURLs(
//        under path: String,
//        bucketName: String? = nil
//    ) async throws -> [URL] {
//        guard let userId = AuthService.shared.currentUser?.id.uuidString else {
//            throw NSError(domain: "auth", code: 401,
//                          userInfo: [NSLocalizedDescriptionKey: "ユーザーが未ログインです"])
//        }
//        let bucket = bucketName ?? defaultBucketName
//        let objects = try await client.storage
//            .from(bucket)
//            .list(path: path)
//        guard let baseURL = Bundle.main
//                .object(forInfoDictionaryKey: "SUPABASE_URL") as? String
//        else {
//            throw NSError(domain: "config", code: 0,
//                          userInfo: [NSLocalizedDescriptionKey: "Supabase URLが見つかりません"])
//        }
//        return objects.compactMap { obj in
//            URL(string: "\(baseURL)/storage/v1/object/public/\(bucket)/\(path)/\(obj.name)")
//        }
//    }
}
