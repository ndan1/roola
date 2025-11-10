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
    private var isCountingDown = false
    private var videoWriter: AVAssetWriter?
    private var videoWriterInput: AVAssetWriterInput?
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
    
    // MARK: - Feedback (GUARDED)
    private func showFeedback(_ message: String, color: UIColor = .systemOrange) {
        guard !isCountingDown && !isRecording else { return }
        overlayView.showFeedback(message, color: color)
    }
    
    private func showValidPoseIndicator(_ show: Bool) {
        guard !isCountingDown && !isRecording else { return }
        overlayView.showValidPoseIndicator(show)
        overlayView.setStencil(image: show ? stencilImageB : stencilImageA)
    }
    
    @objc private func handleBackButton() {
        print("Back tapped")
        cancelRecording()
        validPoseCount = 0
        dismiss(animated: true)
    }
    
    private func cancelRecording() {
        isRecording = false
        isCountingDown = false
        isSettingUpWriter = false
        
        videoWriterInput?.markAsFinished()
        videoWriter?.cancelWriting()
        videoWriter = nil
        videoWriterInput = nil
        
        if let url = videoURLToSave {
            try? FileManager.default.removeItem(at: url)
        }
        videoURLToSave = nil
        measurementsToSave = nil
    }
}

// MARK: - Video Capture Delegate
extension PoseCaptureViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    private func setupVideoWriter(with buffer: CMSampleBuffer) {
        guard let formatDesc = CMSampleBufferGetFormatDescription(buffer) else {
            print("Error: No format description")
            isRecording = false
            return
        }
        let dimensions = CMVideoFormatDescriptionGetDimensions(formatDesc)
        
        let fileName = "poseVideo-\(UUID().uuidString).mp4"
        let videoURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        videoURLToSave = videoURL
        
