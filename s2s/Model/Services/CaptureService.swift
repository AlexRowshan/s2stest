//
//  CaptureService.swift
//  Snap2Spoon
//
//  Created by Cory DeWitt on 11/2/24.
//

import AVFoundation
import UIKit

actor CaptureService {
    private let captureSession = AVCaptureSession()
    private var activeVideoInput: AVCaptureDeviceInput?
    private let photoOutput = AVCapturePhotoOutput()
    private var photoDelegate: PhotoCaptureDelegate?
    
    func getSession() -> AVCaptureSession {
        captureSession
    }
    
    func checkAuthorization() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        var isAuthorized = status == .authorized
        
        if status == .notDetermined {
            isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
        }
        return isAuthorized
    }
    
    func setupSession() async throws {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                 for: .video,
                                                 position: .back) else {
            throw CameraError.deviceNotFound
        }
        
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        
        let input = try AVCaptureDeviceInput(device: device)
        guard captureSession.canAddInput(input) else {
            throw CameraError.inputError
        }
        captureSession.addInput(input)
        activeVideoInput = input
        
        guard captureSession.canAddOutput(photoOutput) else {
            throw CameraError.outputError
        }
        captureSession.addOutput(photoOutput)
        
        Task.detached {
            await self.captureSession.startRunning()
        }
    }
    
    func capturePhoto() async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            let settings = AVCapturePhotoSettings()
            
            let delegate = PhotoCaptureDelegate()
            
            self.photoDelegate = delegate
            
            delegate.onComplete = { [weak self] result in
                Task {
                    await self?.clearDelegate()
                }
                
                switch result {
                case .success(let image):
                    continuation.resume(returning: image)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            self.photoOutput.capturePhoto(with: settings, delegate: delegate)
        }
    }
    
    private func clearDelegate() {
        self.photoDelegate = nil
    }
}
