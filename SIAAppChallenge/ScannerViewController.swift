//
//  ScannerViewController.swift
//  SIAAppChallenge
//
//  Created by Clarence Chan on 22/8/20.
//  Copyright © 2020 High Flyers. All rights reserved.
//

import AVFoundation
import UIKit
import Alamofire
import SwiftyJSON
import Toast_Swift

enum ScanType {
    case meetingRoom, shower, checkIn
}

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    // MARK: - Properties
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    var checkInOutDelegate: CheckInOutDelegate?
    var facilityBookingDelegate: FacilityBookingDelegate?
    
    var userId: String?
    
    var scanType: ScanType?

    // MARK: - View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        captureSession.startRunning()
        
        // Set the orientation of the camera
        if let previewLayerConnection = previewLayer.connection,
            previewLayerConnection.isVideoOrientationSupported {
            
            if let interfaceOrientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation {
                previewLayerConnection.videoOrientation = AVCaptureVideoOrientation(rawValue: interfaceOrientation.rawValue)!
            }
        }
    }
    
    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if (captureSession?.isRunning == false) {
            captureSession.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()

        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)
        }

        dismiss(animated: true)
    }

    func found(code: String) {
        self.userId = code
        
        switch scanType {
        case .checkIn:
            let params: [String: Any] = ["id": code]
            let headers: HTTPHeaders = ["Content-Type": "application/x-www-form-urlencoded"]
            // Check if user is checked in before checking in or out
            AF.request(URL(string: "https://lounge-management-backend.herokuapp.com/IsCheckedIn")!, method: .post, parameters: params, encoding: URLEncoding.httpBody, headers: headers).response { response in
                do {
                    let resJson = try JSON.init(data: response.data!)
                    let result = resJson["result"].boolValue
                    if result == true {
                        // User is checked in, proceed to check out
                        self.checkOut()
                    } else {
                        // User is not checked in, proceed to select seat in FacilitiesViewController and check in
                        self.dismiss(animated: true) {
                            self.checkInOutDelegate?.checkIn(userId: code)
                        }
                    }
                } catch {
                    print("Error checking if user is checked in")
                }
            }
        case .meetingRoom:
            let params: [String: Any] = [
                "id": code,
                "facilityType": 3
            ]
            let headers: HTTPHeaders = ["Content-Type": "application/x-www-form-urlencoded"]
            
            AF.request(URL(string: "https://lounge-management-backend.herokuapp.com/CheckInOutFacilities")!, method: .post, parameters: params, encoding: URLEncoding.httpBody, headers: headers).response { response in
                do {
                    let resJson = try JSON.init(data: response.data!)
                    let result = resJson["result"].stringValue

                    if result == "Booked" {
                        self.facilityBookingDelegate?.didBookMeetingRoom()
                    } else if result == "Ended" {
                        self.facilityBookingDelegate?.didEndBookingForMeetingRoom()
                    }

                } catch {
                    print("Error checking in or out of meeting room")
                }
            }
        case .shower:
            let params: [String: Any] = [
                "id": code,
                "facilityType": 2
            ]
            let headers: HTTPHeaders = ["Content-Type": "application/x-www-form-urlencoded"]
            
            AF.request(URL(string: "https://lounge-management-backend.herokuapp.com/CheckInOutFacilities")!, method: .post, parameters: params, encoding: URLEncoding.httpBody, headers: headers).response { response in
                do {
                    let resJson = try JSON.init(data: response.data!)
                    let result = resJson["result"].stringValue

                    if result == "Booked" {
                        self.facilityBookingDelegate?.didBookShowerRoom()
                    } else if result == "Ended" {
                        self.facilityBookingDelegate?.didEndBookingForShowerRoom()
                    }

                } catch {
                    print("Error checking in or out of meeting room")
                }
            }
        default:
            break
        }
        
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    private func checkOut() {
        guard let userId = userId else { return }
        
        let params: [String: Any] = [
            "id": userId
        ]
        let headers: HTTPHeaders = [
            "Content-Type": "application/x-www-form-urlencoded"
        ]
        
        AF.request(URL(string: "https://lounge-management-backend.herokuapp.com/CheckOutLounge")!, method: .post, parameters: params, encoding: URLEncoding.httpBody, headers: headers).response { response in
            do {
                let resJson = try JSON.init(data: response.data!)
                let result = resJson["result"].boolValue
                if result == true {
                    self.checkInOutDelegate?.didCheckOutSuccessfully()
                } else {
                    self.checkInOutDelegate?.didNotCheckOutSuccessfully()
                }
            } catch {
                print("Error checking if user is checked in")
            }
        }
    }
    
}