        do {
            videoWriter = try AVAssetWriter(url: videoURL, fileType: .mp4)
        } catch {
            print("Error creating AVAssetWriter: \(error)")
            isRecording = false
            return
        }
        
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(dimensions.width),
            AVVideoHeightKey: Int(dimensions.height)
        ]
        
        videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoWriterInput?.expectsMediaDataInRealTime = true
        videoWriterInput?.transform = CGAffineTransform(rotationAngle: .pi / 2)
        
        if let input = videoWriterInput, videoWriter!.canAdd(input) {
            videoWriter!.add(input)
        } else {
            print("Error adding input")
            isRecording = false
            return
        }
        
        videoWriter?.startWriting()
        
        guard videoWriter?.status == .writing else {
            print("Failed to start writing: \(videoWriter?.error?.localizedDescription ?? "")")
            isRecording = false
            try? FileManager.default.removeItem(at: videoURL)
            videoURLToSave = nil
            return
        }
        
        let startTime = CMSampleBufferGetPresentationTimeStamp(buffer)
        videoWriter?.startSession(atSourceTime: startTime)
        print("Video writer setup complete")
    }
    
    @objc private func stopRecording() {
        guard let writer = videoWriter,
              let url = videoURLToSave,
              measurementsToSave != nil else {
            print("Stop failed: missing data")
            resetCaptureState()
            return
        }
        
        guard !isRecording && !isCountingDown else {
            print("Stop already in progress")
            return
        }
        
        guard writer.status == .writing else {
            print("Writer not writing: \(writer.status.rawValue)")
            try? FileManager.default.removeItem(at: url)
            resetCaptureState()
            return
        }
        
        videoWriterInput?.markAsFinished()
        
        writer.finishWriting { [weak self] in
            guard let self = self else { return }
            self.videoWriter = nil
            self.videoWriterInput = nil
            
            DispatchQueue.main.async {
                if writer.status == .completed,
                   let url = self.videoURLToSave,
                   let sizeInfo = self.getVideoSize(at: url),
                   sizeInfo.bytes > 1024 {
                    
                    print("Video saved: \(sizeInfo.formatted)")
                    
                    // DELEGATE FIRST (instant)
                    self.delegate?.didCaptureVideo(videoURL: url, measurements: self.measurementsToSave!)
                    
                    // THEN success animation
                    self.overlayView.showSuccessCloseAnimation {
                        print("Success animation done")
                    }
                    
                } else {
                    let msg = writer.error?.localizedDescription ?? "Unknown error"
                    self.handleRecordingFailure(url: url, message: msg)
                }
            }
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // STOP ALL PROCESSING DURING COUNTDOWN OR RECORDING
        if isCountingDown || isRecording {
            if isRecording {
                // Setup writer on first frame
                if videoWriter == nil && !isSettingUpWriter {
                    isSettingUpWriter = true
                    setupVideoWriter(with: sampleBuffer)
                }
                
                // Append frame
                if let input = videoWriterInput,
                   let writer = videoWriter,
                   writer.status == .writing,
                   input.isReadyForMoreMediaData {
                    input.append(sampleBuffer)
                }
            }
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
            
            // Confidence
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
            
            // Body height
            let bodyHeight = abs(neck.y - ((leftHip.y + rightHip.y) / 2))
            if bodyHeight < 0.16 || bodyHeight > 0.20 {
                validPoseCount = 0
                showValidPoseIndicator(false)
                return
            }
            
            // Arm span
            let armSpanX = abs(leftWrist.x - rightWrist.x)
            if armSpanX < 0.40 || armSpanX > 0.90 {
                validPoseCount = 0
                showValidPoseIndicator(false)
                return
            }
            
            // Arm angles
            let leftAngle = calculateArmAngle(shoulder: leftShoulder, wrist: leftWrist)
            let rightAngle = calculateArmAngle(shoulder: rightShoulder, wrist: rightWrist)
            let leftValid = leftAngle > -70 && leftAngle < -20
            let rightValid = rightAngle > -160 && rightAngle < -110
            if !leftValid || !rightValid {
                validPoseCount = 0
                showValidPoseIndicator(false)
                return
            }
            
            // Symmetry
            let ySymmetry = abs(leftWrist.y - rightWrist.y)
            if ySymmetry > 0.08 {
                validPoseCount = 0
                showValidPoseIndicator(false)
                return
            }
            
            validPoseCount += 1
            showValidPoseIndicator(true)
            showFeedback("Hold Still", color: UIColor(AppColors.primaryPurple))
            
            // TRIGGER CAPTURE
            if validPoseCount >= requiredValidFrames {
                guard !isRecording && !isCountingDown else { return }
                
                isCountingDown = true
                validPoseCount = 0
                isSettingUpWriter = false
                
                // Save measurements
                let shoulderWidth = abs(leftShoulder.x - rightShoulder.x)
                measurementsToSave = BodyMeasurements(
                    armSpan: armSpanX * previewLayer.bounds.width,
                    shoulderWidth: shoulderWidth * previewLayer.bounds.width,
                    torsoLength: bodyHeight * previewLayer.bounds.height
                )
                
                // START COUNTDOWN + RECORDING
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    self.showFeedback("Hold Still", color: UIColor(AppColors.primaryPurple))
                    
                    self.overlayView.startCountdown {
                        print("Countdown UI finished")
                    }
                    
                    // Start recording at "2"
                    Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { _ in
                        guard self.isCountingDown else { return }
                        print("Recording STARTED")
                        self.isRecording = true
                    }
                    
                    // Stop after 2.7s (duration of "2" + "1")
                    Timer.scheduledTimer(withTimeInterval: 3.1, repeats: false) { _ in
                        guard self.isCountingDown else { return }
                        print("Recording STOPPED")
                        self.isRecording = false
                        self.isCountingDown = false
                        self.isSettingUpWriter = false
                        self.stopRecording()
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
        let radians = atan2(deltaY, deltaX)
        return radians * 180 / .pi
    }

    
    private func handleRecordingFailure(url: URL?, message: String) {
        print("Recording failed: \(message)")
        if let url = url {
            try? FileManager.default.removeItem(at: url)
        }
        showFeedback("Gagal merekam video", color: .systemRed)
        resetCaptureState()
    }
    
    private func resetCaptureState() {
        isRecording = false
        isCountingDown = false
        isSettingUpWriter = false
        validPoseCount = 0
        measurementsToSave = nil
        videoURLToSave = nil
    }
}
