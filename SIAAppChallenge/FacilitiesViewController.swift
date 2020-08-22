//
//  FacilitiesViewController.swift
//  SIAAppChallenge
//
//  Created by Clarence Chan on 22/8/20.
//  Copyright © 2020 High Flyers. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

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
            
            seats.sort { (a, b) -> Bool in
                return a.tag < b.tag
            }
        }
    }
    
    @IBOutlet var showers: [UIButton]!
    
    // MARK: - View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getSeatAvailability()
        getFacilitiesAvailability()
    }
    
    private func getSeatAvailability() {
        AF.request(URL(string: "https://lounge-management-backend.herokuapp.com/GetSeatAvailability/")!).response { response in
            do {
                let resJson = try JSON.init(data: response.data!)
                for (index, res) in resJson.enumerated() {
                    print("\(res.0) \(res.1)")
                    if res.1.intValue == 0 {
                        // free seat
                        self.seats[index].backgroundColor = .green
                    } else if res.1.intValue == 1 {
                        // blocked seat (for safe distancing)
                        self.seats[index].backgroundColor = .lightGray
                    } else {
                        // occupied seat
                        self.seats[index].backgroundColor = .red
                    }
                }
            } catch {
                print("Error getting seat availability")
            }
        }
    }
    
    private func getFacilitiesAvailability() {
        AF.request(URL(string: "https://lounge-management-backend.herokuapp.com/GetFacilitiesAvailability/")!).response { response in
            do {
                let resJson = try JSON.init(data: response.data!)
                
                // Get availability of showers
                let shower = resJson.arrayValue.first { $0["type"].stringValue == "shower" }!
                let showerQuantity = shower["quantity"].intValue
                
                var updatedIndex = 0
                for index in 0..<showerQuantity {
                    self.showers[index].backgroundColor = .green
                    updatedIndex = index
                }
                
                for index in updatedIndex..<self.showers.count - 1 {
                    self.showers[index].backgroundColor = .lightGray
                }
                
                // Get availability of meeting room
                let meetingRoom = resJson.arrayValue.first { $0["type"].stringValue == "meeting_room" }!
                let meetingRoomQuantity = meetingRoom["quantity"].intValue
                
                if meetingRoomQuantity == 1 {
                    self.meetingRoomBtn.backgroundColor = .green
                } else {
                    self.meetingRoomBtn.backgroundColor = .gray
                }
                
            } catch {
                print("Error getting facilities availability")
            }
        }
    }
    
}
