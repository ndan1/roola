//
//  UserProfileViewModel.swift
//  Roola
//
//  Created by Lin Dan Christiano on 08/11/25.
//

import Foundation
import SwiftUI
import AVFoundation

// Definisikan alur navigasi di sini
enum CameraFlowStep: Identifiable {
    case terms
    case tutorial
    case capture
    case permissionDenied
    
    var id: Self { self }
}

@MainActor
class UserProfileViewModel: ObservableObject {
    
    // MARK: - Published State
    
    // State untuk mengontrol alur fullScreenCover
    @Published var cameraFlowStep: CameraFlowStep? = nil
    
    // State untuk UI lainnya
    @Published var showingEditSheet = false
    @Published var capturedVideoURL: URL?

    // MARK: - Persisted State
    
    @AppStorage("hasSeenCameraTerms") private var hasSeenCameraTerms = false
    
    // MARK: - Public Functions (Dipanggil oleh View)

    /// Fungsi ini dipanggil oleh tombol "Scan Body with Camera"
    func startCameraFlow() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        // Kondisi 1: Izin sudah ditolak.
        if status == .denied || status == .restricted {
            cameraFlowStep = .permissionDenied
        }
        // Kondisi 2: User belum pernah lihat terms (pertama kali)
        else if !hasSeenCameraTerms {
            cameraFlowStep = .terms
        }
        // Kondisi 3: User sudah lihat terms & izin sudah ada (langsung ke tutorial)
        else {
            cameraFlowStep = .tutorial
        }
    }
    
    // MARK: - Logic Alur (Dipanggil oleh View buildView)
    
    /// Dipanggil saat 'Terms' selesai
    func didFinishTerms() {
        self.hasSeenCameraTerms = true
        
        // Minta izin kamera
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    self.cameraFlowStep = .tutorial // Lanjut ke tutorial
                } else {
                    self.cameraFlowStep = nil // Ditolak, tutup sheet
                }
            }
        }
    }
    
    /// Dipanggil saat 'Tutorial' selesai
    func didFinishTutorial() {
        self.cameraFlowStep = .capture
    }
    
    /// Dipanggil saat 'Capture' selesai
    func didFinishCapture(videoURL: URL, measurements: BodyMeasurements) {
        self.capturedVideoURL = videoURL
        print("Captured! Arm span: \(measurements.armSpan)")
        self.cameraFlowStep = nil // Selesai, tutup alur
    }
    
    /// Dipanggil saat 'Permission Denied' dibatalkan
    func didCancelPermissionView() {
        self.cameraFlowStep = nil
    }
    
    /// Dipanggil saat user ingin membuka settings
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        self.cameraFlowStep = nil
    }
}
