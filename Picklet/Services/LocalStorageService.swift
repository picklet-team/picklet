import Foundation
import UIKit

/// ローカルストレージを管理するサービス（オフライン専用）
class LocalStorageService {
  static let shared = LocalStorageService()

  private let fileManager = FileManager.default
  private let groupIdentifier = "group.com.yourdomain.picklet" // App Group識別子を設定
  private let documentsDirectory: URL
  private let userDefaults: UserDefaults

  // 画像保存用のディレクトリ
  private let imagesDirectory: URL

  // 衣類データ保存用のディレクトリ
  private let clothingDirectory: URL

  private init() {
    // アプリグループのコンテナURLを取得
    if let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier) {
      documentsDirectory = containerURL
      userDefaults = UserDefaults(suiteName: groupIdentifier) ?? .standard
    } else {
      // フォールバックとして通常のドキュメントディレクトリを使用
      print("⚠️ アプリグループが利用できないため、通常のドキュメントディレクトリを使用します")
      documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
      userDefaults = .standard
    }

    // 画像保存用のディレクトリパスを作成
    imagesDirectory = documentsDirectory.appendingPathComponent("images")

    // 衣類データ保存用のディレクトリパスを作成
    clothingDirectory = documentsDirectory.appendingPathComponent("clothing")

    // 必要なディレクトリが存在しない場合は作成
    for directory in [imagesDirectory, clothingDirectory] {
      if !fileManager.fileExists(atPath: directory.path) {
        do {
          try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
          print("✅ ディレクトリを作成: \(directory.path)")
        } catch {
          print("❌ ディレクトリ作成エラー: \(error)")
        }
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
    // パスの存在確認
    guard fileManager.fileExists(atPath: path) else {
      print("❌ 画像ファイルが存在しません: \(path)")

      // パスが古いドキュメントディレクトリを参照している場合、新しいパスに変換してみる
      let filename = URL(fileURLWithPath: path).lastPathComponent
      let newPath = imagesDirectory.appendingPathComponent(filename).path

      if fileManager.fileExists(atPath: newPath) {
        print("🔄 新しいパスで画像を発見: \(newPath)")
        return UIImage(contentsOfFile: newPath)
      }

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

  /// URLから画像をダウンロードしてローカルに保存
  /// - Parameters:
  ///   - url: ダウンロード元のURL
  ///   - id: 画像の一意なID
  ///   - type: 画像タイプ (original, mask, resultなど)
  ///   - completion: ダウンロード完了後に呼ばれるクロージャ。ローカルパスとエラーを返す
  func downloadAndSaveImage(
    from url: URL,
    id: UUID,
    type: String,
    completion: @escaping (String?, Error?) -> Void) {
    let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
      guard let self = self else { return }

      if let error = error {
        print("❌ 画像ダウンロードエラー: \(error)")
        completion(nil, error)
        return
      }

      guard let data = data,
            let image = UIImage(data: data)
      else {
        let error = NSError(domain: "LocalStorageService",
                            code: 1_002,
                            userInfo: [NSLocalizedDescriptionKey: "無効な画像データです"])
        completion(nil, error)
        return
      }

      // 画像を保存
      let path = self.saveImage(image, id: id, type: type)
      completion(path, nil)
    }

    task.resume()
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
        "originalLocalPath": image.originalLocalPath ?? "",
        "maskLocalPath": image.maskLocalPath ?? "",
        "resultLocalPath": image.resultLocalPath ?? "",
        "createdAt": image.createdAt.timeIntervalSince1970,
        "updatedAt": image.updatedAt.timeIntervalSince1970
      ]
    }

    userDefaults.set(metadataArray, forKey: "clothingImages_\(clothingId.uuidString)")
    userDefaults.synchronize()
    print("✅ \(clothingId) の画像メタデータを保存: \(metadataArray.count)件")
  }

