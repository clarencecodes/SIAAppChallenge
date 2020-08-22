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
    var isCheckingIn = false
    var userId: String?
    
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
        
        // If user is checking in, only show available seats, and prompt user to select a seat.
        // If user is not checking in, show available seats and facilities
        if !isCheckingIn {
            getFacilitiesAvailability()
        } else {
            self.view.makeToast("Welcome, please select your seat to get started. Available seats are in green while occupied seats are red.")
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
        // If user is checking in and the seat is available
        // go ahead with checking in to the lounge
        if let userId = userId,
            isCheckingIn && sender.backgroundColor == .green {
            checkIn(userId: userId, seatNo: sender.tag)
        }
        
        if !isCheckingIn && sender.backgroundColor == .lightGray {
            self.checkOut()
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
        
        if !isCheckingIn {
            getFacilitiesAvailability()
        }
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
//
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
    
    private func checkIn(userId: String, seatNo: Int) {
        
        let params: [String: Any] = [
            "id": userId,
            "seatNo": seatNo
        ]
        let headers: HTTPHeaders = ["Content-Type": "application/x-www-form-urlencoded"]
        
        AF.request(URL(string: "https://lounge-management-backend.herokuapp.com/CheckInLounge")!, method: .post, parameters: params, encoding: URLEncoding.httpBody, headers: headers).response { response in
            do {
                let resJson = try JSON.init(data: response.data!)
                let result = resJson["result"].boolValue
                
                if result == true {
                    
                    // Check in successful
                    
                    self.isCheckingIn = false
                    
                    // Reload updated available seats and facilities from API
                    self.getSeatAvailability()
                    self.getFacilitiesAvailability()
                    
                    self.view.makeToast("You have successfully checked in. Welcome to SilverKris Lounge.")
                } else {
                    self.view.makeToast("User has already checked in.")
                }
            } catch {
                print("Error checking in")
            }
        }
        
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
                    self.dismiss(animated: true) {
                        self.view.makeToast("Checkout successful. Thank you for lounging with SilverKris Lounge.")
                    }
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
