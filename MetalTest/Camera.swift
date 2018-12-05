//
//  Camera.swift
//  MetalTest
//
//  Created by s.kananat on 2018/12/05.
//  Copyright © 2018 s.kananat. All rights reserved.
//

import AVFoundation

// MARK: Main
public class Camera: NSObject {
    
    /// Capture session
    private let session: AVCaptureSession = {
        let session = AVCaptureSession()
        
        if session.canSetSessionPreset(.hd1280x720) { session.sessionPreset = .hd1280x720 }
        else if session.canSetSessionPreset(.high) { session.sessionPreset = .high }
            
        return session
    }()
    
    /// Capture session input
    private let input: AVCaptureInput
    
    /// Capture session output
    private lazy var output: AVCaptureOutput = {
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: Camera.dispatchQueue)
        output.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA]
        
        return output
    }()
    
    init?(position: AVCaptureDevice.Position = .back) {

        // Requests access to camera
        var granted = true
        
        AVCaptureDevice.requestAccess(for: .video) { granted = $0 }
        
        guard granted else { return nil }

        // Discovers capture input devices
        let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: position).devices
        
        guard devices.count > 0 else { return nil }
        
        guard let input = try? AVCaptureDeviceInput(device: devices[0]) else { return nil }

        self.input = input
        
        super.init()
        
        // Begin atomic operation
        self.session.beginConfiguration()
        
        // Add input to session
        guard self.session.canAddInput(input) else { return nil }
        
        self.session.addInput(input)

        // Add output to session
        guard self.session.canAddOutput(self.output) else { return nil }
        
        self.session.addOutput(output)
        
        // Finish atomic operation
        self.session.commitConfiguration()
        
        // Start running
        self.session.startRunning()
    }
    
    deinit {
        self.session.stopRunning()
    }
}

// MARK: Protocol
extension Camera: AVCaptureVideoDataOutputSampleBufferDelegate {

    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    }
}

// MARK: Private
private extension Camera {
    
    /// Dispatch queue for camera session
    static let dispatchQueue = DispatchQueue(label: "CameraCaptureSession")
}
