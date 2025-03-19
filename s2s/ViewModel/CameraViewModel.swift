//
//  CameraViewModel.swift
//  Snap2Spoon
//
//  Created by Cory DeWitt on 11/2/24.
//

import SwiftUI
import AVFoundation

@MainActor
class CameraViewModel: ObservableObject {
    @Published var photo: UIImage?
    @Published var showPermissionAlert = false
    @Published var showCameraError = false
    @Published var isReady = false
    @Published var errorMessage = ""
    
    private let captureService = CaptureService()
    private var session: AVCaptureSession?
    
    var captureSession: AVCaptureSession {
        session ?? AVCaptureSession()
    }
    
    func initialize() async {
        do {
            if await captureService.checkAuthorization() {
                try await captureService.setupSession()
                session = await captureService.getSession()
                isReady = true
            } else {
                showPermissionAlert = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showCameraError = true
        }
    }
    
    func capturePhoto() async throws {
        do {
            photo = try await captureService.capturePhoto()
            LoadingPageView()
        } catch {
            errorMessage = error.localizedDescription
            showCameraError = true
            throw error
        }
    }

}

