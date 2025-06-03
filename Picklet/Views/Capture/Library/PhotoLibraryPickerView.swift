//
//  PhotoLibraryPickerView.swift
//  Picklet
//
//  Updated: keep the same item at the top when column count changes
//

import Photos
import SwiftUI

struct PhotoLibraryPickerView: View {
  @EnvironmentObject var themeManager: ThemeManager // 追加
  let onImagePicked: (UIImage) -> Void
  @Environment(\.dismiss) private var dismiss

  @State private var assets: [PHAsset] = []
  private let imageManager = PHCachingImageManager()

  private var columnsCount: Int = 4
  private let spacing: CGFloat = 4

  /// イニシャライザ
  init(onImagePicked: @escaping (UIImage) -> Void) {
    self.onImagePicked = onImagePicked
  }

  var body: some View {
    ZStack {
      // 背景グラデーション
      themeManager.currentTheme.backgroundGradient
        .ignoresSafeArea()

      NavigationView {
        GeometryReader { geo in
          let totalSpacing = spacing * CGFloat(columnsCount + 1)
          let cellSize = (geo.size.width - totalSpacing) / CGFloat(columnsCount)

          ScrollView {
            LazyVGrid(
              columns: Array(repeating: .init(.fixed(cellSize), spacing: spacing), count: columnsCount),
              spacing: spacing) {
                ForEach(assets, id: \.localIdentifier) { asset in
                  PhotoThumbnailCell(
                    asset: asset,
                    size: cellSize,
                    manager: imageManager) { image in
                      let square = image.squareCropped()
                      onImagePicked(square)
                      dismiss()
                    }
                    .environmentObject(themeManager) // テーマを渡す
                }
              }
              .padding(spacing)
          }
          .accessibility(identifier: "photoLibraryPicker")
          .onAppear(perform: fetchAssets)
        }
        .navigationTitle("写真を選択")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
          ToolbarItem(placement: .navigationBarLeading) {
            Button("キャンセル") {
              dismiss()
            }
            .foregroundColor(themeManager.currentTheme.primaryColor)
          }
        }
      }
      .tint(themeManager.currentTheme.accentColor)
    }
  }

  private func fetchAssets() {
    let opts = PHFetchOptions()
    opts.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
    let result = PHAsset.fetchAssets(with: .image, options: opts)
    var tmp: [PHAsset] = []
    result.enumerateObjects { obj, _, _ in tmp.append(obj) }
    assets = tmp
  }
}

// MARK: - Thumbnail Cell

struct PhotoThumbnailCell: View {
  @EnvironmentObject var themeManager: ThemeManager // 追加
  let asset: PHAsset
  let size: CGFloat
  let manager: PHCachingImageManager
  let onSelect: (UIImage) -> Void

  @State private var thumbnail: UIImage?
  @State private var isLoading = true

  var body: some View {
    ZStack {
      if let thumb = thumbnail {
        Image(uiImage: thumb)
          .resizable()
          .scaledToFill()
      } else {
        // ローディング状態のプレースホルダー
        ZStack {
          Color(.systemGray6)

          if isLoading {
            ProgressView()
              .scaleEffect(0.8)
              .tint(themeManager.currentTheme.primaryColor)
          }
        }
      }
    }
    .frame(width: size, height: size)
    .clipped()
    .cornerRadius(8)
    .overlay(
      RoundedRectangle(cornerRadius: 8)
        .stroke(Color(.systemGray4), lineWidth: 0.5)
    )
    .onAppear(perform: loadThumb)
    .onTapGesture { requestFull() }
  }

  private func loadThumb() {
    let opts = PHImageRequestOptions()
    opts.deliveryMode = .highQualityFormat
    opts.resizeMode = .exact
    let target = CGSize(width: size * UIScreen.main.scale, height: size * UIScreen.main.scale)

    manager.requestImage(for: asset, targetSize: target, contentMode: .aspectFill, options: opts) { img, _ in
      DispatchQueue.main.async {
        self.thumbnail = img
        self.isLoading = false
      }
    }
  }

  private func requestFull() {
    let opts = PHImageRequestOptions()
    opts.deliveryMode = .highQualityFormat
    opts.resizeMode = .exact
    opts.isNetworkAccessAllowed = true
    let target = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)

    manager.requestImage(for: asset, targetSize: target, contentMode: .aspectFit, options: opts) { img, _ in
      if let img = img { onSelect(img) }
    }
  }
}
