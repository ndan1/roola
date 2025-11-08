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
    func didCaptureVideo(videoURL: URL, measurements: BodyMeasurements)
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
    
    private var overlayView: PoseValidationOverlay!
    private var isRecording = false
    private var videoWriter: AVAssetWriter?
    private var videoWriterInput: AVAssetWriterInput?
    private var recordingTimer: Timer?
    private var measurementsToSave: BodyMeasurements?
    private var videoURLToSave: URL?
    private var isSettingUpWriter = false
    
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
        
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .front) else {
//            showFeedback("Kamera tidak tersedia", color: .systemRed)\
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            
            if captureSession.canAddOutput(videoDataOutput) {
                captureSession.addOutput(videoDataOutput)
            }
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.connection?.videoRotationAngle = 90
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
        
        if show {
            overlayView.setStencil(image: stencilImageB)
        } else {
            overlayView.setStencil(image: stencilImageA)
        }
    }
}

// MARK: - Video Capture Delegate
extension PoseCaptureViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    private func setupVideoWriter(with buffer: CMSampleBuffer) {
        // Dapatkan dimensi video dari buffer pertama
        guard let formatDesc = CMSampleBufferGetFormatDescription(buffer) else {
            print("Error: Tidak bisa mendapatkan dimensi video")
            isRecording = false
            return
        }
        let dimensions = CMVideoFormatDescriptionGetDimensions(formatDesc)
        
        // Buat URL file unik
        let fileName = "poseVideo-\(UUID().uuidString).mp4"
        let videoURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        videoURLToSave = videoURL // Simpan URL untuk dikirim ke delegate
        
        do {
            videoWriter = try AVAssetWriter(url: videoURL, fileType: .mp4)
        } catch {
            print("Error membuat AVAssetWriter: \(error)")
            isRecording = false
            return
        }
        
