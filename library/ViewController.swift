//
//  ViewController.swift
//  library
//
//  Created by Ekin Bulut on 10.04.2023.
//

import UIKit
import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Check for camera authorization
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch authorizationStatus {
        case .authorized:
            setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.setupCaptureSession()
                    }
                } else {
                    print("Camera access denied")
                }
            }
        default:
            print("Camera access denied")
        }
    }

    func setupCaptureSession() {
        captureSession = AVCaptureSession()

        // Configure the capture device
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            print("Failed to access camera.")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(input)

            let metadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .pdf417]
            
            // Use a background queue for starting the capture session
            DispatchQueue.global(qos: .background).async { [weak self] in
                self?.captureSession.startRunning()
            }


            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = view.layer.bounds
            DispatchQueue.main.async { [weak self] in
                            self?.previewLayer.frame = self?.view.layer.bounds ?? CGRect.zero
                            self?.view.layer.addSublayer(self?.previewLayer ?? CALayer())
                        }

            

        } catch {
            print("Error configuring capture device: \(error.localizedDescription)")
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        
        for metadataObject in metadataObjects {
            if let barcodeObject = metadataObject as? AVMetadataMachineReadableCodeObject {
                if let barcodeString = barcodeObject.stringValue {
                    print("Detected barcode: \(barcodeString)")
                }
            }
        }
    }
}


