//
//  PoseCaptureViewController.swift
//  Roola
//
//  Created by Lin Dan Christiano on 29/10/25.
//

import UIKit
import AVFoundation
import Vision

// MARK: - Delegate Protocol
protocol PoseCaptureDelegate: AnyObject {
    func didCapture(image: UIImage, measurements: BodyMeasurements)
}

struct BodyMeasurements {
    let armSpan: CGFloat
    let shoulderWidth: CGFloat
    let torsoLength: CGFloat
}

// MARK: - Feedback State Enum
enum PoseFeedbackState: Equatable {
    case none
    case noPerson
    case tooClose
    case tooFar
    case handsTooClose
    case handsTooWide
    case badAngles
    case notSymmetrical
    case success
    
    // Text shown on screen
    var message: String {
        switch self {
        case .none: return ""
        case .noPerson: return "No person detected"
        case .tooClose: return "Move backwards"
        case .tooFar: return "Move forward"
        case .handsTooClose: return "Lift your arms"
        case .handsTooWide: return "Lower hands slightly"
        case .badAngles: return "Adjust arm angle"
        case .notSymmetrical: return "Level your arms"
        case .success: return "Hold still"
        }
    }
    
    // Text spoken by TTS
    var spokenMessage: String {
        switch self {
        case .none: return ""
        case .noPerson: return "Make sure all body parts is seen on camera"
        case .tooClose: return "Please move backwards"
        case .tooFar: return "Please move forward"
        case .handsTooClose: return "Lift your arm to the side"
        case .handsTooWide: return "Lower your hands just a little."
        case .badAngles: return "Lift your arms to shoulder height."
        case .notSymmetrical: return "Try to keep your arms level."
        case .success: return "Hold still for a few seconds"
        }
    }
}

class PoseCaptureViewController: UIViewController {
    
    // MARK: - Properties
    weak var delegate: PoseCaptureDelegate?
    var onBackButtonTapped: (() -> Void)?
    
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    
    private var overlayView: PoseValidationOverlay!
    
    // State Flags
    private var isCapturingPhoto = false
    private var isCountingDown = false
    private var measurementsToSave: BodyMeasurements?
    
    private var validPoseCount = 0
    private let requiredValidFrames = 15
    
    // The current state
    private var currentFeedbackState: PoseFeedbackState = .none
    
    // TTS Debounce
    private var speechDebounceTimer: Timer?
    private let errorSpeechDelay: TimeInterval = 1.0
    
    private lazy var stencilImageA: UIImage? = UIImage(named: "red_stencil")
    private lazy var stencilImageB: UIImage? = UIImage(named: "green_stencil")
    
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var cachedVoice: AVSpeechSynthesisVoice?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupAudioSession()
        configureVoice()
        setupCamera()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
        captureSession?.stopRunning()
        stopSpeaking()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .black
        overlayView = PoseValidationOverlay(frame: view.bounds)
        overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(overlayView)
        overlayView.onBackTapped = { [weak self] in self?.handleBackButton() }
    }
    
    private func setupAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    private func configureVoice() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let voices = AVSpeechSynthesisVoice.speechVoices()
            let samanthaVoice = voices.first { $0.name == "Samantha" }
            let finalVoice = samanthaVoice ?? AVSpeechSynthesisVoice(language: "en-US")
            
            DispatchQueue.main.async {
                self?.cachedVoice = finalVoice
            }
        }
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else { return }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) { captureSession.addInput(input) }
            
            videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            if captureSession.canAddOutput(videoDataOutput) { captureSession.addOutput(videoDataOutput) }
            
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
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
        } catch { print("Camera error: \(error)") }
    }
    
    // MARK: - State Management
    private func updateState(_ newState: PoseFeedbackState) {
        if !isCountingDown && !isCapturingPhoto {
            overlayView.showFeedback(newState.message)
            
            let isValid = (newState == .success)
            overlayView.showValidPoseIndicator(isValid)
            overlayView.setStencil(image: isValid ? stencilImageB : stencilImageA)
        }
        
        if newState != currentFeedbackState {
            if currentFeedbackState == .success && newState != .success {
                resetCountdownState()
            }
            
            currentFeedbackState = newState
            speechDebounceTimer?.invalidate()
            
            if newState != .none && !isCountingDown && !isCapturingPhoto {
                if newState == .success {
                    speak(newState.spokenMessage)
                } else {
                    speechDebounceTimer = Timer.scheduledTimer(withTimeInterval: errorSpeechDelay, repeats: false) { [weak self] _ in
                        guard let self = self else { return }
                        if self.currentFeedbackState == newState && !self.isCountingDown {
                            self.speak(newState.spokenMessage)
                        }
                    }
                }
            }
        }
    }
    
    private func resetCountdownState() {
        isCountingDown = false
        validPoseCount = 0
        stopSpeaking()
        DispatchQueue.main.async {
            self.overlayView.cancelCountdown()
        }
    }
    
    private func speak(_ text: String) {
        if speechSynthesizer.isSpeaking { speechSynthesizer.stopSpeaking(at: .immediate) }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = cachedVoice
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.95
        utterance.pitchMultiplier = 1.05
        utterance.volume = 1.0
        
        speechSynthesizer.speak(utterance)
    }
    
    private func stopSpeaking() {
        speechDebounceTimer?.invalidate()
        if speechSynthesizer.isSpeaking { speechSynthesizer.stopSpeaking(at: .immediate) }
    }
    
    // MARK: - Actions
    @objc private func handleBackButton() {
        cancelCapture()
        onBackButtonTapped?()
    }
    
    private func cancelCapture() {
        resetCountdownState()
        isCapturingPhoto = false
        measurementsToSave = nil
    }
    
    private func takePhoto() {
        guard let connection = photoOutput.connection(with: .video) else { return }
        connection.videoRotationAngle = 90
        
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    private func calculateArmAngle(shoulder: VNRecognizedPoint, wrist: VNRecognizedPoint) -> CGFloat {
        let deltaX = wrist.x - shoulder.x
        let deltaY = wrist.y - shoulder.y
        return atan2(deltaY, deltaX) * 180 / .pi
    }
}

