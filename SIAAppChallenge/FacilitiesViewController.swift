//
//  FacilitiesViewController.swift
//  SIAAppChallenge
//
//  Created by Clarence Chan on 22/8/20.
//  Copyright © 2020 High Flyers. All rights reserved.
//

import UIKit

class FacilitiesViewController: UIViewController {

    // MARK: - IBOutlets
    
    @IBOutlet weak var meetingRoomBtn: UIButton! {
        didSet {
            meetingRoomBtn.backgroundColor = UIColor.lightGray
            meetingRoomBtn.setTitleColor(.black, for: .normal)
        }
    }
    
    @IBOutlet var seats: [UIButton]! {
        didSet {
            for seat in seats {
                seat.layer.cornerRadius = 25
            }
        }
    }
    
    // MARK: - View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }


}