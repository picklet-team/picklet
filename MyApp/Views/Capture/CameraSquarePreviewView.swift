//
//  CameraSquarePreviewView.swift
//  MyApp
//
//  Created by al dente on 2025/04/30.
//


import SwiftUI

struct CameraSquarePreviewView: View {
    let onCaptured: (UIImage) -> Void

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)

            CameraPreviewView(onImageCaptured: onCaptured)
                .frame(width: size, height: size)
                .clipped()
        }
    }
}
