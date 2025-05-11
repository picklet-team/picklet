// swiftlint:disable file_length
// swiftlint:disable type_body_length
// swiftlint:disable function_body_length
// swiftlint:disable cyclomatic_complexity
// swiftlint:disable line_length
import Foundation
import SwiftUI

@MainActor
class ClothingViewModel: ObservableObject {
  @Published var clothes: [Clothing] = []
  @Published var isLoading = false
  @Published var errorMessage: String?
  @Published var imageSetsMap: [UUID: [EditableImageSet]] = [:]

  // オフライン専用サービスを使用
  let localStorageService = LocalStorageService.shared
  let imageLoaderService = ImageLoaderService.shared
  let clothingService = ClothingService.shared

  // デバッグ用
  @Published var imageLoadStatus: [String: String] = [:]

  init(skipInitialLoad: Bool = false) {
    print("🧠 ClothingViewModel 初期化, skipInitialLoad: \(skipInitialLoad)")
    if !skipInitialLoad {
      loadClothings()
    }
  }

  // デバッグ情報を出力する関数
  func printDebugInfo() {
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
          print("    🆕 isNew: \(set.isNew)")
        }
      } else {
        print("  ⚠️ 関連画像セットなし")
      }
    }
  }

  /// ローカルストレージから全ての衣類を読み込む
  func loadClothings() {
    print("📂 ローカルストレージから衣類を読み込み開始")

    isLoading = true
    // ClothingServiceを使って全ての衣類を読み込む
    clothes = clothingService.fetchClothes()

    // 画像も読み込む
    Task {
      await loadAllImages()
      isLoading = false
    }

    print("✅ 衣類読み込み完了: \(clothes.count)件")
  }

  /// メインエントリーポイント - 服の保存（新規 or 更新）
  func saveClothing(_ clothing: Clothing, imageSets: [EditableImageSet], isNew: Bool) {
    print("📝 saveClothing 開始: ID=\(clothing.id), isNew=\(isNew)")

    isLoading = true

    // ステップ1: 衣類データを保存
    let success = if isNew {
      clothingService.addClothing(clothing)
    } else {
      clothingService.updateClothing(clothing)
    }

    if !success {
      errorMessage = "衣類データの保存に失敗しました"
      isLoading = false
      return
    }

    // ステップ2: ローカルストレージに画像を保存
    let localSavedSets = saveImagesToLocalStorage(clothing.id, imageSets: imageSets)

    // ステップ3: UIを更新
    updateLocalImagesCache(clothing.id, imageSets: localSavedSets)

    // ステップ4: UIの衣類リストを更新
    if isNew {
      if !clothes.contains(where: { $0.id == clothing.id }) {
        clothes.append(clothing)
      }
    } else {
      if let index = clothes.firstIndex(where: { $0.id == clothing.id }) {
        clothes[index] = clothing
      }
    }

    isLoading = false
    printDebugInfo()
  }

  /// 画像をローカルストレージに保存
  private func saveImagesToLocalStorage(_ clothingId: UUID, imageSets: [EditableImageSet]) -> [EditableImageSet] {
    print("💾 ローカルストレージへ画像を保存: clothingId=\(clothingId)")
    var updatedSets: [EditableImageSet] = []

    for var set in imageSets {
      // オリジナル画像を保存
      if set.original != UIImage(systemName: "photo") {
        if imageLoaderService.saveImage(set.original, for: clothingId, imageId: set.id) {
          print("✅ オリジナル画像をローカルに保存: \(set.id)")
          set.isNew = false
        }
      }

      // マスク画像があれば保存
      if let mask = set.mask {
        if let localPath = localStorageService.saveImage(mask, id: set.id, type: "mask") {
          print("✅ マスク画像をローカルに保存: \(localPath)")

          // メタデータを更新
          var metadata = localStorageService.loadImageMetadata(for: clothingId)
          if let index = metadata.firstIndex(where: { $0.id == set.id }) {
            metadata[index] = metadata[index].updatingLocalPath(maskLocalPath: localPath)
            localStorageService.saveImageMetadata(for: clothingId, imageMetadata: metadata)
          }
        }
      }

      // AIマスク画像があれば保存
      if let aimask = set.aimask {
        if let localPath = localStorageService.saveImage(aimask, id: set.id, type: "aimask") {
          print("✅ AIマスク画像をローカルに保存: \(localPath)")
        }
      }

      updatedSets.append(set)
    }

    return updatedSets
  }

  /// UIの即時更新のためにメモリ内の画像キャッシュを更新
  public func updateLocalImagesCache(_ clothingId: UUID, imageSets: [EditableImageSet]) {
    // 編集中の画像をすぐに表示できるようにキャッシュ
    imageSetsMap[clothingId] = imageSets
    print("✅ 即時表示用に画像キャッシュ更新: \(clothingId)")
  }

  /// 全ての服に関連する画像を読み込む
  func loadAllImages() async {
    print("🖼️ loadAllImages 開始")
    var newMap: [UUID: [EditableImageSet]] = [:]

    // プレースホルダー画像を作成
    let placeholderImage = UIImage(systemName: "photo") ?? UIImage()

    for clothing in clothes {
      // ローカルストレージからメタデータを取得
      let images = localStorageService.loadImageMetadata(for: clothing.id)
      print("📷 \(clothing.id)の画像メタデータを取得: \(images.count)件")

      // 画像セットを作成
      var imageSets: [EditableImageSet] = []

      for image in images {
        var original: UIImage = placeholderImage
        let aimask: UIImage? = nil
        var mask: UIImage?

        // オリジナル画像を読み込む
        if let originalPath = image.originalLocalPath {
          if let loadedImage = localStorageService.loadImage(from: originalPath) {
            original = loadedImage
            print("✅ ローカルからオリジナル画像を読み込み: \(originalPath)")
          }
        }

        // マスク画像を読み込む
        if let maskPath = image.maskLocalPath {
          if let loadedMask = localStorageService.loadImage(from: maskPath) {
            mask = loadedMask
            print("✅ ローカルからマスク画像を読み込み: \(maskPath)")
          }
        }

        // EditableImageSetを構築
        let set = EditableImageSet(
          id: image.id,
          original: original,
          aimask: aimask,
          mask: mask,
          isNew: false)

        imageSets.append(set)
      }

      newMap[clothing.id] = imageSets
    }

    imageSetsMap = newMap
    print("✅ 全画像読み込み完了: \(newMap.count)アイテム")
  }

  /// 服IDから画像を読み込むメソッド（ビュー層からの呼び出し用）
  func getImageForClothing(_ clothingId: UUID) -> UIImage? {
    // キャッシュから画像を取得
    if let imageSets = imageSetsMap[clothingId], let firstSet = imageSets.first {
      // すでにキャッシュされた画像がある場合はそれを返す
      if firstSet.original != UIImage(systemName: "photo") {
        return firstSet.original
      }
    }

    // キャッシュにない場合はローカルストレージから検索
    return imageLoaderService.loadFirstImageForClothing(clothingId)
  }

  /// 服を削除
  func deleteClothing(_ clothing: Clothing) {
    print("🗑️ deleteClothing 開始: ID=\(clothing.id)")

    // ClothingServiceを使って削除
    if clothingService.deleteClothing(clothing) {
      // UIから削除
      if let idx = clothes.firstIndex(where: { $0.id == clothing.id }) {
        clothes.remove(at: idx)
        print("✅ ローカル配列からアイテムを削除")
      }
      // 画像キャッシュからも削除
      imageSetsMap.removeValue(forKey: clothing.id)
      print("✅ imageSetsMapからエントリーを削除")
    } else {
      errorMessage = "衣類の削除に失敗しました"
    }
  }

  /// サーバーとローカルデータを同期する
  func syncIfNeeded() async {
    print("🔄 データ同期チェック")

    // 既にロード中の場合は何もしない
    if isLoading {
      return
    }

    isLoading = true

    // オンラインか確認し、必要に応じてサーバーからデータを取得
    // このサンプルでは簡単にローカルデータの再読み込みのみ実行
    loadClothings()

    // 画像も再読み込み
    await loadAllImages()

    print("✅ 同期完了")

    isLoading = false
  }
}