  /// ClothingImageメタデータをUserDefaultsから読み込み
  /// - Parameter clothingId: 服のID
  /// - Returns: 画像メタデータの配列
  func loadImageMetadata(for clothingId: UUID) -> [ClothingImage] {
    let key = "clothingImages_\(clothingId.uuidString)"
    guard let metadataArray = userDefaults.array(forKey: key) as? [[String: Any]] else {
      print("⚠️ \(clothingId) の画像メタデータがローカルに存在しません")
      return []
    }

    let imageMetadata = metadataArray.compactMap { dict -> ClothingImage? in
      guard
        let idString = dict["id"] as? String,
        let clothingIdString = dict["clothingId"] as? String,
        let id = UUID(uuidString: idString),
        let clothingId = UUID(uuidString: clothingIdString),
        let createdAtTimestamp = dict["createdAt"] as? Double,
        let updatedAtTimestamp = dict["updatedAt"] as? Double
      else {
        return nil
      }

      // パスの修正：古いパスを新しいパスに変換
      let paths = fixImagePaths(
        originalPath: dict["originalLocalPath"] as? String,
        maskPath: dict["maskLocalPath"] as? String,
        resultPath: dict["resultLocalPath"] as? String)

      return ClothingImage(
        id: id,
        clothingId: clothingId,
        originalLocalPath: paths.originalPath,
        maskLocalPath: paths.maskPath,
        resultLocalPath: paths.resultPath,
        createdAt: Date(timeIntervalSince1970: createdAtTimestamp),
        updatedAt: Date(timeIntervalSince1970: updatedAtTimestamp))
    }

    print("✅ \(clothingId) の画像メタデータを読み込み: \(imageMetadata.count)件")
    return imageMetadata
  }

  /// 画像パスを修正する
  /// - Parameters:
  ///   - originalPath: オリジナル画像のパス
  ///   - maskPath: マスク画像のパス
  ///   - resultPath: 結果画像のパス
  /// - Returns: 修正されたパスのタプル
  private func fixImagePaths(originalPath: String?, maskPath: String?, resultPath: String?) ->
  (originalPath: String?, maskPath: String?, resultPath: String?) {
    var fixedOriginalPath = originalPath
    var fixedMaskPath = maskPath
    var fixedResultPath = resultPath

    // パスが空でなく、ファイルが存在しない場合は修正を試みる
    if let path = fixedOriginalPath, !path.isEmpty, !fileManager.fileExists(atPath: path) {
      let filename = URL(fileURLWithPath: path).lastPathComponent
      let newPath = imagesDirectory.appendingPathComponent(filename).path
      if fileManager.fileExists(atPath: newPath) {
        fixedOriginalPath = newPath
        print("🔄 パスを修正: \(path) -> \(newPath)")
      }
    }

    // マスクとリザルトの画像パスも同様に修正
    if let path = fixedMaskPath, !path.isEmpty, !fileManager.fileExists(atPath: path) {
      let filename = URL(fileURLWithPath: path).lastPathComponent
      let newPath = imagesDirectory.appendingPathComponent(filename).path
      if fileManager.fileExists(atPath: newPath) {
        fixedMaskPath = newPath
      }
    }

    if let path = fixedResultPath, !path.isEmpty, !fileManager.fileExists(atPath: path) {
      let filename = URL(fileURLWithPath: path).lastPathComponent
      let newPath = imagesDirectory.appendingPathComponent(filename).path
      if fileManager.fileExists(atPath: newPath) {
        fixedResultPath = newPath
      }
    }

    return (fixedOriginalPath, fixedMaskPath, fixedResultPath)
  }

  // MARK: - 衣類データ管理

  /// 衣類データを保存
  /// - Parameter clothing: 保存する衣類データ
  /// - Returns: 保存が成功したかどうか
  func saveClothing(_ clothing: Clothing) -> Bool {
    let encoder = JSONEncoder()
    let fileURL = clothingDirectory.appendingPathComponent("\(clothing.id.uuidString).json")

    do {
      let data = try encoder.encode(clothing)
      try data.write(to: fileURL)

      // IDリストを更新
      var clothingIds = loadClothingIdList()
      if !clothingIds.contains(clothing.id) {
        clothingIds.append(clothing.id)
        saveClothingIdList(clothingIds)
      }

      print("✅ 衣類データを保存: \(clothing.id)")
      return true
    } catch {
      print("❌ 衣類データ保存エラー: \(error)")
      return false
    }
  }

