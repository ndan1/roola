//
//  PoseCaptureViewController.swift
//  Roola
//
//  Created by Lin Dan Christiano on 29/10/25.
//

import UIKit
import AVFoundation
import Vision

protocol PoseCaptureDelegate: AnyObject {
    func didCaptureValidPose(image: UIImage, measurements: BodyMeasurements)
}

struct BodyMeasurements {
    let armSpan: CGFloat
    let shoulderWidth: CGFloat
    let torsoLength: CGFloat
}

class PoseCaptureViewController: UIViewController {
    
    // MARK: - Properties
    weak var delegate: PoseCaptureDelegate?
    
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private var photoOutput = AVCapturePhotoOutput()
    
    private var overlayView: PoseValidationOverlay!
    private var isCapturing = false
    private var validPoseCount = 0
    private let requiredValidFrames = 15
    
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
        
        overlayView.showFeedback("Posisikan tubuh Anda\nLengan melentang 45° ke bawah", color: .systemBlue)
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .front) else {
            showFeedback("Kamera tidak tersedia", color: .systemRed)
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            
            // PERBAIKAN: Set orientation untuk video output
            if let connection = videoDataOutput.connection(with: .video) {
//                connection.videoOrientation = .portrait
                // Mirror untuk front camera
                if camera.position == .front {
//                    connection.isVideoMirrored = true
                }
            }
            
            if captureSession.canAddOutput(videoDataOutput) {
                captureSession.addOutput(videoDataOutput)
            }
            
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = .resizeAspect
            previewLayer.connection?.videoOrientation = .portrait
            view.layer.insertSublayer(previewLayer, at: 0)
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
            }
            
        } catch {
            showFeedback("Error setup kamera: \(error.localizedDescription)", color: .systemRed)
        }
    }

    
    // MARK: - Feedback
    private func showFeedback(_ message: String, color: UIColor = .systemOrange) {
        overlayView.showFeedback(message, color: color)
    }
    
    private func showValidPoseIndicator(_ show: Bool) {
        overlayView.showValidPoseIndicator(show)
        
        let progress = Float(validPoseCount) / Float(requiredValidFrames)
        overlayView.updateProgress(show ? progress : 0.0)
    }
    
    // MARK: - Photo Capture
    private func capturePhoto(with measurements: BodyMeasurements) {
        guard !isCapturing else { return }
        isCapturing = true
        
        overlayView.showSuccessAnimation {
            let settings = AVCapturePhotoSettings()
            settings.flashMode = .off
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
        
        showFeedback("✓ Foto berhasil diambil!", color: .systemGreen)
    }
}

