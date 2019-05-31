//
//  ViewController.swift
//  HackBikeApp
//
//  Created by Yasushi Sakai on 2/22/19.
//  Copyright © 2019 Yasushi Sakai. All rights reserved.
//

import UIKit
import CoreLocation
import Foundation

class ViewController: UIViewController, LocationPermissionDelegate, LocationDelegate{

    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var videoView: UIView!
    
    lazy var locationManager = {
        LocationManager(permissionDelegate: self, locationDelegate: self)
    }()
    
    var trip: Trip?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            try locationManager.requestAuthorization()
        } catch let error {
            print("error: \(error)")
        }
}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func requestLocation(){
        locationManager.requestLocation()
    }
    
    @objc func toggleUpdatingLocation(){
        locationManager.toggleUpdate()
        if locationManager.isUpdating {
            // reset the trip
            let now = Date()
            trip = Trip(started: now)
            
            UIApplication.shared.isIdleTimerDisabled = true

            locationButton.setTitle("stop recording", for: .normal)
        } else {
            // save the trip to a file
            if let trip = trip {
                let fmt = DateFormatter()
                fmt.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                let fileName = "trip_\(fmt.string(from: trip.started)).csv"
                do {
                    try FileWriter.write(to: fileName, contents: trip.breadCrumbString())
                } catch let error {
                    fatalError(error.localizedDescription)
                }
            }
            
            UIApplication.shared.isIdleTimerDisabled = false

            locationButton.setTitle("start recording", for: .normal)
        }
    }
    
    // MARK: - Location Permission Delegate Function
    
    func authGranted() {
        locationButton.isEnabled = true
        locationButton.addTarget(self, action: #selector(ViewController.toggleUpdatingLocation), for:.touchUpInside)
        locationButton.setTitle("start recording", for: .normal)
    }
    
    func authFailed(with status: CLAuthorizationStatus) {
        switch status {
            case .denied : print("user denied location authorization")
            default : print("authorization status: \(status)")
        }
    }
    
    // FIXME: redundant code
    
    func toBackground() {
        locationManager.toBackground()
    }
    
    func toForeground() {
        locationManager.toForeground()
    }
    
    // MARK: - Location Delegate Function
    
    func obtainedLocation(_ location: Location) {
        trip?.append(breadCrumb: location)
    }
    
    func failedWithError(_ error: LocationError) {
        // fatalError("Location Error: \(error)")
    }
}