        // Pengaturan Video (gunakan dimensi dari buffer)
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(dimensions.width),
            AVVideoHeightKey: Int(dimensions.height)
        ]
        
        videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoWriterInput?.expectsMediaDataInRealTime = true
        
        let transform = CGAffineTransform(rotationAngle: .pi / 2) // Mirror horizontal
        videoWriterInput?.transform = transform
        
        if let writerInput = videoWriterInput, videoWriter!.canAdd(writerInput) {
            videoWriter!.add(writerInput)
        } else {
            print("Error: Tidak bisa menambahkan video writer input")
            isRecording = false
            return
        }
        
        // Mulai sesi penulisan - HANYA PANGGIL SEKALI
        videoWriter?.startWriting()
        
        // Cek apakah berhasil
        guard videoWriter?.status == .writing else {
            print("Error: Gagal memulai video writer. \(videoWriter?.error?.localizedDescription ?? "")")
            isRecording = false
            try? FileManager.default.removeItem(at: videoURL)
            videoURLToSave = nil
            return
        }
        
        let startTime = CMSampleBufferGetPresentationTimeStamp(buffer)
        videoWriter?.startSession(atSourceTime: startTime)
        
        print("✅ Video writer berhasil di-setup dan mulai menulis")
    }

    @objc private func stopRecording() {
        guard isRecording else { return }
        
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        guard let writer = videoWriter,
              let url = videoURLToSave,
              let measurements = measurementsToSave else {
            print("Batal merekam: writer, url, atau data pengukuran nil")
            return
        }
        
        // PERBAIKAN: Cek status writer sebelum finish
        guard writer.status == .writing else {
            print("Writer status: \(writer.status.rawValue), tidak bisa finish")
            if writer.status == .failed {
                print("Writer error: \(writer.error?.localizedDescription ?? "unknown")")
            }
            try? FileManager.default.removeItem(at: url)
            videoWriter = nil
            videoWriterInput = nil
            return
        }
        
        videoWriterInput?.markAsFinished()
        
        writer.finishWriting { [weak self] in
            guard let self = self else { return }
            
            self.videoWriter = nil
            self.videoWriterInput = nil
            
            DispatchQueue.main.async {
                if writer.status == .completed {
                    print("✅ Video berhasil disimpan di: \(url)")
                    self.delegate?.didCaptureVideo(videoURL: url, measurements: measurements)
                    self.dismiss(animated: true)
                    if let sizeFormatted = self.getVideoSize(at: url)?.formatted {
                        print("📊 Video ready: \(sizeFormatted)")
                    }
                    
                    // Optional: Encode to Base64 now (e.g., for immediate upload/debug)
                    if let base64 = self.encodeVideoToBase64(at: url) {
                        print("✅ Base64 ready: \(base64.prefix(50))...")  // Log first 50 chars
                        // TODO: Send base64 to server, e.g., via API call
                    }
                } else {
                    print("❌ Gagal menyimpan video: \(writer.error?.localizedDescription ?? "unknown error")")
                    self.showFeedback("Gagal menyimpan video", color: .systemRed)
                    try? FileManager.default.removeItem(at: url)
                }
                self.overlayView.hideStencil()
            }
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput,
                      didOutput sampleBuffer: CMSampleBuffer,
                      from connection: AVCaptureConnection) {
        if isRecording {
            // Jika writer belum di-setup, setup sekarang
            if videoWriter == nil && !isSettingUpWriter {
                isSettingUpWriter = true
                setupVideoWriter(with: sampleBuffer)
                isSettingUpWriter = false
            }
            
            // Pastikan writer sudah siap dan dalam status writing
            guard let writerInput = videoWriterInput,
                    let writer = videoWriter,
                    writer.status == .writing,
                    writerInput.isReadyForMoreMediaData else {
                return
            }
            
            writerInput.append(sampleBuffer)
            return
        }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        
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
        
        let x = point.x * imageSize.width
        let y = (1.0 - point.y) * imageSize.height
        
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
            
            // 2. Validasi badan dulu harus full body terlihat
            let bodyHeight = abs(neck.y - ((leftHip.y + rightHip.y) / 2))
            
            print("🔍 DEBUG - Body Height: \(String(format: "%.3f", bodyHeight))")
            
            if bodyHeight < 0.2 {
                validPoseCount = 0
                showFeedback("📏 Maju sedikit agar Posisi lebih pas", color: .systemYellow)
                showValidPoseIndicator(false)
                return
            }
            
            if bodyHeight > 0.24 {
                validPoseCount = 0
                showFeedback("📏 Mundur sedikit agar seluruh tubuh terlihat", color: .systemBlue)
                showValidPoseIndicator(false)
                return
            }
            
            // 3. Kedua tangan harus melentang lebar
            let armSpanX = abs(leftWrist.x - rightWrist.x)
            
            // DEBUG
            print("DEBUG - Arm Span X: \(String(format: "%.3f", armSpanX)) (\(Int(armSpanX * 100))%)")
            print("DEBUG - Left Wrist X: \(String(format: "%.3f", leftWrist.x))")
            print("DEBUG - Right Wrist X: \(String(format: "%.3f", rightWrist.x))")
            print("DEBUG - Shoulder Width X: \(String(format: "%.3f", abs(leftShoulder.x - rightShoulder.x)))")
            
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
            
            validPoseCount += 1
            showValidPoseIndicator(true)
            
            let progressPercent = Int((Float(validPoseCount) / Float(requiredValidFrames)) * 100)
            showFeedback("✅ Pose sempurna! (\(progressPercent)%)\nTahan posisi...", color: .systemGreen)
            
            if validPoseCount >= requiredValidFrames {
                
                guard !isRecording else { return }
                            
                isRecording = true
                
                measurementsToSave = BodyMeasurements(
                    armSpan: armSpanX * previewLayer.bounds.width,
                    shoulderWidth: abs(leftShoulder.x - rightShoulder.x) * previewLayer.bounds.width,
                    torsoLength: bodyHeight * previewLayer.bounds.height
                )
                
                DispatchQueue.main.async {
                    self.showFeedback("✅ TAHAN POSISI...\nMerekam 2 detik", color: .systemGreen)
                    self.recordingTimer?.invalidate()
                    self.recordingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
                        self?.stopRecording()
                    }
                }
            }
            
        } catch {
            validPoseCount = 0
            showFeedback("Error deteksi pose", color: .systemRed)
            showValidPoseIndicator(false)
        }
    }

    
    private func calculateArmAngle(shoulder: VNRecognizedPoint, wrist: VNRecognizedPoint) -> CGFloat {

        let deltaX = wrist.x - shoulder.x
        let deltaY = wrist.y - shoulder.y

        let angleRadians = atan2(deltaY, deltaX)
        let angleDegrees = angleRadians * 180 / .pi

        return angleDegrees
    }

}
