//
//  CameraPreviewController.swift
//  MyApp
//
//  Created by al dente on 2025/04/26.
//


import UIKit
import AVFoundation

class CameraPreviewController: UIViewController, AVCapturePhotoCaptureDelegate {
    var captureSession: AVCaptureSession?
    var photoOutput: AVCapturePhotoOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?

    var onImageCaptured: ((UIImage) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }

    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .photo

        guard let backCamera = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: backCamera),
              let captureSession = captureSession else { return }
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        photoOutput = AVCapturePhotoOutput()
        if let photoOutput = photoOutput, captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = view.bounds
        if let previewLayer = previewLayer {
            view.layer.addSublayer(previewLayer)
        }
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
    }

    func capture() {
        let settings = AVCapturePhotoSettings()
        photoOutput?.capturePhoto(with: settings, delegate: self)
    }

    @objc private func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput?.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }
        let squareImage = cropToSquare(image: image)
        onImageCaptured?(squareImage)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    private func cropToSquare(image: UIImage) -> UIImage {
        let originalWidth = image.size.width
        let originalHeight = image.size.height

        // カメラセンサーのアスペクト比と、プレビュー表示比が違うため
        // 中央を正方形でトリミングする
        let edgeLength = min(originalWidth, originalHeight)
        let cropX = (originalWidth - edgeLength) / 2.0
        let cropY = (originalHeight - edgeLength) / 2.0

        let cropRect = CGRect(x: cropX, y: cropY, width: edgeLength, height: edgeLength)

        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            print("⚠️ 正方形クロップ失敗、オリジナルを返します")
            return image
        }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }

}
