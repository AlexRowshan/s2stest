//
//  PhotoCaptureDelegate.swift
//  Snap2Spoon
//
//  Created by Cory DeWitt on 11/2/24.
//

import AVFoundation
import UIKit

class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    var onComplete: ((Result<UIImage, Error>) -> Void)?
    private var hasCompleted = false
    
    override init() {
        super.init()
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput,
                    didFinishProcessingPhoto photo: AVCapturePhoto,
                    error: Error?) {
        
        guard !hasCompleted else { return }
        hasCompleted = true
        
        if let error = error {
            onComplete?(.failure(error))
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            onComplete?(.failure(CameraError.captureError))
            return
        }
        
        onComplete?(.success(image))
    }
}
