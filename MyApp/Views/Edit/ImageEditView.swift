//
//  ImageEditView.swift
//  MyApp
//
//  Created by al dente on 2025/04/29.
//


// ImageEditView.swift
import SwiftUI

struct ImageEditView: View {
    let imageSet: EditableImageSet

    var body: some View {
        VStack {
            Text("画像編集画面")
            if let image = imageSet.original {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
                    .frame(width: 300, height: 300)
                    .clipped()
            } else if let url = imageSet.originalUrl {
                Text("URL: \(url)")
            } else {
                Text("画像なし")
            }
        }
        .padding()
    }
}

