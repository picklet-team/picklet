import SDWebImageSwiftUI
import SwiftUI

struct ClothingEditView: View {
  @EnvironmentObject private var viewModel: ClothingViewModel
  @Environment(\.dismiss) private var dismiss
  @Binding var clothing: Clothing
  let openPhotoPickerOnAppear: Bool
  let canDelete: Bool
  let isNew: Bool

  // editingSetsは直接表示に使うデータ（詳細画面と同じデータソースを使用）
  @State private var editingSets: [EditableImageSet] = []
  @State private var selectedImageSet: EditableImageSet?
  @State private var showPhotoPicker = false
  @State private var showImageEditor = false
  @State private var showDeleteConfirm = false
  @State private var isBackgroundLoading = false // バックグラウンド処理中フラグ

  var body: some View {
    VStack {
      ImageListSection(
        imageSets: $editingSets,
        addAction: { showPhotoPicker = true },
        selectAction: { set in
          // 画像編集前に確実に最新のデータを取得
          if !set.isNew {
            // マスク編集の前に、選択された画像を高品質バージョンに更新
            ensureHighQualityImage(for: set) { updatedSet in
              selectedImageSet = updatedSet
              showImageEditor = true
            }
          } else {
            // 新規の場合はそのまま設定
            selectedImageSet = set
            showImageEditor = true
          }
        },
        isLoading: isBackgroundLoading)

      ClothingFormSection(
        clothing: $clothing,
        canDelete: canDelete,
        onDelete: { showDeleteConfirm = true })

      Spacer()
    }
    .navigationTitle("服を編集")
    .safeAreaInset(edge: .bottom) {
      PrimaryActionButton(title: "保存") {
        saveChanges()
      }
    }
    .onAppear {
      // 初期表示時に詳細画面と同じデータソースを使用（ViewModelから直接）
      editingSets = viewModel.imageSetsMap[clothing.id] ?? []

      // 既存データかつ1枚以上画像がある場合のみ、バックグラウンドで高品質データを取得
      if !isNew && !editingSets.isEmpty {
        enhanceImagesInBackground()
      }

      if openPhotoPickerOnAppear {
        showPhotoPicker = true
      }
    }
    .sheet(isPresented: $showPhotoPicker) {
      CaptureOrLibraryView { image in
        let newSet = EditableImageSet(
          id: UUID(),
          original: image.normalized(),
          originalUrl: nil,
          mask: nil,
          maskUrl: nil,
          result: nil,
          resultUrl: nil,
          isNew: true)

        // 新規画像を追加
        editingSets.append(newSet)

        // ViewModelのキャッシュも同時に更新（詳細画面と整合性を保つ）
        viewModel.updateLocalImagesCache(clothing.id, imageSets: editingSets)
        print("📸 画像選択後にimageSetsMapを更新: \(clothing.id), 画像数: \(editingSets.count)")
      }
    }
    .sheet(item: $selectedImageSet) { imageSet in
      MaskEditorView(imageSet: bindingFor(imageSet))
        .onDisappear {
          // マスク編集後もViewModelのキャッシュを更新
          viewModel.updateLocalImagesCache(clothing.id, imageSets: editingSets)
          print("🎭 マスク編集後にimageSetsMapを更新: \(clothing.id)")
        }
    }
    .confirmationDialog("本当に削除しますか？", isPresented: $showDeleteConfirm) {
      Button("削除する", role: .destructive) {
        Task {
          await viewModel.deleteClothing(clothing)
          dismiss()
        }
      }
      Button("キャンセル", role: .cancel) {}
    }
  }

  // MARK: - バックグラウンド処理

  /// バックグラウンドで画像の高品質バージョンを取得
  private func enhanceImagesInBackground() {
    // バックグラウンド処理開始（低優先度）
    isBackgroundLoading = true

    Task(priority: .low) {
      print("🔄 バックグラウンドで高品質画像の準備開始: \(clothing.id)")

      // サーバーから最新データを取得（UI更新なしで裏で処理）
      let fetchedImages = try? await viewModel.imageMetadataService.fetchImages(for: clothing.id)
      guard let images = fetchedImages else {
        await MainActor.run { isBackgroundLoading = false }
        print("❌ 画像メタデータの取得に失敗")
        return
      }

      // ローカル処理（サーバー通信なし）で画像を拡張
      for image in images {
        let localStorageService = viewModel.localStorageService

        // 既存の画像があれば高品質版に更新、なければ追加
        if let idx = editingSets.firstIndex(where: { $0.id == image.id }) {
          let currentSet = editingSets[idx]

          // 画像サイズチェック - 低品質の場合のみローカルから読み込み
          if currentSet.original.size.width < 100 || currentSet.original.size.height < 100 {
            if let originalPath = image.originalLocalPath,
               let loadedImage = localStorageService.loadImage(from: originalPath) {
              // 高品質画像で更新（新しいインスタンスを作成）
              let updatedSet = EditableImageSet(
                id: currentSet.id,
                original: loadedImage,
                originalUrl: currentSet.originalUrl,
                mask: currentSet.mask,
                maskUrl: currentSet.maskUrl,
                result: currentSet.result,
                resultUrl: currentSet.resultUrl,
                isNew: currentSet.isNew)

              print("🔄 ローカルから高品質画像で更新: \(image.id)")

              // メインスレッドで更新（UIに影響するため）
              await MainActor.run {
                if let stillIdx = editingSets.firstIndex(where: { $0.id == image.id }) {
                  editingSets[stillIdx] = updatedSet
                }
              }
            }
          }
        }
      }

      // 画像セットの順序を維持しながら、確実に重複がないようにする
      await MainActor.run {
        // ViewModelのキャッシュを同期的に更新（detailViewとの整合性確保）
        viewModel.updateLocalImagesCache(clothing.id, imageSets: editingSets)
        isBackgroundLoading = false
        print("✅ バックグラウンド処理完了: 画像セット数=\(editingSets.count)")
      }
    }
  }

