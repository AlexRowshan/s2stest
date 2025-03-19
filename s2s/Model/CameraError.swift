//
//  CameraError.swift
//  s2s
//
//  Created by Cory DeWitt on 2/13/25.
//

enum CameraError: Error {
    case deviceNotFound
    case inputError
    case outputError
    case captureError
    case authorizationDenied
}
 
