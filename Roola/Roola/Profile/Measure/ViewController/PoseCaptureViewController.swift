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

// MARK: - Feedback State Enum (Improved Copy)
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
    
    // Text shown on screen (Concise)
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
    
    // Text spoken by TTS (Natural & Polite)
    var spokenMessage: String {
        switch self {
        case .none: return ""
        case .noPerson: return "I can't see you clearly."
        case .tooClose: return "Please step back a bit."
        case .tooFar: return "Step forward closer to the camera."
        case .handsTooClose: return "Stretch your arms out wider."
        case .handsTooWide: return "Lower your hands just a little."
        case .badAngles: return "Lift your arms to shoulder height."
        case .notSymmetrical: return "Try to keep your arms level."
        case .success: return "Perfect. Hold that pose."
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
    private let errorSpeechDelay: TimeInterval = 1.0 // Slower for errors (less annoying)
    
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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
            // Enhanced Samantha is usually the most natural built-in voice
            let voice = AVSpeechSynthesisVoice(identifier: "com.apple.voice.enhanced.en-US.Samantha")
                ?? AVSpeechSynthesisVoice(language: "en-US")
            DispatchQueue.main.async { self?.cachedVoice = voice }
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
    
    // MARK: - State Management (Smoother)
    private func updateState(_ newState: PoseFeedbackState) {
        // 1. Visuals: Update immediately for responsiveness
        if !isCountingDown && !isCapturingPhoto {
            overlayView.showFeedback(newState.message)
            
            let isValid = (newState == .success)
            overlayView.showValidPoseIndicator(isValid)
            overlayView.setStencil(image: isValid ? stencilImageB : stencilImageA)
        }
        
        // 2. TTS: Logic to reduce annoyance
        if newState != currentFeedbackState {
            
            // If we fall out of success, cancel countdown immediately
            if currentFeedbackState == .success && newState != .success {
                resetCountdownState()
            }
            
            currentFeedbackState = newState
            
            // Kill any pending speech so we don't say old errors
            speechDebounceTimer?.invalidate()
            
            if newState != .none && !isCountingDown && !isCapturingPhoto {
                
                // CASE A: Success -> Speak IMMEDIATELY
                if newState == .success {
                    speak(newState.spokenMessage)
                }
                // CASE B: Error -> Wait (Debounce) to see if user settles
                else {
                    speechDebounceTimer = Timer.scheduledTimer(withTimeInterval: errorSpeechDelay, repeats: false) { [weak self] _ in
                        guard let self = self else { return }
                        // Ensure state hasn't changed during the delay
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
        
        // Clear visuals
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
        
        // This takes a split second, so we trigger it exactly when countdown ends
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    private func calculateArmAngle(shoulder: VNRecognizedPoint, wrist: VNRecognizedPoint) -> CGFloat {
        let deltaX = wrist.x - shoulder.x
        let deltaY = wrist.y - shoulder.y
        return atan2(deltaY, deltaX) * 180 / .pi
    }
}

// MARK: - Vision Processing & Hysteresis
extension PoseCaptureViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // We DO process during countdown now to ensure they stay still
        guard !isCapturingPhoto else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNDetectHumanBodyPoseRequest { [weak self] request, error in
            guard let self = self else { return }
            
            guard let observations = request.results as? [VNHumanBodyPoseObservation],
                  let observation = observations.first else {
                DispatchQueue.main.async { self.updateState(.noPerson) }
                return
            }
            
            // Analyze Logic
            let detectedState = self.analyzePose(observation)
            
            DispatchQueue.main.async {
                self.handlePoseState(detectedState, observation: observation)
            }
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .leftMirrored, options: [:])
        try? handler.perform([request])
    }
    
    // Returns the calculated state of the body
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
            
            // --- HYSTERESIS / STICKY LOGIC ---
            // If we are currently successful, we widen the acceptable ranges slightly.
            // This prevents "jittering" between Success and Error states when on the edge.
            let isAlreadySuccess = (currentFeedbackState == .success)
            
            // 2. Height Check (Distance)
            let bodyHeight = abs(neck.y - ((leftHip.y + rightHip.y) / 2))
            
            let minHeight: CGFloat = isAlreadySuccess ? 0.15 : 0.16
            let maxHeight: CGFloat = isAlreadySuccess ? 0.21 : 0.20
            
            if bodyHeight > maxHeight { return .tooClose }
            if bodyHeight < minHeight { return .tooFar }
            
            // 3. Arm Span Check
            let armSpanX = abs(leftWrist.x - rightWrist.x)
            let minSpan: CGFloat = isAlreadySuccess ? 0.38 : 0.40
            let maxSpan: CGFloat = isAlreadySuccess ? 0.92 : 0.90 // Allow 0.92 if already holding it
            
            if armSpanX < minSpan { return .handsTooClose }
            if armSpanX > maxSpan { return .handsTooWide }
            
            // 4. Angle Check (T-Pose)
            let leftAngle = calculateArmAngle(shoulder: leftShoulder, wrist: leftWrist)
            let rightAngle = calculateArmAngle(shoulder: rightShoulder, wrist: rightWrist)
            
            // Allow 5 degrees extra variance if already success
            let variance: CGFloat = isAlreadySuccess ? 5.0 : 0.0
            
            // Left: -70 to -20
            let lValid = leftAngle > (-70 - variance) && leftAngle < (-20 + variance)
            // Right: -160 to -110
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
                resetCountdownState() // User moved during countdown!
            }
        }
        
        // Trigger Countdown if stable
        if validPoseCount >= requiredValidFrames && !isCountingDown && !isCapturingPhoto {
            startCountdownSequence(observation: observation)
        }
    }
    
    private func startCountdownSequence(observation: VNHumanBodyPoseObservation) {
        speechDebounceTimer?.invalidate()
        isCountingDown = true
        validPoseCount = 0
        
        saveMeasurements(observation)
        
        // Only say "Hold still" once at the start
        speak("Hold still")
        
        // Start UI Countdown
        overlayView.startCountdown { [weak self] in
            guard let self = self, self.isCountingDown else { return }
            
            // INSTANT CAPTURE:
            // The overlay callback now fires exactly when "1" appears/finishes.
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
