//
//  CameraPreviewView.swift
//  MyApp
//
//  Created by al dente on 2025/04/26.
//


import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewControllerRepresentable {
    var onImageCaptured: (UIImage) -> Void

    func makeUIViewController(context: Context) -> CameraPreviewController {
        let controller = CameraPreviewController()
        controller.onImageCaptured = onImageCaptured
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraPreviewController, context: Context) {}
}
