//
//  LibraryPickerView.swift
//  MyApp
//
//  Created by al dente on 2025/04/26.
//

import PhotosUI
import SwiftUI

struct LibraryPickerView: View {
  var onImagePicked: (UIImage) -> Void
  @Environment(\.dismiss) private var dismiss
  @StateObject private var vm = LibraryPickerViewModel()
  @State private var columnsCount: Int = 10
  private let spacing: CGFloat = 4

  var body: some View {
    NavigationView {
      GeometryReader { geo in
        //                let totalSpacing = spacing * CGFloat(columnsCount + 1)
        //                let cellSize = (geo.size.width - totalSpacing) / CGFloat(columnsCount)

        VStack(spacing: spacing) {
          //                    // 列数選択メニュー
          //                    HStack {
          //                        Spacer()
          //                        Menu {
          //                            Button("3列") { columnsCount = 3 }
          //                            Button("4列") { columnsCount = 4 }
          //                            Button("5列") { columnsCount = 5 }
          //                        } label: {
          //                            Label("\(columnsCount)列", systemImage: "square.grid.3x3")
          //                                .padding(.trailing, spacing)
          //                        }
          //                    }

          // グリッド表示
          //                    ScrollView {
          //                        LazyVGrid(
          //                            columns: Array(repeating: .init(.fixed(cellSize), spacing: spacing), count: columnsCount),
          //                            spacing: spacing
          //                        ) {
          //                            ForEach(vm.urls, id: \.self) { url in
          //                                LibraryImageCell(url: url, cellSize: cellSize) { image in
          //                                    onImagePicked(image)
          //                                }
          //                            }
          //                        }
          //                        .padding(spacing)
          //                    }
        }
      }
      .navigationTitle("画像を選択")
      .onAppear { vm.fetch() }
    }
  }
}

// MARK: - セル用サブビュー
struct LibraryImageCell: View {
  let url: URL
  let cellSize: CGFloat
  let onImagePicked: (UIImage) -> Void
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    AsyncImage(url: url, scale: UIScreen.main.scale) { phase in
      switch phase {
      case .success(let image):
        image
          .resizable()
          .interpolation(.high)
          .scaledToFill()
          .frame(width: cellSize, height: cellSize)
          .clipped()
          .cornerRadius(6)
      case .failure:
        Color.gray.opacity(0.2)
          .frame(width: cellSize, height: cellSize)
          .overlay(Image(systemName: "xmark.octagon"))
      default:
        ProgressView()
          .frame(width: cellSize, height: cellSize)
      }
    }
    .onTapGesture {
      Task {
        if let (data, _) = try? await URLSession.shared.data(from: url),
          let uiImage = UIImage(data: data)
        {
          onImagePicked(uiImage)
          dismiss()
        }
      }
    }
  }
}
