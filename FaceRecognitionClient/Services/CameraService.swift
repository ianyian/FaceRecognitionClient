//
//  CameraService.swift
//  FaceRecognitionClient
//
//  Created on November 29, 2025.
//

import AVFoundation
import UIKit
import SwiftUI
import Combine

class CameraService: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var error: Error?
    @Published var capturedImage: UIImage?
    
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var currentDevice: AVCaptureDevice?
    private var isSimulator: Bool = false
    
    var onFrameCapture: ((UIImage) -> Void)?
    
    override init() {
        super.init()
        #if targetEnvironment(simulator)
        isSimulator = true
        print("📱 Running in simulator - using mock camera mode")
        #endif
        checkAuthorization()
    }
    
    // MARK: - Authorization
    
    func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                }
            }
        default:
            isAuthorized = false
        }
    }
    
    // MARK: - Session Setup
    
    func setupSession() throws {
        guard isAuthorized else {
            throw NSError(domain: "CameraService", code: 1, 
                         userInfo: [NSLocalizedDescriptionKey: "Camera access not authorized"])
        }
        
        // Simulator mode - skip real camera setup
        if isSimulator {
            print("📱 Simulator detected - using mock camera")
            captureSession = AVCaptureSession() // Empty session for simulator
            isAuthorized = true
            return
        }
        
        let session = AVCaptureSession()
        session.beginConfiguration()
        
        // Set session preset
        if session.canSetSessionPreset(.photo) {
            session.sessionPreset = .photo
        }
        
        // Get camera device
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, 
                                                        for: .video, 
                                                        position: .front) else {
            throw NSError(domain: "CameraService", code: 2,
                         userInfo: [NSLocalizedDescriptionKey: "Could not find camera device"])
        }
        
        currentDevice = videoDevice
        
        // Add video input
        let videoInput = try AVCaptureDeviceInput(device: videoDevice)
        
        guard session.canAddInput(videoInput) else {
            throw NSError(domain: "CameraService", code: 3,
                         userInfo: [NSLocalizedDescriptionKey: "Could not add video input"])
        }
        
        session.addInput(videoInput)
        
        // Add photo output
        let photoOutput = AVCapturePhotoOutput()
        
        guard session.canAddOutput(photoOutput) else {
            throw NSError(domain: "CameraService", code: 4,
                         userInfo: [NSLocalizedDescriptionKey: "Could not add photo output"])
        }
        
        session.addOutput(photoOutput)
        self.photoOutput = photoOutput
        
        // Add video output for continuous frame capture
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.frame.queue"))
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            self.videoOutput = videoOutput
        }
        
        session.commitConfiguration()
        
        self.captureSession = session
        
        print("✅ Camera session configured")
    }
    
    // MARK: - Session Control
    
    func startSession() {
        guard let session = captureSession else { return }
        
        if isSimulator {
            print("📱 Simulator mode - camera session simulated")
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            if !session.isRunning {
                session.startRunning()
                print("✅ Camera session started")
            }
        }
    }
    
    func stopSession() {
        guard let session = captureSession else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            if session.isRunning {
                session.stopRunning()
                print("✅ Camera session stopped")
            }
        }
    }
    
    // MARK: - Photo Capture
    
    func capturePhoto() {
        if isSimulator {
            print("📱 Simulator mode - generating test image")
            generateTestImage()
            return
        }
        
        guard let photoOutput = photoOutput else {
            print("⚠️ Photo output not available")
            return
        }
        
        // Configure photo settings with available codec
        let settings: AVCapturePhotoSettings
        if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
            settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        } else if photoOutput.availablePhotoCodecTypes.contains(.jpeg) {
            settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        } else {
            settings = AVCapturePhotoSettings()
        }
        
        photoOutput.capturePhoto(with: settings, delegate: self)
        print("📸 Capturing photo...")
    }
    
    // MARK: - Preview Layer
    
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        guard let session = captureSession else { return nil }
        
        if isSimulator {
            // Return nil for simulator - will show placeholder
            return nil
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        
        return previewLayer
    }
    
    // MARK: - Simulator Support
    
    private func generateTestImage() {
        // Create a test image with some content
        let size = CGSize(width: 640, height: 480)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            // Fill with gray background
            UIColor.gray.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Draw some text
            let text = "Simulator Test Image\n\(Date().formatted(date: .omitted, time: .standard))"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            text.draw(in: textRect, withAttributes: attributes)
        }
        
        DispatchQueue.main.async {
            self.capturedImage = image
            print("✅ Test image generated for simulator")
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, 
                    didFinishProcessingPhoto photo: AVCapturePhoto, 
                    error: Error?) {
        if let error = error {
            print("❌ Error capturing photo: \(error)")
            DispatchQueue.main.async {
                self.error = error
            }
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("❌ Could not convert photo to image")
            return
        }
        
        DispatchQueue.main.async {
            self.capturedImage = image
            print("✅ Photo captured successfully")
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                      didOutput sampleBuffer: CMSampleBuffer,
                      from connection: AVCaptureConnection) {
        // Convert sample buffer to UIImage for frame processing
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext()
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        
        let image = UIImage(cgImage: cgImage)
        
        DispatchQueue.main.async {
            self.onFrameCapture?(image)
        }
    }
}
