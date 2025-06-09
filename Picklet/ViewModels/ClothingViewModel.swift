import Foundation
import SwiftUI

@MainActor
class ClothingViewModel: ObservableObject {
  @Published var clothes: [Clothing] = []
  @Published var wearHistories: [WearHistory] = []
  @Published var isLoading = false
  @Published var errorMessage: String?
  @Published var imageSetsMap: [UUID: [EditableImageSet]] = [:]

  // Services
  let dataManager = SQLiteManager.shared
  let imageLoaderService = ImageLoaderService.shared
  let clothingService = ClothingService.shared

  // デバッグ用
  @Published var imageLoadStatus: [String: String] = [:]

  init(skipInitialLoad: Bool = false) {
    print("🧠 ClothingViewModel 初期化, skipInitialLoad: \(skipInitialLoad)")
    if !skipInitialLoad {
      loadClothings()
      loadWearHistories()
    }
  }

  // デバッグ情報を出力する関数
  func printDebugInfo() {
    print("🔍 ClothingViewModel デバッグ情報:")
    print("🧵 clothes 数: \(clothes.count)")
    print("🖼️ imageSetsMap エントリー数: \(imageSetsMap.count)")

    // 各服の情報をデバッグ
    for clothing in clothes {
      let imageSets = imageSetsMap[clothing.id] ?? []
      print("  - \(clothing.name): \(imageSets.count) 画像セット")
    }
  }

  /// ローカルストレージから全ての衣類を読み込む
  func loadClothings() {
    print("📂 ローカルストレージから衣類を読み込み開始")

    isLoading = true
    clothes = clothingService.fetchClothes()

    Task {
      await loadAllImages()
      isLoading = false
    }

    print("✅ 衣類読み込み完了: \(clothes.count)件")
  }

  /// 服を削除
  func deleteClothing(_ clothing: Clothing) {
    print("🗑️ deleteClothing 開始: ID=\(clothing.id)")

    if clothingService.deleteClothing(clothing) {
      if let idx = clothes.firstIndex(where: { $0.id == clothing.id }) {
        clothes.remove(at: idx)
        print("✅ ローカル配列からアイテムを削除")
      }
      imageSetsMap.removeValue(forKey: clothing.id)
      print("✅ imageSetsMapからエントリーを削除")
    } else {
      errorMessage = "衣類の削除に失敗しました"
    }
  }

  /// サーバーとローカルデータを同期する
  func syncIfNeeded() async {
    print("🔄 データ同期チェック")

    if isLoading {
      return
    }

    isLoading = true
    loadClothings()
    await loadAllImages()
    print("✅ 同期完了")
    isLoading = false
  }
}