  /// 特定の画像を高品質バージョンに確実に更新（マスク編集前など）
  private func ensureHighQualityImage(for set: EditableImageSet, completion: @escaping (EditableImageSet) -> Void) {
    // すでに十分な品質があれば、そのままコールバック
    if set.original.size.width >= 100 && set.original.size.height >= 100 {
      print("✅ 既に十分な品質の画像があります: \(set.id)")
      completion(set)
      return
    }

    print("🔍 高品質画像を取得中: \(set.id)")

    // ローカルストレージから最高品質の画像を取得
    Task {
      let imageMetadataService = viewModel.imageMetadataService
      let localStorageService = viewModel.localStorageService

      // まずローカルストレージをチェック
      let images = try? await imageMetadataService.fetchImages(for: clothing.id)
      if let image = images?.first(where: { $0.id == set.id }),
         let originalPath = image.originalLocalPath,
         let loadedImage = localStorageService.loadImage(from: originalPath) {
        // ローカルに高品質画像がある場合は新しいインスタンスを作成
        let updatedSet = EditableImageSet(
          id: set.id,
          original: loadedImage,
          originalUrl: set.originalUrl,
          mask: set.mask,
          maskUrl: set.maskUrl,
          result: set.result,
          resultUrl: set.resultUrl,
          isNew: set.isNew)

        print("📲 ローカルから高品質画像を取得: \(originalPath)")

        // 配列も更新
        if let idx = editingSets.firstIndex(where: { $0.id == set.id }) {
          await MainActor.run {
            editingSets[idx] = updatedSet
          }
        }

        await MainActor.run {
          completion(updatedSet)
        }
        return
      }

      // ローカルになければSDWebImageを使ってネットワークから取得
      if let urlString = set.originalUrl, let url = URL(string: urlString) {
        // ネットワーク取得はメインスレッドをブロックしない
        let options: SDWebImageOptions = [.highPriority, .retryFailed, .refreshCached]

        SDWebImageManager.shared.loadImage(
          with: url,
          options: options,
          progress: nil) { image, _, _, _, _, _ in
            if let downloadedImage = image {
              print("🌐 URLから高品質画像を取得: \(urlString)")

              // 新しいインスタンスを作成
              let updatedSet = EditableImageSet(
                id: set.id,
                original: downloadedImage,
                originalUrl: set.originalUrl,
                mask: set.mask,
                maskUrl: set.maskUrl,
                result: set.result,
                resultUrl: set.resultUrl,
                isNew: set.isNew)

              // ローカルに保存して次回以降の高速アクセス用にキャッシュ
              if let savedPath = localStorageService.saveImage(downloadedImage, id: set.id, type: "original") {
                print("💾 高品質画像をローカルに保存: \(savedPath)")
              }

              // 配列も更新
              if let idx = self.editingSets.firstIndex(where: { $0.id == set.id }) {
                DispatchQueue.main.async {
                  self.editingSets[idx] = updatedSet
                }
              }

              completion(updatedSet)
            } else {
              // 失敗したら元の画像を使用
              print("⚠️ 高品質画像の取得失敗。元の画像を使用: \(set.id)")
              completion(set)
            }
          }
      } else {
        // URLがない場合は現状の画像を使う
        await MainActor.run {
          completion(set)
        }
      }
    }
  }

  private func saveChanges() {
    Task {
      await viewModel.saveClothing(
        clothing,
        imageSets: editingSets,
        isNew: isNew)
      dismiss()
    }
  }

  private func bindingFor(_ set: EditableImageSet) -> Binding<EditableImageSet> {
    guard let idx = editingSets.firstIndex(where: { $0.id == set.id }) else {
      fatalError("Invalid imageSet")
    }
    return $editingSets[idx]
  }
}

// MARK: - Subviews

private struct ImageListSection: View {
  @Binding var imageSets: [EditableImageSet]
  let addAction: () -> Void
  let selectAction: (EditableImageSet) -> Void
  let isLoading: Bool

  var body: some View {
    VStack(alignment: .leading) {
      // バックグラウンド処理中の表示
      if isLoading {
        HStack {
          Spacer()
          Text("高品質データを準備中...")
            .font(.caption)
            .foregroundColor(.secondary)
          ProgressView()
            .scaleEffect(0.7)
          Spacer()
        }
        .padding(.vertical, 4)
      }

      // バインディング対応の共通コンポーネントを使用
      ClothingImageGalleryView(
        imageSets: $imageSets,
        showAddButton: true,
        onSelectImage: selectAction,
        onAddButtonTap: addAction)
    }
  }
}

private struct ClothingFormSection: View {
  @Binding var clothing: Clothing
  let canDelete: Bool
  let onDelete: () -> Void

  var body: some View {
    Form {
      Section(header: Text("服の情報")) {
        TextField("名前", text: $clothing.name)
        TextField("カテゴリ", text: $clothing.category)
        TextField("色", text: $clothing.color)
      }

      if canDelete {
        Section {
          Button(action: onDelete) {
            Text("削除")
              .font(.callout) // footnoteからcalloutに変更してサイズアップ
              .foregroundColor(.red.opacity(0.8))
          }
          .frame(maxWidth: .infinity, alignment: .center)
          .listRowBackground(Color.clear)
        }
        .textCase(nil)
      }
    }
  }
}