// MARK: - Vision Processing
extension PoseCaptureViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard !isCapturingPhoto else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNDetectHumanBodyPoseRequest { [weak self] request, error in
            guard let self = self else { return }
            
            guard let observations = request.results as? [VNHumanBodyPoseObservation],
                  let observation = observations.first else {
                DispatchQueue.main.async {
                    self.updateState(.noPerson)
                    self.overlayView.clearSkeleton()
                }
                return
            }
            
            // Analyze Logic
            let detectedState = self.analyzePose(observation)
            
            // Extract and convert points for overlay
            let skeletonPoints = self.extractSkeletonPoints(from: observation)
            
            DispatchQueue.main.async {
                self.handlePoseState(detectedState, observation: observation)
                self.overlayView.updateSkeleton(points: skeletonPoints)
            }
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .leftMirrored, options: [:])
        try? handler.perform([request])
    }
    
    private func extractSkeletonPoints(from observation: VNHumanBodyPoseObservation) -> [VNHumanBodyPoseObservation.JointName : CGPoint] {
        var points: [VNHumanBodyPoseObservation.JointName : CGPoint] = [:]
        
        let joints: [VNHumanBodyPoseObservation.JointName] = [
            .neck,
            .leftShoulder, .rightShoulder,
            .leftElbow, .rightElbow,
            .leftWrist, .rightWrist,
            .leftHip, .rightHip,
            .leftKnee, .rightKnee,
            .leftAnkle, .rightAnkle,
            .root
        ]
        
        let previewBounds = previewLayer.bounds
        
        for joint in joints {
            guard let recognizedPoint = try? observation.recognizedPoint(joint),
                  recognizedPoint.confidence > 0.3 else { continue }
            
            // Convert Vision normalized coordinates (bottom-left origin) to UIKit coordinates (top-left origin)
            let normalizedX = recognizedPoint.x
            let normalizedY = 1 - recognizedPoint.y
            
            let screenPoint = CGPoint(
                x: normalizedX * previewBounds.width,
                y: normalizedY * previewBounds.height
            )
            
            points[joint] = screenPoint
        }
        return points
    }
    
    private func analyzePose(_ observation: VNHumanBodyPoseObservation) -> PoseFeedbackState {
        do {
            let leftWrist = try observation.recognizedPoint(.leftWrist)
            let rightWrist = try observation.recognizedPoint(.rightWrist)
            let leftShoulder = try observation.recognizedPoint(.leftShoulder)
            let rightShoulder = try observation.recognizedPoint(.rightShoulder)
            let neck = try observation.recognizedPoint(.neck)
            let leftHip = try observation.recognizedPoint(.leftHip)
            let rightHip = try observation.recognizedPoint(.rightHip)
            let leftAnkle = try observation.recognizedPoint(.leftAnkle)
            let rightAnkle = try observation.recognizedPoint(.rightAnkle)
            
            // 1. Confidence Check
            let minConf: Float = 0.3
            guard leftWrist.confidence > minConf, rightWrist.confidence > minConf,
                  leftShoulder.confidence > minConf, rightShoulder.confidence > minConf,
                  neck.confidence > minConf, leftAnkle.confidence > 0.2,
                  rightAnkle.confidence > 0.2 else { return .noPerson }
            
            // Hysteresis
            let isAlreadySuccess = (currentFeedbackState == .success)
            
            // 2. Height Check
            let bodyHeight = abs(neck.y - ((leftHip.y + rightHip.y) / 2))
            let minHeight: CGFloat = isAlreadySuccess ? 0.15 : 0.16
            let maxHeight: CGFloat = isAlreadySuccess ? 0.21 : 0.20
            
            if bodyHeight > maxHeight { return .tooClose }
            if bodyHeight < minHeight { return .tooFar }
            
            // 3. Arm Span Check
            let armSpanX = abs(leftWrist.x - rightWrist.x)
            let minSpan: CGFloat = isAlreadySuccess ? 0.38 : 0.40
            let maxSpan: CGFloat = isAlreadySuccess ? 0.92 : 0.90
            
            if armSpanX < minSpan { return .handsTooClose }
            if armSpanX > maxSpan { return .handsTooWide }
            
            // 4. Angle Check
            let leftAngle = calculateArmAngle(shoulder: leftShoulder, wrist: leftWrist)
            let rightAngle = calculateArmAngle(shoulder: rightShoulder, wrist: rightWrist)
            
            let variance: CGFloat = isAlreadySuccess ? 5.0 : 0.0
            
            let lValid = leftAngle > (-70 - variance) && leftAngle < (-20 + variance)
            let rValid = rightAngle > (-160 - variance) && rightAngle < (-110 + variance)
            
            if !lValid || !rValid { return .badAngles }
            
            // 5. Symmetry Check
            if abs(leftWrist.y - rightWrist.y) > (isAlreadySuccess ? 0.10 : 0.08) { return .notSymmetrical }
            
            return .success
            
        } catch { return .noPerson }
    }
    
    private func handlePoseState(_ state: PoseFeedbackState, observation: VNHumanBodyPoseObservation) {
        updateState(state)
        
        if state == .success {
            validPoseCount += 1
        } else {
            validPoseCount = 0
            if isCountingDown {
                resetCountdownState()
            }
        }
        
        if validPoseCount >= requiredValidFrames && !isCountingDown && !isCapturingPhoto {
            startCountdownSequence(observation: observation)
        }
    }
    
    private func startCountdownSequence(observation: VNHumanBodyPoseObservation) {
        speechDebounceTimer?.invalidate()
        isCountingDown = true
        validPoseCount = 0
        
        saveMeasurements(observation)
        speak("Hold still")
        
        overlayView.startCountdown { [weak self] in
            guard let self = self, self.isCountingDown else { return }
            print("Countdown finished. Capturing immediately.")
            self.isCapturingPhoto = true
            self.isCountingDown = false
            self.takePhoto()
        }
    }
    
    private func saveMeasurements(_ observation: VNHumanBodyPoseObservation) {
        guard let leftWrist = try? observation.recognizedPoint(.leftWrist),
              let rightWrist = try? observation.recognizedPoint(.rightWrist),
              let leftShoulder = try? observation.recognizedPoint(.leftShoulder),
              let rightShoulder = try? observation.recognizedPoint(.rightShoulder),
              let neck = try? observation.recognizedPoint(.neck),
              let leftHip = try? observation.recognizedPoint(.leftHip),
              let rightHip = try? observation.recognizedPoint(.rightHip) else { return }
        
        measurementsToSave = BodyMeasurements(
            armSpan: abs(leftWrist.x - rightWrist.x) * previewLayer.bounds.width,
            shoulderWidth: abs(leftShoulder.x - rightShoulder.x) * previewLayer.bounds.width,
            torsoLength: abs(neck.y - ((leftHip.y + rightHip.y) / 2)) * previewLayer.bounds.height
        )
    }
}

// MARK: - Photo Output
extension PoseCaptureViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Capture Error: \(error)")
            resetCountdownState()
            return
        }
        guard let data = photo.fileDataRepresentation(), let img = UIImage(data: data) else { return }
        
        // Flip for front camera mirroring
        let finalImage = UIImage(cgImage: img.cgImage!, scale: img.scale, orientation: .leftMirrored)
        
        guard let measurements = measurementsToSave else { resetCountdownState(); return }
        
        DispatchQueue.main.async {
            self.overlayView.showSuccessCloseAnimation {
                self.delegate?.didCapture(image: finalImage, measurements: measurements)
            }
        }
    }
}
