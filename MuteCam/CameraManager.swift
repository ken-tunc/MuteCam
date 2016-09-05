//
//  CameraManager.swift
//  MuteCam
//
//  Created by ken_tunc on 2016/09/06.
//  Copyright © 2016年 ken_tunc. All rights reserved.
//

import AVFoundation
import UIKit

class CameraManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    private var vc: CameraViewController!
    private var session: AVCaptureSession!
    private var captureDevice: AVCaptureDevice!
    private var captureDeviceDiscoverySession: AVCaptureDeviceDiscoverySession!
    private var captureDeviceInput: AVCaptureDeviceInput!
    private var captureVideoDataOutput: AVCaptureVideoDataOutput!
    
    init(cameraViewController: CameraViewController) {
        vc = cameraViewController
    }
    
    func setupAVCapture() {
        session = AVCaptureSession()
        
        // Set quality for picture
        session.sessionPreset = AVCaptureSessionPresetHigh
        
        // Get back camera
        captureDeviceDiscoverySession = AVCaptureDeviceDiscoverySession.init(deviceTypes: [AVCaptureDeviceType.builtInWideAngleCamera], mediaType: nil, position: .back)
        for device in captureDeviceDiscoverySession.devices {
            captureDevice = device
        }
        
        // Get input from caputre device
        do {
            captureDeviceInput = try AVCaptureDeviceInput.init(device: captureDevice)
        } catch {
            captureDeviceInput = nil
            print("error: captureDeviceInput is nil")
        }
        
        // Add input to session
        if session.canAddInput(captureDeviceInput) {
            session.addInput(captureDeviceInput)
        }
        
        captureVideoDataOutput = AVCaptureVideoDataOutput()
        
        // Set output format
        captureVideoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable: Int(kCVPixelFormatType_32BGRA)]
        
        // Throw if queue is blocked during datat output
        captureVideoDataOutput.alwaysDiscardsLateVideoFrames = true
        
        // Serial queue for extracting frames
        captureVideoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        
        if session.canAddOutput(captureVideoDataOutput) {
            session.addOutput(captureVideoDataOutput)
        }
        
        // Change FPS
        do {
            try captureDevice.lockForConfiguration()
            captureDevice.activeVideoMinFrameDuration = CMTimeMake(1, 30)
            captureDevice.unlockForConfiguration()
        } catch {
            print("error: can't lock device")
        }
        
        session.startRunning()
    }
    
    func stopAVCapture() {
        session.stopRunning()
        
        for output in session.outputs {
            session.removeOutput(output as? AVCaptureOutput)
        }
        
        for input in session.inputs {
            session.removeInput(input as? AVCaptureInput)
        }
        
        session = nil
        captureDevice = nil
        captureDeviceDiscoverySession = nil
        vc.imageView.image = nil
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        let image = imageFromSampleBuffer(sampleBuffer: sampleBuffer)
        
        DispatchQueue.main.async() {
            self.vc.imageView.image = image
        }
    }
    
    func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> UIImage {
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
        
        let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue|CGBitmapInfo.byteOrder32Little.rawValue)!
        let quartzImage = context.makeImage()!
        
        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
        
        let image = UIImage(cgImage: quartzImage, scale: 1.0, orientation: UIImageOrientation.right)
        
        return image
    }
    
    func getImage() -> UIImage? {
        if let _: AVCaptureConnection? = captureVideoDataOutput.connection(withMediaType: AVMediaTypeVideo) {
            return vc.imageView.image
        }
        
        return nil
    }
 
}
