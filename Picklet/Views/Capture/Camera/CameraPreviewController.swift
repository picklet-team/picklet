//
//  CameraPreviewController.swift
//  Picklet
//
//  Created by al dente on 2025/04/26.
//

import AVFoundation
import UIKit

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
    captureSession?.sessionPreset = .high

    guard let backCamera = AVCaptureDevice.default(for: .video),
          let input = try? AVCaptureDeviceInput(device: backCamera),
          let captureSession = captureSession
    else { return }
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

  func photoOutput(
    _ output: AVCapturePhotoOutput,
    didFinishProcessingPhoto photo: AVCapturePhoto,
    error: Error?
  ) {
    guard let data = photo.fileDataRepresentation(),
          let image = UIImage(data: data),
          let layer = previewLayer
    else { return }

    // プレビューに写っていた矩形(0-1正規化) → 画像座標へ変換
    let visible = layer.metadataOutputRectConverted(fromLayerRect: layer.bounds)
    let cgImage = image.cgImage!
    let crop = CGRect(
      x: visible.origin.x * CGFloat(cgImage.width),
      y: visible.origin.y * CGFloat(cgImage.height),
      width: visible.size.width * CGFloat(cgImage.width),
      height: visible.size.height * CGFloat(cgImage.height)
    ).integral

    guard let cropped = cgImage.cropping(to: crop) else {
      onImageCaptured?(image) // 失敗時はオリジナル
      return
    }

    onImageCaptured?(
      UIImage(
        cgImage: cropped,
        scale: image.scale,
        orientation: image.imageOrientation
      ))
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    previewLayer?.frame = view.bounds
  }
}