  /// 特定の衣類データを読み込む
  /// - Parameter id: 衣類ID
  /// - Returns: 読み込んだ衣類データ、失敗時はnil
  func loadClothing(id: UUID) -> Clothing? {
    let fileURL = clothingDirectory.appendingPathComponent("\(id.uuidString).json")

    guard fileManager.fileExists(atPath: fileURL.path) else {
      print("⚠️ 衣類ファイルが存在しません: \(id)")
      return nil
    }

    do {
      let data = try Data(contentsOf: fileURL)
      let clothing = try JSONDecoder().decode(Clothing.self, from: data)
      return clothing
    } catch {
      print("❌ 衣類データ読み込みエラー: \(error)")
      return nil
    }
  }

  /// すべての衣類データを読み込む
  /// - Returns: 衣類データの配列
  func loadAllClothing() -> [Clothing] {
    let clothingIds = loadClothingIdList()

    return clothingIds.compactMap { id in
      loadClothing(id: id)
    }
  }

  /// 衣類データを削除する
  /// - Parameter id: 削除する衣類のID
  /// - Returns: 削除が成功したかどうか
  func deleteClothing(id: UUID) -> Bool {
    let fileURL = clothingDirectory.appendingPathComponent("\(id.uuidString).json")

    // ファイルの存在確認
    guard fileManager.fileExists(atPath: fileURL.path) else {
      return false
    }

    do {
      // ファイルの削除
      try fileManager.removeItem(at: fileURL)

      // IDリストから削除
      var clothingIds = loadClothingIdList()
      clothingIds.removeAll { $0 == id }
      saveClothingIdList(clothingIds)

      // 関連する画像のメタデータを削除
      userDefaults.removeObject(forKey: "clothingImages_\(id.uuidString)")
      userDefaults.synchronize()

      print("✅ 衣類データを削除: \(id)")
      return true
    } catch {
      print("❌ 衣類データ削除エラー: \(error)")
      return false
    }
  }

  // MARK: - 衣類IDリスト管理

  /// 衣類IDリストを保存
  /// - Parameter ids: UUIDの配列
  private func saveClothingIdList(_ ids: [UUID]) {
    let idStrings = ids.map { $0.uuidString }
    userDefaults.set(idStrings, forKey: "clothing_id_list")
    userDefaults.synchronize()
  }

  /// 衣類IDリストを読み込む
  /// - Returns: UUIDの配列
  private func loadClothingIdList() -> [UUID] {
    guard let idStrings = userDefaults.stringArray(forKey: "clothing_id_list") else {
      return []
    }

    return idStrings.compactMap { UUID(uuidString: $0) }
  }

  /// 全ての画像メタデータを削除（キャッシュクリア用）
  func clearAllImageMetadata() {
    let defaults = userDefaults
    let allKeys = defaults.dictionaryRepresentation().keys

    for key in allKeys where key.starts(with: "clothingImages_") {
      defaults.removeObject(forKey: key)
    }
    defaults.synchronize()
    print("✅ すべての画像メタデータをクリア")
  }

  /// 全てのローカルデータをクリア
  func clearAllData() {
    // 画像メタデータをクリア
    clearAllImageMetadata()

    // 衣類IDリストをクリア
    saveClothingIdList([])

    // ファイルを削除
    for directory in [imagesDirectory, clothingDirectory] {
      do {
        let fileURLs = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        for fileURL in fileURLs {
          try fileManager.removeItem(at: fileURL)
        }
        print("✅ ディレクトリ内のファイルを削除: \(directory.path)")
      } catch {
        print("❌ ファイル削除エラー: \(error)")
      }
    }
  }
}
