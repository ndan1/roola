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
    private var isCountingDown = false // <-- NEW: Prevent multiple triggers
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
        
        overlayView.onBackTapped = { [weak self] in
            self?.handleBackButton()
        }
        
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .medium
        
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

        // Keep stencil only
        if show {
            overlayView.setStencil(image: stencilImageB)
        } else {
            overlayView.setStencil(image: stencilImageA)
        }
    }
    
    @objc private func handleBackButton() {
        print("Tapped")
        // Cancel any recording
        if isRecording || isCountingDown {
            isRecording = false
            isCountingDown = false
            recordingTimer?.invalidate()
            recordingTimer = nil
            
            videoWriterInput?.markAsFinished()
            videoWriter?.cancelWriting()
            videoWriter = nil
            videoWriterInput = nil
            
            if let url = videoURLToSave {
                try? FileManager.default.removeItem(at: url)
            }
        }
        
        // Clean up
        validPoseCount = 0
        
        // Dismiss
        dismiss(animated: true)
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
        guard let writer = videoWriter,
              let url = videoURLToSave,
              let measurements = measurementsToSave else {
            print("Batal merekam: writer, url, atau data pengukuran nil")
            isRecording = false // Ensure state is reset
            isCountingDown = false
            return
        }
        
        // Ensure we only run this once
        guard isRecording == false && isCountingDown == false else {
            print("Stop recording already called or in progress.")
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
                    print("Video saved at: \(url)")
                        
                    // Add delay for file flush (0.1-0.5s)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        // This is the verification step
                        if let sizeInfo = self.getVideoSize(at: url) {
                            print("Video size: \(sizeInfo.formatted)")
                            
                            // Verification: Check if file is not empty
                            if sizeInfo.bytes > 0 {
                                // Optional: Log Base64 for debugging, but don't block
                                if let base64 = self.encodeVideoToBase64(at: url) {
                                    print("Base64 ready: \(base64.prefix(50))...")
                                } else {
                                    print("Encoding failed, but file exists.")
                                }

                                // 1. Call delegate (to "new view" for API call)
                                self.delegate?.didCaptureVideo(videoURL: url, measurements: measurements)
                                
                                // 2. Show success and dismiss this view
                                self.overlayView.showSuccessCloseAnimation {
//                                    self.dismiss(animated: true)
                                }
                                
                            } else {
                                print("Encoding failed: File empty or invalid")
                                self.showFeedback("Gagal menyimpan video", color: .systemRed)
                                try? FileManager.default.removeItem(at: url)
                            }
                        } else {
                            print("File size check failed")
                            self.showFeedback("Gagal verifikasi video", color: .systemRed)
                            try? FileManager.default.removeItem(at: url)
                        }
                    }
                } else {
                    print("❌ Gagal menyimpan video: \(writer.error?.localizedDescription ?? "unknown error")")
                    self.showFeedback("Gagal menyimpan video", color: .systemRed)
                    try? FileManager.default.removeItem(at: url)
                }
            }
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if isRecording {
            // Check if writer needs setup
            if videoWriter == nil && !isSettingUpWriter {
                isSettingUpWriter = true // Set flag
                // Must setup writer on the same queue
                setupVideoWriter(with: sampleBuffer)
            }

            guard let writerInput = videoWriterInput,
                  let writer = videoWriter,
                  writer.status == .writing,
                  writerInput.isReadyForMoreMediaData else {
                return
            }

            // Append the buffer
            writerInput.append(sampleBuffer)
            return
        }
        
        // --- Pose detection logic (only if not recording) ---
        guard !isCountingDown, // Don't process poses if countdown is active
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        
        let request = VNDetectHumanBodyPoseRequest { [weak self] request, error in
            guard let observations = request.results as? [VNHumanBodyPoseObservation],
                  let observation = observations.first else {
                self?.validPoseCount = 0
//                self?.showFeedback("Pastikan tubuh terlihat jelas", color: .systemRed)
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
//                showFeedback("Pastikan seluruh tubuh terlihat", color: .systemOrange)
                showValidPoseIndicator(false)
                return
            }
            
            // 2. Validasi badan dulu harus full body terlihat
            let bodyHeight = abs(neck.y - ((leftHip.y + rightHip.y) / 2))
            
            print("🔍 DEBUG - Body Height: \(String(format: "%.3f", bodyHeight))")
            
            if bodyHeight < 0.16 {
                validPoseCount = 0
//                showFeedback("📏 Maju sedikit agar Posisi lebih pas", color: .systemYellow)
                showValidPoseIndicator(false)
                return
            }
            
            if bodyHeight > 0.20 {
                validPoseCount = 0
//                showFeedback("📏 Mundur sedikit agar seluruh tubuh terlihat", color: .systemBlue)
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
            
            // REQUIREMENT: Arm span minimal
            let minArmSpanX: CGFloat = 0.40
            let maxArmSpanX: CGFloat = 0.90
            
            if armSpanX < minArmSpanX {
                validPoseCount = 0
//                showFeedback("🙆‍♂️ Rentangkan kedua lengan lebih lebar ke samping\n(Jarak: \(Int(armSpanX * 100))% dari lebar)", color: .systemYellow)
                showValidPoseIndicator(false)
                return
            } else if armSpanX > maxArmSpanX {
                validPoseCount = 0
//                showFeedback("📏 Terlalu lebar, rapatkan sedikit", color: .systemYellow)
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
//                showFeedback("⬇️ Posisikan lengan 45° ke bawah\n(Bentuk 'A')", color: .systemOrange)
                showValidPoseIndicator(false)
                return
            }
            
            // 4. VALIDASI SYMMETRY - Kedua tangan harus setinggi/sejajar
            let ySymmetry = abs(leftWrist.y - rightWrist.y)
            let maxYAsymmetry: CGFloat = 0.08
            
            print("🔍 DEBUG - Y Symmetry: \(String(format: "%.3f", ySymmetry))")
            
            if ySymmetry > maxYAsymmetry {
                validPoseCount = 0
//                showFeedback("⚖️ Sejajarkan tinggi kedua tangan", color: .systemOrange)
                showValidPoseIndicator(false)
                return
            }
            
            validPoseCount += 1
            showValidPoseIndicator(true)
            
            showFeedback("Hold Still", color: UIColor(AppColors.primaryPurple))
            
            if validPoseCount >= requiredValidFrames {
                guard !isRecording && !isCountingDown else { return }
                
                isCountingDown = true

                // Save measurements immediately
                measurementsToSave = BodyMeasurements(
                    armSpan: armSpanX * previewLayer.bounds.width,
                    shoulderWidth: abs(leftShoulder.x - rightShoulder.x) * previewLayer.bounds.width,
                    torsoLength: bodyHeight * previewLayer.bounds.height
                )

                // =================================================================
                // MARK: - UPDATED CAPTURE LOGIC
                // =================================================================
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.showFeedback("Hold Still", color: UIColor(AppColors.primaryPurple))

                    // 1. Start the countdown UI.
                    // The completion block from the overlay runs *after* the "Recording..." text fades.
                    // We will not use it to stop recording.
                    self.overlayView.startCountdown {
                        // This block is called when the overlay's full animation is done.
                        // By this time, stopRecording() will have already been called by our timer.
                        print("Overlay countdown animation finished.")
                    }

                    // 2. Schedule START recording
                    // "3" (pose confirm) shows for 0.4s.
                    // Then "2" appears. We start recording *exactly* then.
                    let startTime = 0.4
                    Timer.scheduledTimer(withTimeInterval: startTime, repeats: false) { [weak self] _ in
                        guard let self = self, self.isCountingDown else { return }
                        print("TIMER: STARTING RECORDING (at '2')")
                        self.isRecording = true
                        // self.isSettingUpWriter is set to false initially
                        // The captureOutput delegate will now see isRecording=true
                        // and will trigger setupVideoWriter on the next available frame.
                    }
                    
                    // 3. Schedule STOP recording
                    // "2" shows for 1.35s (0.35s anim + 1.0s pause)
                    // "1" shows for 1.35s (0.35s anim + 1.0s pause)
                    // Total recording time for "2" and "1" = 2.7s
                    // Stop time = 0.4s (for "3") + 2.7s (for "2" & "1") = 3.1s
                    // This is exactly when "Recording..." text appears.
                    let stopTime = 3.1
                    Timer.scheduledTimer(withTimeInterval: stopTime, repeats: false) { [weak self] _ in
                        guard let self = self, self.isCountingDown else { return }
                        print("TIMER: STOPPING RECORDING (at 'Recording...' text)")
                        
                        // Set flags to stop processing
                        self.isRecording = false
                        self.isCountingDown = false
                        self.isSettingUpWriter = false // Prevent setup if it hasn't happened
                        
                        // Call stopRecording, which handles verification, delegate call, and dismiss
                        self.stopRecording()
                    }
                }
                return
                // =================================================================
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
    
    private func setupVideoWriterAndStart() {
        // This function is no longer needed, logic is moved to captureOutput
        // We just set isRecording = true, and captureOutput handles the rest.
        // We do need to reset the isSettingUpWriter flag
        isSettingUpWriter = false
    }
}
