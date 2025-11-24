//
//  PoseCaptureViewController.swift
//  Roola
//
//  Created by Lin Dan Christiano on 29/10/25.
//

import UIKit
import AVFoundation
import Vision

// MARK: - Delegate Protocol Updated
protocol PoseCaptureDelegate: AnyObject {
    // Changed from videoURL to image
    func didCapture(image: UIImage, measurements: BodyMeasurements)
}

struct BodyMeasurements {
    let armSpan: CGFloat
    let shoulderWidth: CGFloat
    let torsoLength: CGFloat
}

class PoseCaptureViewController: UIViewController {
    
    // MARK: - Properties
    weak var delegate: PoseCaptureDelegate?
    var onBackButtonTapped: (() -> Void)?
    
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    
    // Outputs
    private let videoDataOutput = AVCaptureVideoDataOutput() // Keeps running for Vision
    private let photoOutput = AVCapturePhotoOutput()         // New: For capturing the image
    
    private var overlayView: PoseValidationOverlay!
    
    // State
    private var isCapturingPhoto = false // Replaces isRecording
    private var isCountingDown = false
    private var measurementsToSave: BodyMeasurements?
    
    private var validPoseCount = 0
    private let requiredValidFrames = 15
    
    private lazy var stencilImageA: UIImage? = UIImage(named: "red_stencil")
    private lazy var stencilImageB: UIImage? = UIImage(named: "green_stencil")
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCamera()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .black
        
        overlayView = PoseValidationOverlay(frame: view.bounds)
        overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(overlayView)
        
