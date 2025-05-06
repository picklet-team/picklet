import SDWebImageSwiftUI
import SwiftUI

struct ClothingEditView: View {
  @EnvironmentObject private var viewModel: ClothingViewModel
  @Environment(\.dismiss) private var dismiss
  @Binding var clothing: Clothing
  let openPhotoPickerOnAppear: Bool
  let canDelete: Bool
  let isNew: Bool

  @State private var editingSets: [EditableImageSet] = []
  @State private var selectedImageSet: EditableImageSet?
  @State private var showPhotoPicker = false
  @State private var showImageEditor = false
  @State private var showDeleteConfirm = false
  @State private var isLoadingImages = false

  var body: some View {
    VStack {
      // 読込中の表示
      if isLoadingImages {
        ProgressView("画像を読込中...")
          .padding()
      } else {
        ImageListSection(
          imageSets: $editingSets,
          addAction: { showPhotoPicker = true },
          selectAction: { set in
            // 画像編集前に確実に最新のデータを取得
            if !set.isNew && set.originalUrl != nil {
              // 既存の服の画像の場合、編集前にオリジナル画像が読み込まれていることを確認
              loadImageFromUrlIfNeeded(set) { updatedSet in
                selectedImageSet = updatedSet
                showImageEditor = true
              }
            } else {
              // 新規の場合はそのまま設定
              selectedImageSet = set
              showImageEditor = true
            }
          })
      }

      ClothingFormSection(clothing: $clothing)

      Spacer()

      ActionButtonsSection(
        saveAction: saveChanges,
        deleteAction: { showDeleteConfirm = true },
        canDelete: canDelete)
    }
    .navigationTitle("服を編集")
    .onAppear {
      // 初期ロード
      if editingSets.isEmpty {
        // 既存の服データを読み込み
        editingSets = viewModel.imageSetsMap[clothing.id] ?? []

        // 既存データの場合はデータを再ロードする
        if !isNew && !editingSets.isEmpty {
          loadImagesIfNeeded()
        }
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
        editingSets.append(newSet)

        // 画像選択後、即座にViewModelのキャッシュも更新
        viewModel.updateLocalImagesCache(clothing.id, imageSets: editingSets)
        print("📸 画像選択後にimageSetsMapを更新: \(clothing.id), 画像数: \(editingSets.count)")
      }
    }
    .sheet(item: $selectedImageSet) { imageSet in
      MaskEditorView(imageSet: bindingFor(imageSet))
        .onDisappear {
          // マスク編集後も即座にキャッシュを更新
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

  // MARK: - Actions

  // 必要に応じて画像を再読み込み
  private func loadImagesIfNeeded() {
    isLoadingImages = true
    Task {
      print("🔄 既存の服の画像を再読み込みします: \(clothing.id)")
      await viewModel.loadImagesForClothing(id: clothing.id)

      // UIを更新
      await MainActor.run {
        editingSets = viewModel.imageSetsMap[clothing.id] ?? []
        print("📥 画像の再読み込み完了: \(editingSets.count)枚")

        // 読み込みが終わっても画像が小さい場合はURLから直接ロードを試みる
        for (index, set) in editingSets.enumerated() {
          if set.original.size.width < 50 {
            loadImageFromURL(set: set, index: index)
          }
        }

        isLoadingImages = false
      }
    }
  }

  // URLから直接画像を読み込む（SDWebImageを活用）
  private func loadImageFromURL(set: EditableImageSet, index: Int) {
    guard let urlString = set.originalUrl, let url = URL(string: urlString) else { return }

    print("🌐 URLから画像を直接読み込み開始: \(urlString)")

    // SDWebImageを使用して画像をダウンロード
    SDWebImageManager.shared.loadImage(
      with: url,
      options: [.refreshCached],
      progress: nil) { (image, _, _, _, _, _) in
        guard let downloadedImage = image else {
          print("⚠️ URLからの画像読み込み失敗: \(urlString)")
          return
        }

        print("✅ URLから画像を直接取得: \(urlString), サイズ: \(downloadedImage.size)")

        // 編集中の配列を更新
        DispatchQueue.main.async {
          let updatedSet = EditableImageSet(
            id: set.id,
            original: downloadedImage,
            originalUrl: set.originalUrl,
            mask: set.mask,
            maskUrl: set.maskUrl,
            result: set.result,
            resultUrl: set.resultUrl,
            isNew: false
          )

          if index < self.editingSets.count {
            self.editingSets[index] = updatedSet
            print("✏️ URLからロードした画像でセットを更新: ID=\(set.id)")
          }
        }
      }
  }

  // 特定の画像セットが正しく読み込まれているか確認し、URLから直接読み込む
  private func loadImageFromUrlIfNeeded(_ set: EditableImageSet, completion: @escaping (EditableImageSet) -> Void) {
    // すでに有効な画像があれば何もしない
    if set.original.size.width > 50 && set.original.size.height > 50 {
      print("✅ 既に有効な画像があります: サイズ=\(set.original.size)")
      completion(set)
      return
    }

    print("⚠️ 画像が正しく読み込まれていません: ID=\(set.id)")

    // URLから直接読み込みを試みる
    if let urlString = set.originalUrl, let url = URL(string: urlString) {
      print("🌐 URL経由で画像を直接読み込みます: \(urlString)")

      // SDWebImageを使用して画像をダウンロード
      SDWebImageManager.shared.loadImage(
        with: url,
        options: [.refreshCached],
        progress: nil) { (image, _, _, _, _, _) in
          guard let downloadedImage = image else {
            print("⚠️ URLからの画像読み込み失敗: \(urlString)")
            completion(set) // 失敗した場合は元のセットを返す
            return
          }

          print("✅ URLから画像を直接取得: \(urlString), サイズ: \(downloadedImage.size)")

          let updatedSet = EditableImageSet(
            id: set.id,
            original: downloadedImage,
            originalUrl: set.originalUrl,
            mask: set.mask,
            maskUrl: set.maskUrl,
            result: set.result,
            resultUrl: set.resultUrl,
            isNew: false
          )

          // 編集中の配列も更新
          if let idx = self.editingSets.firstIndex(where: { $0.id == set.id }) {
            DispatchQueue.main.async {
              self.editingSets[idx] = updatedSet
            }
          }

          completion(updatedSet)
        }
    } else {
      // URLがない場合や無効な場合はローカルストレージから読み込む
      ensureImageLoaded(set, completion: completion)
    }
  }

  // ローカルストレージから画像を読み込む
  private func ensureImageLoaded(_ set: EditableImageSet, completion: @escaping (EditableImageSet) -> Void) {
    // ローカルストレージから画像を直接読み込む
    Task {
      let imageMetadataService = viewModel.imageMetadataService
      let localStorageService = viewModel.localStorageService

      do {
        // 画像メタデータを取得
        let images = try await imageMetadataService.fetchImages(for: clothing.id)

        // 対象の画像を探す
        if let image = images.first(where: { $0.id == set.id }) {
          var updatedSet = set

          // ローカルパスから画像を読み込む
          if let originalPath = image.originalLocalPath,
             let loadedImage = localStorageService.loadImage(from: originalPath) {
            print("📲 ローカルから画像を読み込みました: \(originalPath)")

            // 更新されたセットを作成
            updatedSet = EditableImageSet(
              id: set.id,
              original: loadedImage,
              originalUrl: image.originalUrl,
              mask: set.mask,
              maskUrl: image.maskUrl,
              result: set.result,
              resultUrl: image.resultUrl,
              isNew: false
            )

            // 編集中の配列も更新
            if let idx = editingSets.firstIndex(where: { $0.id == set.id }) {
              await MainActor.run {
                editingSets[idx] = updatedSet
              }
            }
          }

          // コールバックを呼び出す
          await MainActor.run {
            completion(updatedSet)
          }
        } else {
          // 見つからなかった場合は元のセットを返す
          await MainActor.run {
            completion(set)
          }
        }
      } catch {
        print("❌ 画像読み込みエラー: \(error.localizedDescription)")
        await MainActor.run {
          completion(set) // エラー時は元のセットを返す
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

  var body: some View {
    VStack(alignment: .leading) {
      // バインディング対応の共通コンポーネントを使用
      ClothingImageGalleryView(
        imageSets: $imageSets, // $を使ってバインディングを渡す
        showAddButton: true,
        onSelectImage: selectAction,
        onAddButtonTap: addAction)
    }
  }
}

private struct ClothingFormSection: View {
  @Binding var clothing: Clothing

  var body: some View {
    Form {
      Section(header: Text("服の情報")) {
        TextField("名前", text: $clothing.name)
        TextField("カテゴリ", text: $clothing.category)
        TextField("色", text: $clothing.color)
      }
    }
  }
}

private struct ActionButtonsSection: View {
  let saveAction: () -> Void
  let deleteAction: () -> Void
  let canDelete: Bool

  var body: some View {
    HStack {
      if canDelete {
        Button(action: deleteAction) {
          Text("削除")
            .foregroundColor(.red)
        }
        Spacer()
      }
      Button(action: saveAction) {
        Text("保存")
          .bold()
      }
    }
    .padding()
  }
}
