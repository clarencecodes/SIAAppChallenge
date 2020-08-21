//
//  MainMenuViewController.swift
//  SIAAppChallenge
//
//  Created by Clarence Chan on 22/8/20.
//  Copyright © 2020 High Flyers. All rights reserved.
//

import UIKit

class MainMenuViewController: UIViewController {

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func checkInAndOutBtnTapped(_ sender: UIButton) {
        // Launch QR Scanner
    }
    
    @IBAction func facilitiesBtnTapped(_ sender: UIButton) {
        // Display lounge floor plan
    }
    

}