        overlayView.onBackTapped = { [weak self] in
            self?.handleBackButton()
        }
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo // Optimized for high res photos
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                  for: .video,
                                                  position: .front) else {
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            // 1. Vision Output (Data Stream)
            videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            if captureSession.canAddOutput(videoDataOutput) {
                captureSession.addOutput(videoDataOutput)
            }
            
            // 2. Photo Output (Capture)
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
                // Optional: Enable high-res if needed
                photoOutput.isHighResolutionCaptureEnabled = true
            }
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.connection?.videoRotationAngle = 90
            view.layer.insertSublayer(previewLayer, at: 0)
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
            }
            
        } catch {
            showFeedback("Error setup camera: \(error.localizedDescription)", color: .systemRed)
        }
    }
    
    // MARK: - Feedback (GUARDED)
    private func showFeedback(_ message: String, color: UIColor = .systemOrange) {
        guard !isCountingDown && !isCapturingPhoto else { return }
        overlayView.showFeedback(message, color: color)
    }
    
    private func showValidPoseIndicator(_ show: Bool) {
        guard !isCountingDown && !isCapturingPhoto else { return }
        overlayView.showValidPoseIndicator(show)
        overlayView.setStencil(image: show ? stencilImageB : stencilImageA)
    }
    
    @objc private func handleBackButton() {
        print("Back tapped")
        cancelCapture()
        onBackButtonTapped?()
    }
    
    private func cancelCapture() {
        isCapturingPhoto = false
        isCountingDown = false
        validPoseCount = 0
        measurementsToSave = nil
    }
    
    // MARK: - Photo Capture Logic
    private func takePhoto() {
        guard let connection = photoOutput.connection(with: .video) else { return }
        
        // Ensure orientation matches UI (Portrait)
        connection.videoRotationAngle = 90
        
        // Setup Settings
        let settings = AVCapturePhotoSettings()
        // If you need flash: settings.flashMode = .auto
        
        // Capture
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

// MARK: - Vision / Video Data Delegate
extension PoseCaptureViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // STOP PROCESSING DURING COUNTDOWN OR CAPTURE
        if isCountingDown || isCapturingPhoto {
            return
        }
        
        // NORMAL POSE DETECTION
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNDetectHumanBodyPoseRequest { [weak self] request, error in
            guard let observations = request.results as? [VNHumanBodyPoseObservation],
                  let observation = observations.first else {
                self?.validPoseCount = 0
                self?.showValidPoseIndicator(false)
                return
            }
            self?.processPoseObservation(observation)
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                            orientation: .leftMirrored,
                                            options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Vision error: \(error)")
        }
    }
    
    // MARK: - Pose Processing
    private func processPoseObservation(_ observation: VNHumanBodyPoseObservation) {
        do {
            let leftWrist = try observation.recognizedPoint(.leftWrist)
            let rightWrist = try observation.recognizedPoint(.rightWrist)
            let leftShoulder = try observation.recognizedPoint(.leftShoulder)
            let rightShoulder = try observation.recognizedPoint(.rightShoulder)
            let leftHip = try observation.recognizedPoint(.leftHip)
            let rightHip = try observation.recognizedPoint(.rightHip)
            let neck = try observation.recognizedPoint(.neck)
            let leftAnkle = try observation.recognizedPoint(.leftAnkle)
            let rightAnkle = try observation.recognizedPoint(.rightAnkle)
            
            // Confidence checks
            guard leftWrist.confidence > 0.4,
                  rightWrist.confidence > 0.4,
                  leftShoulder.confidence > 0.4,
                  rightShoulder.confidence > 0.4,
                  neck.confidence > 0.4,
                  leftAnkle.confidence > 0.3,
                  rightAnkle.confidence > 0.3 else {
                validPoseCount = 0
                showValidPoseIndicator(false)
                return
            }
            
            // --- LOGIC: (Same as before) ---
            let bodyHeight = abs(neck.y - ((leftHip.y + rightHip.y) / 2))
            if bodyHeight < 0.16 || bodyHeight > 0.20 {
                validPoseCount = 0; showValidPoseIndicator(false); return
            }
            
            let armSpanX = abs(leftWrist.x - rightWrist.x)
            if armSpanX < 0.40 || armSpanX > 0.90 {
                validPoseCount = 0; showValidPoseIndicator(false); return
            }
            
            let leftAngle = calculateArmAngle(shoulder: leftShoulder, wrist: leftWrist)
            let rightAngle = calculateArmAngle(shoulder: rightShoulder, wrist: rightWrist)
            let leftValid = leftAngle > -70 && leftAngle < -20
            let rightValid = rightAngle > -160 && rightAngle < -110
            if !leftValid || !rightValid {
                validPoseCount = 0; showValidPoseIndicator(false); return
            }
            
            let ySymmetry = abs(leftWrist.y - rightWrist.y)
            if ySymmetry > 0.08 {
                validPoseCount = 0; showValidPoseIndicator(false); return
            }
            // --------------------------------
            
            validPoseCount += 1
            showValidPoseIndicator(true)
            showFeedback("Hold Still", color: UIColor(AppColors.primaryPurple))
            
            // TRIGGER CAPTURE
            if validPoseCount >= requiredValidFrames {
                guard !isCapturingPhoto && !isCountingDown else { return }
                
                isCountingDown = true
                validPoseCount = 0
                
                // Save measurements snapshot
                let shoulderWidth = abs(leftShoulder.x - rightShoulder.x)
                measurementsToSave = BodyMeasurements(
                    armSpan: armSpanX * previewLayer.bounds.width,
                    shoulderWidth: shoulderWidth * previewLayer.bounds.width,
                    torsoLength: bodyHeight * previewLayer.bounds.height
                )
                
                // START COUNTDOWN + PHOTO CAPTURE
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    self.showFeedback("Hold Still", color: UIColor(AppColors.primaryPurple))
                    
                    // Start Countdown UI
                    self.overlayView.startCountdown {
                        // Countdown Finished (3, 2, 1, Done)
                        guard self.isCountingDown else { return }
                        
                        print("Countdown done. Snap photo!")
                        self.isCapturingPhoto = true
                        self.isCountingDown = false
                        
                        // SNAP!
                        self.takePhoto()
                    }
                }
            }
            
        } catch {
            validPoseCount = 0
            showFeedback("Error detection", color: .systemRed)
            showValidPoseIndicator(false)
        }
    }
    
    private func calculateArmAngle(shoulder: VNRecognizedPoint, wrist: VNRecognizedPoint) -> CGFloat {
        let deltaX = wrist.x - shoulder.x
        let deltaY = wrist.y - shoulder.y
        let radians = atan2(deltaY, deltaX)
        return radians * 180 / .pi
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension PoseCaptureViewController: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        if let error = error {
            print("Error capturing photo: \(error)")
            resetCaptureState()
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("Could not generate UIImage")
            resetCaptureState()
            return
        }
        
        // Flip image if using front camera (Mirror effect)
        let savedImage: UIImage
        if let cgImage = image.cgImage {
             savedImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: .leftMirrored)
        } else {
            savedImage = image
        }
        
        // Success Flow
        guard let measurements = measurementsToSave else {
             print("Measurements lost")
             resetCaptureState()
             return
        }
        
        DispatchQueue.main.async {
            // Success Animation
            self.overlayView.showSuccessCloseAnimation {
                // Return to SwiftUI
                self.delegate?.didCapture(image: savedImage, measurements: measurements)
            }
        }
    }
    
    private func resetCaptureState() {
        isCapturingPhoto = false
        isCountingDown = false
        validPoseCount = 0
        measurementsToSave = nil
    }
}
