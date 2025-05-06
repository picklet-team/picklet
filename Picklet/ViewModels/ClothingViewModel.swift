import Foundation
import SwiftUI

@MainActor
class ClothingViewModel: ObservableObject {
  @Published var clothes: [Clothing] = []
  @Published var isLoading = false
  @Published var errorMessage: String?

  @Published var imageSetsMap: [UUID: [EditableImageSet]] = [:]

  private let clothingService = SupabaseService.shared
  private let imageMetadataService = ImageMetadataService.shared
//  private let imageStorageService = ImageStorageService.shared
  private let originalImageStorageService = ImageStorageService(bucketName: "originals")
  private let maskImageStorageService = ImageStorageService(bucketName: "masks")
  private let localStorageService = LocalStorageService.shared

  init() {
    print("🧠 ClothingViewModel 初期化")
    Task {
      await printDebugInfo()
    }
  }

  // デバッグ情報を出力する関数
  func printDebugInfo() async {
    print("🔍 ClothingViewModel デバッグ情報:")
    print("🧵 clothes 数: \(clothes.count)")
    print("🖼️ imageSetsMap エントリー数: \(imageSetsMap.count)")

    // 各服の情報をデバッグ
    for clothing in clothes {
      print("👕 服ID: \(clothing.id), 名前: \(clothing.name)")

      // 服に関連する画像セットを表示
      if let imageSets = imageSetsMap[clothing.id] {
        print("  📸 関連画像セット数: \(imageSets.count)")
        for (index, set) in imageSets.enumerated() {
          print("  📷 セット[\(index)]: ID=\(set.id)")
          print("    🔗 originalUrl: \(set.originalUrl ?? "nil")")
          print("    🔗 maskUrl: \(set.maskUrl ?? "nil")")
          print("    🆕 isNew: \(set.isNew)")
        }
      } else {
        print("  ⚠️ 関連画像セットなし")
      }
    }
  }

  /// 服を保存（新規 or 更新）
  func updateClothing(_ clothing: Clothing, imageSets: [EditableImageSet], isNew: Bool) async {
    print("📝 updateClothing 開始: ID=\(clothing.id), isNew=\(isNew)")
    do {
      // 1. 服情報を保存
      try await saveClothingData(clothing, isNew: isNew)

      // 2. 画像セットを処理
      for idx in imageSets.indices {
        var set = imageSets[idx]

        // 3. オリジナル画像の処理
        if set.isNew, set.originalUrl == nil {
          await processOriginalImage(set: &set, clothing: clothing)
        }

        // 4. マスク画像の処理
        if let mask = set.mask, set.maskUrl == nil {
          await processMaskImage(mask: mask, set: &set, clothing: clothing)
        }
      }

      // 更新後のデバッグ情報を表示
      await printDebugInfo()
    } catch {
      print("❌ updateClothing エラー: \(error.localizedDescription)")
      errorMessage = error.localizedDescription
    }
  }

  /// 服データを保存（新規作成または更新）
  private func saveClothingData(_ clothing: Clothing, isNew: Bool) async throws {
    if isNew {
      try await clothingService.addClothing(clothing)
      print("✅ 新規服を追加しました: \(clothing.id)")
    } else {
      try await clothingService.updateClothing(clothing)
      print("✅ 既存服を更新しました: \(clothing.id)")
    }
  }

  /// オリジナル画像を処理・アップロード
  private func processOriginalImage(set: inout EditableImageSet, clothing: Clothing) async {
    let originalImage = set.original
    print("🔄 新規画像をアップロード中: setID=\(set.id)")

    // ローカルに画像を保存
    guard let localPath = localStorageService.saveImage(originalImage, id: set.id, type: "original") else {
      print("❌ ローカル画像保存失敗")
      return
    }

    print("✅ 画像をローカルに保存: \(localPath)")

    do {
      // サーバーにアップロード
      let url = try await originalImageStorageService.uploadImage(originalImage, for: set.id.uuidString)

      // メタデータを追加（ローカルパス情報も含む）
      let newImage = ClothingImage(
        id: set.id,
        clothingId: clothing.id,
        originalUrl: url,
        originalLocalPath: localPath,
        createdAt: Date(),
        updatedAt: Date())

      // ローカルメタデータを更新
      var localImages = localStorageService.loadImageMetadata(for: clothing.id)
      localImages.append(newImage)
      localStorageService.saveImageMetadata(for: clothing.id, imageMetadata: localImages)

      // サーバーメタデータを更新
      try await imageMetadataService.addImage(for: clothing.id, originalUrl: url)

      // EditableImageSetは可変なのでプロパティを更新
      set.originalUrl = url
      set.isNew = false
      print("✅ 画像アップロード完了: URL=\(url)")
    } catch {
      print("❌ 画像アップロードエラー: \(error.localizedDescription)")
    }
  }

