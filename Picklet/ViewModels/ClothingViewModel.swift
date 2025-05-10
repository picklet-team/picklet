// swiftlint:disable file_length
// swiftlint:disable type_body_length
// swiftlint:disable function_body_length
// swiftlint:disable cyclomatic_complexity
// swiftlint:disable line_length
import Foundation
import SDWebImageSwiftUI
import SwiftUI

@MainActor
class ClothingViewModel: ObservableObject {
  @Published var clothes: [Clothing] = []
  @Published var isLoading = false
  @Published var errorMessage: String?

  @Published var imageSetsMap: [UUID: [EditableImageSet]] = [:]

  // 外部からアクセスできるようにprivateを削除
  let clothingService = SupabaseService.shared
  let imageMetadataService = ImageMetadataService.shared
  let originalImageStorageService = ImageStorageService(bucketName: "originals")
  let maskImageStorageService = ImageStorageService(bucketName: "masks")
  let localStorageService = LocalStorageService.shared

  // デバッグ用
  @Published var imageLoadStatus: [String: String] = [:]

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

  /// ------------------------------------------------------------
  /// 服管理の主要フロー
  /// ------------------------------------------------------------

  /// メインエントリーポイント - 服の保存（新規 or 更新）
  func saveClothing(_ clothing: Clothing, imageSets: [EditableImageSet], isNew: Bool) async {
    print("📝 saveClothing 開始: ID=\(clothing.id), isNew=\(isNew)")
    do {
      isLoading = true

      // ステップ1: 服データをデータベースに保存
      try await saveClothingToDatabase(clothing, isNew: isNew)

      // ステップ2: UIの即時更新用に画像をメモリにキャッシュ
      updateLocalImagesCache(clothing.id, imageSets: imageSets)

      // ステップ3: バックグラウンドでの画像処理を開始（戻り値の配列は処理済みのセット）
      let processedSets = await processAllImages(clothing, imageSets: imageSets)

      // ステップ4: 処理後の最終画像を更新
      updateProcessedImages(clothing.id, imageSets: processedSets)

      isLoading = false
      await printDebugInfo()
    } catch {
      print("❌ saveClothing エラー: \(error.localizedDescription)")
      errorMessage = error.localizedDescription
      isLoading = false
    }
  }

  /// ステップ1: 服データをDBに保存し、必要ならローカルリストも更新
  private func saveClothingToDatabase(_ clothing: Clothing, isNew: Bool) async throws {
    if isNew {
      try await clothingService.addClothing(clothing)
      print("✅ 新規服を追加しました: \(clothing.id)")

      // 新規の場合はUIの配列にも追加
      if !clothes.contains(where: { $0.id == clothing.id }) {
        clothes.append(clothing)
        print("✅ UIに新規服を追加しました: \(clothing.id)")
      }
    } else {
      try await clothingService.updateClothing(clothing)
      // 既存の場合は必要ならローカルも更新
      if let index = clothes.firstIndex(where: { $0.id == clothing.id }) {
        clothes[index] = clothing
      }
      print("✅ 既存服を更新しました: \(clothing.id)")
    }
  }

  /// ステップ2: UIの即時更新のためにメモリ内の画像キャッシュを更新
  public func updateLocalImagesCache(_ clothingId: UUID, imageSets: [EditableImageSet]) {
    // 編集中の画像をすぐに表示できるようにキャッシュ
    imageSetsMap[clothingId] = imageSets
    print("✅ 即時表示用に画像キャッシュ更新: \(clothingId)")
  }

  /// ステップ3: すべての画像を処理（アップロード）
  private func processAllImages(_ clothing: Clothing, imageSets: [EditableImageSet]) async -> [EditableImageSet] {
    print("🔄 画像処理を開始: \(clothing.id)")
    var processedSets: [EditableImageSet] = []

    for var set in imageSets {
      // 新規オリジナル画像の処理
      if set.original != UIImage(systemName: "photo") && (set.isNew || set.originalUrl == nil) {
        await processOriginalImage(set: &set, clothing: clothing)
      }

      // AIマスク画像の処理
      if let aimask = set.aimask, set.aimaskUrl == nil {
        await processAIMaskImage(aimask: aimask, set: &set, clothing: clothing)
      }

      // マスク画像の処理
      if let mask = set.mask, set.maskUrl == nil {
        await processMaskImage(mask: mask, set: &set, clothing: clothing)
      }

      processedSets.append(set)
    }

    print("✅ 画像処理完了: \(clothing.id)")
    return processedSets
  }

