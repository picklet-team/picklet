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
        print("🔧 ImageStorageService 初期化: デフォルトバケット = \(defaultBucketName)")
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
        print("📤 画像のアップロード開始: filename=\(filename)")
        
        // 1. 画像をJPEGデータに変換
        let data = try prepareImageData(image)
        
        // 2. 画像をSupabaseにアップロード
        let bucket = bucketName ?? defaultBucketName
        let path = "\(filename).jpg"
        try await uploadToSupabase(data: data, bucket: bucket, path: path)
        
        // 3. 公開URLを生成して返す
        return try generatePublicURL(bucket: bucket, path: path)
    }
    
    /// 画像をJPEGデータに変換
    private func prepareImageData(_ image: UIImage) throws -> Data {
        let resized = image.resized(toMaxPixel: 800)
        guard let data = resized.jpegData(compressionQuality: 0.6) else {
            let error = NSError(
                domain: "upload",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "画像の変換に失敗しました"]
            )
            print("❌ 画像変換エラー: \(error.localizedDescription)")
            throw error
        }
        print("✓ 画像変換成功: \(data.count) bytes")
        return data
    }
    
    /// Supabaseストレージに画像をアップロード
    private func uploadToSupabase(data: Data, bucket: String, path: String) async throws {
        print("🔄 Supabaseへのアップロード開始: bucket=\(bucket), path=\(path)")
        do {
            _ = try await client.storage
                .from(bucket)
                .upload(
                    path,
                    data: data,
                    options: FileOptions(contentType: "image/jpeg")
                )
            print("✅ Supabaseへのアップロード成功")
        } catch {
            print("❌ Supabase アップロードエラー: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// 公開URLを生成
    private func generatePublicURL(bucket: String, path: String) throws -> String {
        guard let baseURL = Bundle.main
            .object(forInfoDictionaryKey: "SUPABASE_URL") as? String
        else {
            let error = NSError(
                domain: "config",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Supabase URLが見つかりません"]
            )
            print("❌ SUPABASE_URL 取得エラー: Info.plistにキーがありません")
            throw error
        }

        print("✓ SUPABASE_URL 取得成功: \(baseURL)")

        // URLを生成
        let urlString = "\(baseURL)/storage/v1/object/public/\(bucket)/\(path)"
        print("📷 画像URL生成完了: \(urlString)")

        // URL形式の検証
        if let url = URL(string: urlString) {
            print("✅ URL形式の検証OK: \(url)")
        } else {
            print("⚠️ 無効なURL文字列: \(urlString)")
        }

        return urlString
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