  /// マスク画像を処理・アップロード
  private func processMaskImage(mask: UIImage, set: inout EditableImageSet, clothing: Clothing) async {
    print("🔄 マスク画像をアップロード中: setID=\(set.id)")

    // ローカルにマスク画像を保存
    guard let localPath = localStorageService.saveImage(mask, id: set.id, type: "mask") else {
      print("❌ ローカルマスク保存失敗")
      return
    }

    print("✅ マスク画像をローカルに保存: \(localPath)")

    do {
      // サーバーにアップロード
      let maskUrl = try await maskImageStorageService.uploadImage(mask, for: set.id.uuidString)

      // ローカルメタデータを更新
      var localImages = localStorageService.loadImageMetadata(for: clothing.id)
      if let index = localImages.firstIndex(where: { $0.id == set.id }) {
        // ClothingImageはlet定数を持つので新しいインスタンスを作成して置き換え
        let oldImage = localImages[index]
        let updatedImage = ClothingImage(
          id: oldImage.id,
          clothingId: oldImage.clothingId,
          userId: oldImage.userId,
          originalUrl: oldImage.originalUrl,
          maskUrl: maskUrl, // 更新されたマスクURL
          resultUrl: oldImage.resultUrl,
          originalLocalPath: oldImage.originalLocalPath,
          maskLocalPath: localPath, // 新しいローカルパス
          resultLocalPath: oldImage.resultLocalPath,
          createdAt: oldImage.createdAt,
          updatedAt: Date())
        localImages[index] = updatedImage
        localStorageService.saveImageMetadata(for: clothing.id, imageMetadata: localImages)
      }

      // サーバーメタデータを更新
      try await imageMetadataService.updateImageMask(imageId: set.id, maskUrl: maskUrl)

      // EditableImageSetは可変なのでプロパティを更新
      set.maskUrl = maskUrl
      print("✅ マスクアップロード完了: URL=\(maskUrl)")
    } catch {
      print("❌ マスクアップロードエラー: \(error.localizedDescription)")
    }
  }

  /// 起動時 or 手動で呼び出す「差分だけ同期」メソッド
  func syncIfNeeded() async {
    print("🔄 syncIfNeeded 開始")
    do {
      // 1) サーバーから最新リストを取得
      let remote = try await clothingService.fetchClothes()
      print("📥 サーバーから受信: \(remote.count)件")

      // 2) 差分検出＆マージ
      var merged = clothes // 現在のローカル配列をコピー
      for item in remote {
        if let idx = merged.firstIndex(where: { $0.id == item.id }) {
          // ローカルの方が古ければ置き換え
          if merged[idx].updatedAt < item.updatedAt {
            merged[idx] = item
            print("🔄 アイテム更新: \(item.id)")
          }
        } else {
          // ローカルにない新規は追加
          merged.append(item)
          print("➕ 新規アイテム追加: \(item.id)")
        }
      }
      // 3) ローカルにしかないサーバー削除済アイテムは optional で後処理してもOK
      clothes = merged
      print("✅ 同期完了: 最終件数=\(merged.count)")

      // 同期後に画像のロードも行う
      await loadAllImages()
    } catch {
      print("❌ syncIfNeeded エラー: \(error.localizedDescription)")
      errorMessage = error.localizedDescription
    }
  }

  /// 全ての服に関連する画像メタデータを読み込む
  func loadAllImages() async {
    print("🖼️ loadAllImages 開始")
    var newMap: [UUID: [EditableImageSet]] = [:]

    // プレースホルダー画像を作成
    let placeholderImage = UIImage(systemName: "photo") ?? UIImage()

    for clothing in clothes {
      do {
        // ImageMetadataServiceの更新版fetchImagesを使用（オフラインファーストアプローチ）
        let images = try await imageMetadataService.fetchImages(for: clothing.id)
        print("📷 \(clothing.id)の画像を取得: \(images.count)件")

        let imageSets = images.map { image -> EditableImageSet in
          var original: UIImage = placeholderImage
          var mask: UIImage? // nilの明示的初期化を削除

          // ローカルパスから画像を読み込む
          if let originalPath = image.originalLocalPath {
            if let loadedImage = localStorageService.loadImage(from: originalPath) {
              original = loadedImage
              print("📲 ローカルから画像を読み込み: \(originalPath)")
            }
          }

          if let maskPath = image.maskLocalPath {
            if let loadedMask = localStorageService.loadImage(from: maskPath) {
              mask = loadedMask
              print("📲 ローカルからマスク画像を読み込み: \(maskPath)")
            }
          }

          // EditableImageSetを構築
          let set = EditableImageSet(
            id: image.id,
            original: original,
            originalUrl: image.originalUrl,
            mask: mask,
            maskUrl: image.maskUrl,
            isNew: false)

          print("  🔗 画像セット: ID=\(set.id), originalUrl=\(image.originalUrl ?? "nil"), maskUrl=\(image.maskUrl ?? "nil")")
          return set
        }

        newMap[clothing.id] = imageSets
      } catch {
        print("❌ \(clothing.id)の画像読み込みエラー: \(error.localizedDescription)")
      }
    }

    imageSetsMap = newMap
    print("✅ 全画像読み込み完了: \(newMap.count)アイテム")
  }

  /// 服を削除
  func deleteClothing(_ clothing: Clothing) async {
    print("🗑️ deleteClothing 開始: ID=\(clothing.id)")
    do {
      try await clothingService.deleteClothing(clothing)
      // １）ローカル配列から該当アイテムを取り除く
      if let idx = clothes.firstIndex(where: { $0.id == clothing.id }) {
        clothes.remove(at: idx)
        print("✅ ローカル配列からアイテムを削除")
      }
      // ２）マップからも削除
      imageSetsMap.removeValue(forKey: clothing.id)
      print("✅ imageSetsMapからエントリーを削除")
    } catch {
      print("❌ deleteClothing エラー: \(error.localizedDescription)")
      errorMessage = error.localizedDescription
    }
  }
}
