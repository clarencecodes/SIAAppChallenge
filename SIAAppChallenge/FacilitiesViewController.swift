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

protocol FacilityBookingDelegate {
    func didBookMeetingRoom()
    func didEndBookingForMeetingRoom()
    func didBookShowerRoom()
    func didEndBookingForShowerRoom()
}

class FacilitiesViewController: UIViewController {
    
    // MARK: - Properties
    var reloadTimer: Timer!
    var userId: String?
    
    var justCheckedIn = false
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var meetingRoomBtn: UIButton! {
        didSet {
            meetingRoomBtn.backgroundColor = UIColor.lightGray
        }
    }
    
    @IBOutlet weak var trashIndicatorContentView: UIView!
    @IBOutlet weak var trashIndicator: UIView!
    @IBOutlet weak var trashIndicatorTopConstraint: NSLayoutConstraint!
    
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
        
        // Reload data every 10 seconds
        reloadTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(reloadData), userInfo: nil, repeats: true)
        
        getSeatAvailability()
        getBinStatus()
        getFacilitiesAvailability()
        
        if justCheckedIn {
            justCheckedIn = false
            
            let alert = UIAlertController(title: "Welcome", message: "Facilities marked in green are available while facilities marked in red are occupied. Feel free to make bookings of facilities here.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: - IBActions
    
    @IBAction func meetingRoomBtnTapped(_ sender: UIButton) {
        guard sender.backgroundColor == .green || sender.backgroundColor == .red else { return }
        
        let vc = ScannerViewController()
        vc.scanType = .meetingRoom
        vc.facilityBookingDelegate = self
        self.present(vc, animated: true, completion: nil)
    }
    
    @IBAction func seatBtnTapped(_ sender: UIButton) {
        let params: [String: Any] = [
            "seatNo": sender.tag
        ]
        
        if sender.backgroundColor == .green {
            // Fill seat
            
            AF.request(URL(string: "https://lounge-management-backend.herokuapp.com/FillSeat")!, method: .post, parameters: params, encoding: URLEncoding.httpBody, headers: nil).response { response in
                
                do {
                    let resJson = try JSON.init(data: response.data!)
                    let filled = resJson["result"].boolValue
                    
                    if filled {
                        sender.backgroundColor = .red
                        self.view.makeToast("Seat \(sender.tag) filled")
                    }
                } catch {
                    self.view.makeToast("Error parsing JSON data when filling seat")
                }
            }
        } else if sender.backgroundColor == .red {
            // Free up seat
            
            AF.request(URL(string: "https://lounge-management-backend.herokuapp.com/EmptySeat")!, method: .post, parameters: params, encoding: URLEncoding.httpBody, headers: nil).response { response in
                
                do {
                    let resJson = try JSON.init(data: response.data!)
                    let freed = resJson["result"].boolValue
                    
                    if freed {
                        sender.backgroundColor = .green
                        self.view.makeToast("Seat \(sender.tag) freed")
                    }
                } catch {
                    self.view.makeToast("Error parsing JSON data when freeing up seat")
                }
            }
        }
    }
    
    @IBAction func showerBtnTapped(_ sender: UIButton) {
        guard sender.backgroundColor == .green || sender.backgroundColor == .red else { return }
        
        let vc = ScannerViewController()
        vc.scanType = .shower
        vc.facilityBookingDelegate = self
        self.present(vc, animated: true, completion: nil)
    }
    
    // MARK: - Network requests
    
    @objc private func reloadData() {
        getSeatAvailability()
        getBinStatus()
        getFacilitiesAvailability()
    }
    
    private func getBinStatus() {
        AF.request(URL(string: "https://lounge-management-backend.herokuapp.com/GetBinStatus")!).response { response in
            do {
                let resJson = try JSON.init(data: response.data!)
                let color = resJson["response"].stringValue
                
                if color == "GREEN" {
                    self.trashIndicator.backgroundColor = .green
                    self.trashIndicatorTopConstraint.constant = self.trashIndicatorContentView.frame.height - 10
                } else if color == "YELLOW" {
                    self.trashIndicator.backgroundColor = .orange
                    
                    self.trashIndicatorTopConstraint.constant = self.trashIndicatorContentView.frame.height / 2
                    
                } else if color == "RED" {
                    self.trashIndicator.backgroundColor = .red
                    
                    self.trashIndicatorTopConstraint.constant = 0
                }
            } catch {
                print("Error getting bin status")
            }
        }
    }
    
    private func getSeatAvailability() {
        AF.request(URL(string: "https://lounge-management-backend.herokuapp.com/GetSeatAvailability/")!).response { response in
            do {
                let resJson = try JSON.init(data: response.data!)
                for (index, res) in resJson.enumerated() {
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
                
                for index in updatedIndex..<self.showers.count {
                    self.showers[index].backgroundColor = .red
                }
                
                // Get availability of meeting room
                let meetingRoom = resJson.arrayValue.first { $0["type"].stringValue == "meeting_room" }!
                let meetingRoomQuantity = meetingRoom["quantity"].intValue
                
                if meetingRoomQuantity == 1 {
                    self.meetingRoomBtn.backgroundColor = .green
                } else {
                    self.meetingRoomBtn.backgroundColor = .red
                }
                
            } catch {
                print("Error getting facilities availability")
            }
        }
    }
    
}


// MARK: - FacilityBookingDelegate

extension FacilitiesViewController: FacilityBookingDelegate {
    func didBookMeetingRoom() {
        self.view.makeToast("Meeting room booked!")
        self.meetingRoomBtn.backgroundColor = .red
    }
    
    func didEndBookingForMeetingRoom() {
        self.view.makeToast("Meeting room booking ended.")
        self.meetingRoomBtn.backgroundColor = .green
    }

    func didBookShowerRoom() {
        for shower in showers {
            if shower.backgroundColor == .green {
                self.view.makeToast("Shower room booked!")
                shower.backgroundColor = .red
                break
            }
        }
    }
    
    func didEndBookingForShowerRoom() {
        for shower in showers {
            if shower.backgroundColor == .red {
                self.view.makeToast("Shower room booking ended.")
                shower.backgroundColor = .green
                break
            }
        }
    }
}
