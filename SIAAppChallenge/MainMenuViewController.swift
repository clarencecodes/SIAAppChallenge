//
//  MainMenuViewController.swift
//  SIAAppChallenge
//
//  Created by Clarence Chan on 22/8/20.
//  Copyright © 2020 High Flyers. All rights reserved.
//

import UIKit
import AVFoundation

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
        vc.delegate = self
        vc.modalPresentationStyle = .overFullScreen
        self.present(vc, animated: true, completion: nil)
    }
    
    @IBAction func facilitiesBtnTapped(_ sender: UIButton) {
        // Display lounge floor plan
        let vc = FacilitiesViewController(nibName: "FacilitiesViewController", bundle: nil)
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}

// MARK: - ScannerDelegate

extension MainMenuViewController: ScannerDelegate {
    
    func presentLoungeFloorPlanForCheckIn(userId: String) {
        // Display lounge floor plan
        let vc = FacilitiesViewController(nibName: "FacilitiesViewController", bundle: nil)
        vc.isCheckingIn = true
        vc.userId = userId
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func didCheckOutSuccessfully() {
        self.view.makeToast("Checkout successful. Thank you for lounging with SilverKris Lounge.")
    }
    
    func didNotCheckOutSuccessfully() {
        self.view.makeToast("Thank you for checking out.")
    }
    
}
