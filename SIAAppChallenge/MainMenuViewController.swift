//
//  MainMenuViewController.swift
//  SIAAppChallenge
//
//  Created by Clarence Chan on 22/8/20.
//  Copyright © 2020 High Flyers. All rights reserved.
//

import UIKit
import AVFoundation
import Alamofire
import SwiftyJSON

protocol CheckInOutDelegate {
    func checkIn(userId: String)
    func didCheckOutSuccessfully()
    func didNotCheckOutSuccessfully()
}

class MainMenuViewController: UIViewController {

    // MARK: - IBOutlets
    
    @IBOutlet weak var checkInAndOutBtn: UIButton! {
        didSet {
            checkInAndOutBtn.backgroundColor = UIColor.orange
            checkInAndOutBtn.layer.cornerRadius = 20
        }
    }
    
    @IBOutlet weak var facilitiesBtn: UIButton! {
        didSet {
            facilitiesBtn.backgroundColor = UIColor.orange
            facilitiesBtn.layer.cornerRadius = 20
        }
    }
    
    // MARK: - View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
    }

    // MARK: - IBActions
    
    @IBAction func checkInAndOutBtnTapped(_ sender: UIButton) {
        // Launch QR Scanner
        let vc = ScannerViewController()
        vc.checkInOutDelegate = self
        vc.scanType = .checkIn
        self.present(vc, animated: true, completion: nil)
    }
    
    @IBAction func facilitiesBtnTapped(_ sender: UIButton) {
        // Display lounge floor plan
        let vc = FacilitiesViewController(nibName: "FacilitiesViewController", bundle: nil)
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func checkOut(userId: String) {
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
                    self.view.makeToast("Checkout successful. Thank you for lounging with SilverKris Lounge.")
                } else {
                    self.dismiss(animated: true) {
                        self.view.makeToast("Thank you for checking out.")
                    }
                }
            } catch {
                print("Error checking if user is checked in")
            }
        }
    }
    
}

// MARK: - ScannerDelegate

extension MainMenuViewController: CheckInOutDelegate {
    
    func checkIn(userId: String) {
        let params: [String: Any] = [
            "id": userId
        ]
        let headers: HTTPHeaders = ["Content-Type": "application/x-www-form-urlencoded"]
        
        AF.request(URL(string: "https://lounge-management-backend.herokuapp.com/CheckInLounge")!, method: .post, parameters: params, encoding: URLEncoding.httpBody, headers: headers).response { response in
            do {
                let resJson = try JSON.init(data: response.data!)
                let result = resJson["result"].boolValue
                
                if result == true {
                    
                    // Check in successful
                    let vc = FacilitiesViewController(nibName: "FacilitiesViewController", bundle: nil)
                    vc.justCheckedIn = true
                    self.navigationController?.isNavigationBarHidden = false
                    self.navigationController?.pushViewController(vc, animated: true)
                    
                } else {
                    self.checkOut(userId: userId)
                }
            } catch {
                print("Error checking in")
            }
        }
    }
    
    func didCheckOutSuccessfully() {
        self.view.makeToast("Checkout successful. Thank you for lounging with SilverKris Lounge.")
    }
    
    func didNotCheckOutSuccessfully() {
        self.view.makeToast("Thank you for checking out.")
    }
    
}
