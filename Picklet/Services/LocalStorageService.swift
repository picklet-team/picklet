import Foundation
import UIKit

/// ローカルストレージを管理するサービス
class LocalStorageService {
  static let shared = LocalStorageService()

  private let fileManager = FileManager.default
  private let documentsDirectory: URL

  // 画像保存用のディレクトリ
  private let imagesDirectory: URL

  private init() {
    // ドキュメントディレクトリのパスを取得
    documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!

    // 画像保存用のディレクトリパスを作成
    imagesDirectory = documentsDirectory.appendingPathComponent("images")

    // 画像ディレクトリが存在しない場合は作成
    if !fileManager.fileExists(atPath: imagesDirectory.path) {
      do {
        try fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
        print("✅ 画像保存ディレクトリを作成: \(imagesDirectory.path)")
      } catch {
        print("❌ 画像保存ディレクトリ作成エラー: \(error)")
      }
    }
  }

  // MARK: - 画像の保存と読み込み

  /// 画像をローカルに保存し、ローカルパスを返す
  /// - Parameters:
  ///   - image: 保存するUIImage
  ///   - id: 画像の一意なID (UUID)
  ///   - type: 画像タイプ (original, mask, resultなど)
  /// - Returns: ローカルファイルパス
  func saveImage(_ image: UIImage, id: UUID, type: String) -> String? {
    let filename = "\(id.uuidString)_\(type).jpg"
    let fileURL = imagesDirectory.appendingPathComponent(filename)

    guard let data = image.jpegData(compressionQuality: 0.8) else {
      print("❌ 画像をJPEGデータに変換できませんでした")
      return nil
    }

    do {
      try data.write(to: fileURL)
      print("✅ 画像をローカルに保存: \(fileURL.path)")
      return fileURL.path
    } catch {
      print("❌ 画像保存エラー: \(error)")
      return nil
    }
  }

  /// ローカルパスから画像を読み込む
  /// - Parameter path: ローカルファイルパス
  /// - Returns: 読み込んだUIImage、または失敗時にnil
  func loadImage(from path: String) -> UIImage? {
    guard fileManager.fileExists(atPath: path) else {
      print("❌ 画像ファイルが存在しません: \(path)")
      return nil
    }

    if let image = UIImage(contentsOfFile: path) {
      print("✅ 画像をローカルから読み込み: \(path)")
      return image
    } else {
      print("❌ 画像読み込みエラー: \(path)")
      return nil
    }
  }

  /// URLから画像をダウンロードし、ローカルに保存
  /// - Parameters:
  ///   - url: ダウンロードするURL
  ///   - id: 画像のID
  ///   - type: 画像タイプ
  ///   - completion: 完了ハンドラ (ローカルパス, エラー)
  func downloadAndSaveImage(from url: URL, id: UUID, type: String, completion: @escaping (String?, Error?) -> Void) {
    URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
      guard let self = self else { return }

      if let error = error {
        print("❌ 画像ダウンロードエラー: \(error)")
        completion(nil, error)
        return
      }

      guard let data = data, let image = UIImage(data: data) else {
        let error = NSError(
          domain: "LocalStorageService",
          code: 1,
          userInfo: [NSLocalizedDescriptionKey: "画像データの変換に失敗しました"])
        completion(nil, error)
        return
      }

      let localPath = self.saveImage(image, id: id, type: type)
      completion(localPath, nil)
    }.resume()
  }

  // MARK: - メタデータの保存

  /// ClothingImageメタデータをUserDefaultsに保存
  /// - Parameters:
  ///   - clothingId: 服のID
  ///   - imageMetadata: 画像メタデータの配列
  func saveImageMetadata(for clothingId: UUID, imageMetadata: [ClothingImage]) {
    // メタデータをシリアライズ可能な形式に変換
    let metadataArray = imageMetadata.map { image -> [String: Any] in
      return [
        "id": image.id.uuidString,
        "clothingId": image.clothingId.uuidString,
        "userId": image.userId.uuidString,
        "originalUrl": image.originalUrl ?? "",
        "aimaskUrl": image.aimaskUrl ?? "",
        "maskUrl": image.maskUrl ?? "",
        "resultUrl": image.resultUrl ?? "",
        "originalLocalPath": image.originalLocalPath ?? "",
        "maskLocalPath": image.maskLocalPath ?? "",
        "resultLocalPath": image.resultLocalPath ?? "",
        "createdAt": image.createdAt.timeIntervalSince1970,
        "updatedAt": image.updatedAt.timeIntervalSince1970
      ]
    }

    UserDefaults.standard.set(metadataArray, forKey: "clothingImages_\(clothingId.uuidString)")
    print("✅ \(clothingId) の画像メタデータを保存: \(metadataArray.count)件")
  }

  /// ClothingImageメタデータをUserDefaultsから読み込み
  /// - Parameter clothingId: 服のID
  /// - Returns: 画像メタデータの配列
  func loadImageMetadata(for clothingId: UUID) -> [ClothingImage] {
    let key = "clothingImages_\(clothingId.uuidString)"
    guard let metadataArray = UserDefaults.standard.array(forKey: key) as? [[String: Any]] else {
      print("⚠️ \(clothingId) の画像メタデータがローカルに存在しません")
      return []
    }

    let imageMetadata = metadataArray.compactMap { dict -> ClothingImage? in
      guard
        let idString = dict["id"] as? String,
        let clothingIdString = dict["clothingId"] as? String,
        let userIdString = dict["userId"] as? String, !userIdString.isEmpty,
        let id = UUID(uuidString: idString),
        let clothingId = UUID(uuidString: clothingIdString),
        let userId = UUID(uuidString: userIdString),
        let createdAtTimestamp = dict["createdAt"] as? Double,
        let updatedAtTimestamp = dict["updatedAt"] as? Double
      else {
        return nil
      }

      return ClothingImage(
        id: id,
        clothingId: clothingId,
        userId: userId,
        originalUrl: dict["originalUrl"] as? String,
        aimaskUrl: dict["aimaskUrl"] as? String,
        maskUrl: dict["maskUrl"] as? String,
        resultUrl: dict["resultUrl"] as? String,
        originalLocalPath: dict["originalLocalPath"] as? String,
        maskLocalPath: dict["maskLocalPath"] as? String,
        resultLocalPath: dict["resultLocalPath"] as? String,
        createdAt: Date(timeIntervalSince1970: createdAtTimestamp),
        updatedAt: Date(timeIntervalSince1970: updatedAtTimestamp))
    }

    print("✅ \(clothingId) の画像メタデータを読み込み: \(imageMetadata.count)件")
    return imageMetadata
  }

  /// 全ての服の画像メタデータを削除（キャッシュクリア用）
  func clearAllImageMetadata() {
    let defaults = UserDefaults.standard
    let allKeys = defaults.dictionaryRepresentation().keys

    for key in allKeys where key.starts(with: "clothingImages_") {
      defaults.removeObject(forKey: key)
    }
    print("✅ すべての画像メタデータをクリア")
  }
}