// MARK: - Video Capture Delegate
extension PoseCaptureViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput,
                      didOutput sampleBuffer: CMSampleBuffer,
                      from connection: AVCaptureConnection) {
        
        guard !isCapturing,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        
        let request = VNDetectHumanBodyPoseRequest { [weak self] request, error in
            guard let observations = request.results as? [VNHumanBodyPoseObservation],
                  let observation = observations.first else {
                self?.validPoseCount = 0
                self?.showFeedback("Pastikan tubuh terlihat jelas", color: .systemRed)
                self?.showValidPoseIndicator(false)
                return
            }
            
            self?.processPoseObservation(observation)
        }
        
        let requestOrientation: CGImagePropertyOrientation = .leftMirrored
        
        // GUNAKAN ORIENTATION YANG BENAR
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                            orientation: requestOrientation,
                                            options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            print("❌ Vision request error: \(error)")
        }
    }

    
    // MARK: - Helper Methods
    private func convertVisionPoint(_ point: VNRecognizedPoint, in imageSize: CGSize) -> CGPoint {
        // Vision coordinates: (0,0) = bottom-left, (1,1) = top-right
        // Screen coordinates: (0,0) = top-left
        
        let x = point.x * imageSize.width
        let y = (1.0 - point.y) * imageSize.height // Flip Y axis
        
        return CGPoint(x: x, y: y)
    }

    private func calculateDistance(_ point1: VNRecognizedPoint, _ point2: VNRecognizedPoint) -> CGFloat {
        let dx = point2.x - point1.x
        let dy = point2.y - point1.y
        return sqrt(dx * dx + dy * dy)
    }

    
    private func processPoseObservation(_ observation: VNHumanBodyPoseObservation) {
        do {
            // Dapatkan keypoints
            let leftWrist = try observation.recognizedPoint(.leftWrist)
            let rightWrist = try observation.recognizedPoint(.rightWrist)
            let leftShoulder = try observation.recognizedPoint(.leftShoulder)
            let rightShoulder = try observation.recognizedPoint(.rightShoulder)
            let leftElbow = try observation.recognizedPoint(.leftElbow)
            let rightElbow = try observation.recognizedPoint(.rightElbow)
            let leftHip = try observation.recognizedPoint(.leftHip)
            let rightHip = try observation.recognizedPoint(.rightHip)
            let neck = try observation.recognizedPoint(.neck)
            let leftAnkle = try observation.recognizedPoint(.leftAnkle)
            let rightAnkle = try observation.recognizedPoint(.rightAnkle)
            
            // 1. Cek confidence
            guard leftWrist.confidence > 0.4,
                  rightWrist.confidence > 0.4,
                  leftShoulder.confidence > 0.4,
                  rightShoulder.confidence > 0.4,
                  neck.confidence > 0.4,
                  leftAnkle.confidence > 0.3,
                  rightAnkle.confidence > 0.3 else {
                validPoseCount = 0
                showFeedback("Pastikan seluruh tubuh terlihat", color: .systemOrange)
                showValidPoseIndicator(false)
                return
            }
            
            // 2. VALIDASI ARM SPAN - Kedua tangan harus melentang lebar
            let armSpanX = abs(leftWrist.x - rightWrist.x)
            
            // DEBUG
            print("🔍 DEBUG - Arm Span X: \(String(format: "%.3f", armSpanX)) (\(Int(armSpanX * 100))%)")
            print("🔍 DEBUG - Left Wrist X: \(String(format: "%.3f", leftWrist.x))")
            print("🔍 DEBUG - Right Wrist X: \(String(format: "%.3f", rightWrist.x))")
            print("🔍 DEBUG - Shoulder Width X: \(String(format: "%.3f", abs(leftShoulder.x - rightShoulder.x)))")
            
            // REQUIREMENT: Arm span minimal 50% dari lebar layar
            let minArmSpanX: CGFloat = 0.50
            let maxArmSpanX: CGFloat = 0.90
            
            if armSpanX < minArmSpanX {
                validPoseCount = 0
                showFeedback("🙆‍♂️ Rentangkan kedua lengan lebih lebar ke samping\n(Jarak: \(Int(armSpanX * 100))% dari lebar)", color: .systemYellow)
                showValidPoseIndicator(false)
                return
            } else if armSpanX > maxArmSpanX {
                validPoseCount = 0
                showFeedback("📏 Terlalu lebar, rapatkan sedikit", color: .systemYellow)
                showValidPoseIndicator(false)
                return
            }
            
            // 3. VALIDASI POSISI Y - Tangan harus turun ke bawah
            // Vision coordinates: Y=0 di bawah, Y=1 di atas
            // Wrist harus memiliki Y lebih kecil dari shoulder (lebih rendah)
            
            let leftAngle = calculateArmAngle(shoulder: leftShoulder, wrist: leftWrist)
            let rightAngle = calculateArmAngle(shoulder: rightShoulder, wrist: rightWrist)

            DispatchQueue.main.async {
                print("🔍 DEBUG - Left Angle: \(String(format: "%.1f", leftAngle))° | Right Angle: \(String(format: "%.1f", rightAngle))°")
            }

            // Target:
            // Lengan Kiri (Left Arm) = -135° (kita beri rentang misal -155° s/d -115°)
            // Lengan Kanan (Right Arm) = -45° (kita beri rentang misal -65° s/d -25°)

            let leftAngleValid = (leftAngle > -70 && leftAngle < -20)
            let rightAngleValid = (rightAngle > -160 && rightAngle < -110)

            if !leftAngleValid || !rightAngleValid {
                validPoseCount = 0
                showFeedback("⬇️ Posisikan lengan 45° ke bawah\n(Bentuk 'A')", color: .systemOrange)
                showValidPoseIndicator(false)
                return
            }
            
            // 4. VALIDASI SYMMETRY - Kedua tangan harus setinggi/sejajar
            let ySymmetry = abs(leftWrist.y - rightWrist.y)
            let maxYAsymmetry: CGFloat = 0.08
            
            print("🔍 DEBUG - Y Symmetry: \(String(format: "%.3f", ySymmetry))")
            
            if ySymmetry > maxYAsymmetry {
                validPoseCount = 0
                showFeedback("⚖️ Sejajarkan tinggi kedua tangan", color: .systemOrange)
                showValidPoseIndicator(false)
                return
            }
            
            // 5. VALIDASI FULL BODY - Pastikan seluruh tubuh terlihat
            let bodyHeight = abs(neck.y - ((leftHip.y + rightHip.y) / 2))
            
            print("🔍 DEBUG - Body Height: \(String(format: "%.3f", bodyHeight))")
            
            if bodyHeight < 0.15 {
                validPoseCount = 0
                showFeedback("📏 Mundur sedikit agar seluruh tubuh terlihat", color: .systemYellow)
                showValidPoseIndicator(false)
                return
            }
            
            validPoseCount += 1
            showValidPoseIndicator(true)
            
            let progressPercent = Int((Float(validPoseCount) / Float(requiredValidFrames)) * 100)
            showFeedback("✅ Pose sempurna! (\(progressPercent)%)\nTahan posisi...", color: .systemGreen)
            
            if validPoseCount >= requiredValidFrames {
                let measurements = BodyMeasurements(
                    armSpan: armSpanX * previewLayer.bounds.width,
                    shoulderWidth: abs(leftShoulder.x - rightShoulder.x) * previewLayer.bounds.width,
                    torsoLength: bodyHeight * previewLayer.bounds.height
                )
                capturePhoto(with: measurements)
            }
            
        } catch {
            validPoseCount = 0
            showFeedback("Error deteksi pose", color: .systemRed)
            showValidPoseIndicator(false)
        }
    }

    
    private func calculateArmAngle(shoulder: VNRecognizedPoint, wrist: VNRecognizedPoint) -> CGFloat {
        // Fungsi ini menghitung sudut lengan relatif terhadap sumbu X horizontal positif (0 derajat)
        // Koordinat Vision: Y=0 di bawah, Y=1 di atas

        let deltaX = wrist.x - shoulder.x
        let deltaY = wrist.y - shoulder.y

        // atan2 akan memberi kita sudut dalam radian
        let angleRadians = atan2(deltaY, deltaX)
        let angleDegrees = angleRadians * 180 / .pi

        // Hasilnya akan:
        // Lengan kanan lurus (T-pose): ~0 derajat
        // Lengan kiri lurus (T-pose): ~180 derajat
        // Lengan kanan 45° ke bawah: ~ -45 derajat
        // Lengan kiri 45° ke bawah: ~ -135 derajat

        return angleDegrees
    }

}

// MARK: - Photo Capture Delegate
extension PoseCaptureViewController: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput,
                    didFinishProcessingPhoto photo: AVCapturePhoto,
                    error: Error?) {
        
        guard error == nil,
              let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            showFeedback("Gagal mengambil foto", color: .systemRed)
            isCapturing = false
            return
        }
        
        // Delay sebelum dismiss untuk menampilkan feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            let dummyMeasurements = BodyMeasurements(armSpan: 0, shoulderWidth: 0, torsoLength: 0)
            self?.delegate?.didCaptureValidPose(image: image, measurements: dummyMeasurements)
            self?.dismiss(animated: true)
        }
    }
}