  /// ステップ4: 処理後の最終画像を更新
  private func updateProcessedImages(_ clothingId: UUID, imageSets: [EditableImageSet]) {
    imageSetsMap[clothingId] = imageSets
    print("✅ 処理済み最終画像を更新: \(clothingId)")
  }

  /// ------------------------------------------------------------
  /// 画像処理の詳細実装
  /// ------------------------------------------------------------

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

      // 現在のユーザーIDを取得
      guard let user = AuthService.shared.currentUser else {
        print("❌ ユーザーが取得できません")
        return
      }

      // ユーザーIDを取得
      let userId = user.id

      // メタデータを追加（ローカルパス情報も含む）
      let newImage = ClothingImage(
        id: set.id,
        clothingId: clothing.id,
        userId: userId,
        originalUrl: url,
        aimaskUrl: nil,
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
          aimaskUrl: oldImage.aimaskUrl,
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

  /// AIマスク画像を処理・アップロード
  private func processAIMaskImage(aimask: UIImage, set: inout EditableImageSet, clothing: Clothing) async {
    print("🔄 AIマスク画像をアップロード中: setID=\(set.id)")

    // ローカルにAIマスク画像を保存
    guard let localPath = localStorageService.saveImage(aimask, id: set.id, type: "aimask") else {
      print("❌ ローカルAIマスク保存失敗")
      return
    }

    print("✅ AIマスク画像をローカルに保存: \(localPath)")

    do {
      // サーバーにアップロード (AIマスク専用バケットを追加する必要があるかもしれません)
      let aimaskUrl = try await maskImageStorageService.uploadImage(aimask, for: "\(set.id.uuidString)-ai")

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
          aimaskUrl: aimaskUrl, // 新しいAIマスクURL
          maskUrl: oldImage.maskUrl,
          resultUrl: oldImage.resultUrl,
          originalLocalPath: oldImage.originalLocalPath,
          // AIマスク用のローカルパスはまだモデルに定義されていません。必要に応じて追加してください
          maskLocalPath: oldImage.maskLocalPath,
          resultLocalPath: oldImage.resultLocalPath,
          createdAt: oldImage.createdAt,
          updatedAt: Date())
        localImages[index] = updatedImage
        localStorageService.saveImageMetadata(for: clothing.id, imageMetadata: localImages)
      }

      // サーバーメタデータを更新
      try await imageMetadataService.updateImageAIMask(imageId: set.id, aimaskUrl: aimaskUrl)

      // EditableImageSetは可変なのでプロパティを更新
      set.aimaskUrl = aimaskUrl
      set.aimask = aimask
      print("✅ AIマスクアップロード完了: URL=\(aimaskUrl)")
    } catch {
      print("❌ AIマスクアップロードエラー: \(error.localizedDescription)")
    }
  }

  /// ------------------------------------------------------------
  /// データ同期・画像読み込み
  /// ------------------------------------------------------------
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

        // 画像セットを非同期で作成
        var imageSets: [EditableImageSet] = []

        for image in images {
          var original: UIImage = placeholderImage
          var aimask: UIImage?
          var mask: UIImage?

          // ローカルパスから画像を読み込む
          if let originalPath = image.originalLocalPath {
            if let loadedImage = localStorageService.loadImage(from: originalPath) {
              original = loadedImage
              print("📲 ローカルから画像を読み込み: \(originalPath)")
            } else if let originalUrl = image.originalUrl, let url = URL(string: originalUrl) {
              // 非同期でURLから画像をダウンロード
              do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let downloadedImage = UIImage(data: data) {
                  original = downloadedImage
                  print("🌐 URLから画像を非同期にダウンロード: \(originalUrl)")

                  // ローカルに保存して次回利用できるようにする
                  if let savedPath = localStorageService.saveImage(downloadedImage, id: image.id, type: "original") {
                    print("💾 ダウンロードした画像をローカルに保存: \(savedPath)")
                  }
                }
              } catch {
                print("❌ 画像ダウンロードエラー: \(originalUrl) - \(error.localizedDescription)")
              }
            }
          }

          // AIマスク画像の読み込み（後でローカルパスを追加する必要があります）
          if let aimaskUrl = image.aimaskUrl, let url = URL(string: aimaskUrl) {
            do {
              let (data, _) = try await URLSession.shared.data(from: url)
              if let downloadedAIMask = UIImage(data: data) {
                aimask = downloadedAIMask
                print("🌐 URLからAIマスク画像を非同期にダウンロード: \(aimaskUrl)")

                // ローカルに保存して次回利用できるようにする（将来的に必要になるでしょう）
                if let savedPath = localStorageService.saveImage(downloadedAIMask, id: image.id, type: "aimask") {
                  print("💾 ダウンロードしたAIマスク画像をローカルに保存: \(savedPath)")
                }
              }
            } catch {
              print("❌ AIマスク画像ダウンロードエラー: \(aimaskUrl) - \(error.localizedDescription)")
            }
          }

          if let maskPath = image.maskLocalPath {
            if let loadedMask = localStorageService.loadImage(from: maskPath) {
              mask = loadedMask
              print("📲 ローカルからマスク画像を読み込み: \(maskPath)")
            } else if let maskUrl = image.maskUrl, let url = URL(string: maskUrl) {
              // 非同期でURLからマスク画像をダウンロード
              do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let downloadedMask = UIImage(data: data) {
                  mask = downloadedMask
                  print("🌐 URLからマスク画像を非同期にダウンロード: \(maskUrl)")

                  // ローカルに保存して次回利用できるようにする
                  if let savedPath = localStorageService.saveImage(downloadedMask, id: image.id, type: "mask") {
                    print("💾 ダウンロードしたマスク画像をローカルに保存: \(savedPath)")
                  }
                }
              } catch {
                print("❌ マスク画像ダウンロードエラー: \(maskUrl) - \(error.localizedDescription)")
              }
            }
          }

          // EditableImageSetを構築
          let set = EditableImageSet(
            id: image.id,
            original: original,
            originalUrl: image.originalUrl,
            aimask: aimask,
            aimaskUrl: image.aimaskUrl,
            mask: mask,
            maskUrl: image.maskUrl,
            isNew: false)

          imageSets.append(set)
          print(
            "  🔗 画像セット: ID=\(image.id), " +
              "originalUrl=\(image.originalUrl ?? "nil"), " +
              "aimaskUrl=\(image.aimaskUrl ?? "nil"), " +
              "maskUrl=\(image.maskUrl ?? "nil")")
        }

        newMap[clothing.id] = imageSets
      } catch {
        print("❌ \(clothing.id)の画像読み込みエラー: \(error.localizedDescription)")
      }
    }

    imageSetsMap = newMap
    print("✅ 全画像読み込み完了: \(newMap.count)アイテム")
  }

  /// 指定したIDの服の画像のみを読み込む（個別更新用）
  func loadImagesForClothing(id: UUID) async {
    print("🖼️ 指定服の画像読み込み開始: \(id)")

    // プレースホルダー画像を作成
    let placeholderImage = UIImage(systemName: "photo") ?? UIImage()

    do {
      let images = try await imageMetadataService.fetchImages(for: id)
      print("📷 \(id)の画像を取得: \(images.count)件")

      var imageSets: [EditableImageSet] = []

      for image in images {
        var original: UIImage = placeholderImage
        var aimask: UIImage?
        var mask: UIImage?

        // ローカルパスから画像を読み込む
        if let originalPath = image.originalLocalPath {
          if let loadedImage = localStorageService.loadImage(from: originalPath) {
            original = loadedImage
            print("📲 ローカルから画像を読み込み: \(originalPath)")
          } else if let originalUrl = image.originalUrl, let url = URL(string: originalUrl) {
            // 非同期でURLから画像をダウンロード
            do {
              let (data, _) = try await URLSession.shared.data(from: url)
              if let downloadedImage = UIImage(data: data) {
                original = downloadedImage
                print("🌐 URLから画像を非同期にダウンロード: \(originalUrl)")

                // ローカルに保存して次回利用できるようにする
                if let savedPath = localStorageService.saveImage(downloadedImage, id: image.id, type: "original") {
                  print("💾 ダウンロードした画像をローカルに保存: \(savedPath)")
                }
              }
            } catch {
              print("❌ 画像ダウンロードエラー: \(originalUrl) - \(error.localizedDescription)")
            }
          }
        }

        // AIマスク画像の読み込み
        if let aimaskUrl = image.aimaskUrl, let url = URL(string: aimaskUrl) {
          do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let downloadedAIMask = UIImage(data: data) {
              aimask = downloadedAIMask
              print("🌐 URLからAIマスク画像を非同期にダウンロード: \(aimaskUrl)")

              // ローカルに保存して次回利用できるようにする
              if let savedPath = localStorageService.saveImage(downloadedAIMask, id: image.id, type: "aimask") {
                print("💾 ダウンロードしたAIマスク画像をローカルに保存: \(savedPath)")
              }
            }
          } catch {
            print("❌ AIマスク画像ダウンロードエラー: \(aimaskUrl) - \(error.localizedDescription)")
          }
        }

        if let maskPath = image.maskLocalPath {
          if let loadedMask = localStorageService.loadImage(from: maskPath) {
            mask = loadedMask
            print("📲 ローカルからマスク画像を読み込み: \(maskPath)")
          } else if let maskUrl = image.maskUrl, let url = URL(string: maskUrl) {
            // 非同期でURLからマスク画像をダウンロード
            do {
              let (data, _) = try await URLSession.shared.data(from: url)
              if let downloadedMask = UIImage(data: data) {
                mask = downloadedMask
                print("🌐 URLからマスク画像を非同期にダウンロード: \(maskUrl)")

                // ローカルに保存して次回利用できるようにする
                if let savedPath = localStorageService.saveImage(downloadedMask, id: image.id, type: "mask") {
                  print("💾 ダウンロードしたマスク画像をローカルに保存: \(savedPath)")
                }
              }
            } catch {
              print("❌ マスク画像ダウンロードエラー: \(maskUrl) - \(error.localizedDescription)")
            }
          }
        }

        // EditableImageSetを構築
        let set = EditableImageSet(
          id: image.id,
          original: original,
          originalUrl: image.originalUrl,
          aimask: aimask,
          aimaskUrl: image.aimaskUrl,
          mask: mask,
          maskUrl: image.maskUrl,
          isNew: false)

        imageSets.append(set)
        print(
          "  🔗 画像セット: ID=\(image.id), " +
            "originalUrl=\(image.originalUrl ?? "nil"), " +
            "aimaskUrl=\(image.aimaskUrl ?? "nil"), " +
            "maskUrl=\(image.maskUrl ?? "nil")")
      }

      // 既存のマップを更新
      imageSetsMap[id] = imageSets
      print("✅ 指定服の画像読み込み完了: \(id)")
    } catch {
      print("❌ 指定服の画像読み込みエラー: \(error.localizedDescription)")
    }
  }

  /// ------------------------------------------------------------
  /// 画像読み込みAPI
  /// ------------------------------------------------------------

  /// 服IDから画像を読み込むメソッド（ビュー層からの呼び出し用）
  /// - Parameter clothingId: 服のID
  /// - Returns: 読み込んだ画像（成功した場合）
  func getImageForClothing(_ clothingId: UUID) async -> UIImage? {
    // キャッシュから画像を取得
    if let imageSets = imageSetsMap[clothingId], let firstSet = imageSets.first {
      // すでにキャッシュされた画像がある場合はそれを返す
      if firstSet.original != UIImage(systemName: "photo") {
        print("✅ ViewModelのキャッシュから画像を取得: \(clothingId)")
        return firstSet.original
      }
    }

    // キャッシュにない場合はローカルストレージから検索
    let imageLoaderService = ImageLoaderService.shared
    let localStorageService = LocalStorageService.shared
    let metadata = localStorageService.loadImageMetadata(for: clothingId)

    if let firstImage = metadata.first,
       let localPath = firstImage.originalLocalPath,
       let image = localStorageService.loadImage(from: localPath) {
      print("✅ ローカルストレージから画像を読み込み: \(localPath)")
      return image
    }

    // ローカルにもない場合は非同期でネットワークから取得
    if let firstImage = metadata.first, let originalUrl = firstImage.originalUrl {
      let image = await imageLoaderService.loadFromURL(originalUrl)

      // ダウンロードした画像をローカルに保存
      if let image = image, let savedPath = localStorageService.saveImage(image, id: firstImage.id, type: "original") {
        print("💾 ダウンロードした画像をローカルに保存: \(savedPath)")

        // メタデータを更新
        var updatedMetadata = metadata
        if let index = updatedMetadata.firstIndex(where: { $0.id == firstImage.id }) {
          updatedMetadata[index] = firstImage.updatingLocalPath(originalLocalPath: savedPath)
          localStorageService.saveImageMetadata(for: clothingId, imageMetadata: updatedMetadata)
        }
      }

      return image
    }

    print("⚠️ 画像が見つかりませんでした: \(clothingId)")
    return nil
  }

  /// ------------------------------------------------------------
  /// 削除処理
  /// ------------------------------------------------------------

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
