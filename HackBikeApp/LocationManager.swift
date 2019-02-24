//
//  LocationManager.swift
//  HackBikeApp
//
//  Created by Yasushi Sakai on 2/22/19.
//  Copyright © 2019 Yasushi Sakai. All rights reserved.
//

import Foundation
import CoreLocation

enum LocationError: Error {
    case userDisallowed
    case cannotFindLocation
    case unknown
}

protocol LocationPermissionDelegate: class {
    func authGranted()
    func authFailed(with status: CLAuthorizationStatus)
}

protocol LocationDelegate: class {
    func obtainedLocation(_ location: Location)
    func failedWithError(_ error: LocationError)
}

// TODO: separate generic LocationManaging function and Trip and Breadcrumbs
class LocationManager: NSObject, CLLocationManagerDelegate {
    
    private let manager = CLLocationManager()
    
    var isUpdating: Bool
    weak var permissionDelegate: LocationPermissionDelegate?
    weak var delegate: LocationDelegate?
    
    init(
        permissionDelegate: LocationPermissionDelegate?,
        locationDelegate: LocationDelegate?
        ){
        self.permissionDelegate = permissionDelegate
        self.delegate = locationDelegate
        self.isUpdating = false
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = kCLDistanceFilterNone
    }
    
    static var isAuthorized: Bool {
        switch CLLocationManager.authorizationStatus(){
        case .authorizedWhenInUse: return true
        default: return false
        }
    }
    
    func requestAuthorization() throws {
        let authorizationStatus = CLLocationManager.authorizationStatus()
        
        if authorizationStatus == .restricted || authorizationStatus == .denied {
            throw LocationError.userDisallowed
        } else if (authorizationStatus == .notDetermined) {
            manager.requestWhenInUseAuthorization()
        } else {
            return
        }
    }
    
    func requestLocation() {
        manager.requestLocation()
    }
    
    func toggleUpdate(){
        if isUpdating {
            manager.stopUpdatingLocation()
        } else {
            manager.startUpdatingLocation()
        }
        isUpdating = !isUpdating
    }
    
    // MARK: - delagate functions
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            permissionDelegate?.authGranted()
        } else {
            permissionDelegate?.authFailed(with: status)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard let error = error as? CLError else {
            delegate?.failedWithError(.unknown)
            return
        }
        
        switch error.code {
        case .locationUnknown, .network:
            delegate?.failedWithError(.cannotFindLocation)
        case .denied:
            delegate?.failedWithError(.userDisallowed)
        default: return
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let location = locations.last else {
            delegate?.failedWithError(.cannotFindLocation)
            return
        }
        delegate?.obtainedLocation(Location(at: location))
    }
}
















