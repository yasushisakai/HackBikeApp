//
//  ViewController.swift
//  HackBikeApp
//
//  Created by Yasushi Sakai on 2/22/19.
//  Copyright © 2019 Yasushi Sakai. All rights reserved.
//

import UIKit
import CoreLocation
import AVFoundation

enum VideoError : Error {
    case noInput
    case deviceNotFound
    case unknown
}


class ViewController: UIViewController, LocationPermissionDelegate, LocationDelegate, AVCaptureFileOutputRecordingDelegate{

    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var videoView: UIView!
    
    lazy var locationManager = {
        LocationManager(permissionDelegate: self, locationDelegate: self)
    }()
    
    private var videoOutput = AVCaptureMovieFileOutput()
    var trip: Trip?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            try locationManager.requestAuthorization()
        } catch let error {
            print("error: \(error)")
        }
        
        let session = AVCaptureSession()
        
        // NOTE: since the simulator has no camera, you need to test it on a real
        // device
        guard let videoDevice = AVCaptureDevice.default(for: .video) else {
            fatalError("Error: couldn't find video device")
        }
        
        guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
            fatalError("Error: couldn't find audio device")
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput.init(device: videoDevice)
            let audioInput = try AVCaptureDeviceInput.init(device: audioDevice)
            session.addInput(videoInput)
            session.addInput(audioInput)
        } catch {
            // TODO: Error Handling
        }
        
        session.addOutput(videoOutput)
        
        let videoLayer = AVCaptureVideoPreviewLayer.init(session: session)
        videoLayer.frame = videoView.bounds
        videoLayer.videoGravity = .resizeAspectFill
        videoView.layer.addSublayer(videoLayer)
        
        session.startRunning()
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
            
            do{
                let videoURL = try FileWriter.createFullPath(for: "\(now.epoch()).mp4", in: .Documents)
                videoOutput.startRecording(to: videoURL, recordingDelegate: self)
            } catch {
                // TODO: Error Handling
            }
            
            locationButton.setTitle("stop recording", for: .normal)
        } else {
            // save the trip to a file
            if let trip = trip {
                let fileName = "trip_\(trip.started.epoch()).csv"
                do {
                    try FileWriter.write(to: fileName, contents: trip.breadCrumbString())
                } catch let error {
                    fatalError(error.localizedDescription)
                }
            }
            
            videoOutput.stopRecording()
            
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
    
    // MARK: - Location Delegate Function
    
    func obtainedLocation(_ location: Location) {
        trip?.append(breadCrumb: location)
    }
    
    func failedWithError(_ error: LocationError) {
        fatalError("Location Error: \(error)")
    }
    
    // MARK: - Video Recording Delegate Function
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        //
    }
    
}

