//
//  ViewController.swift
//  HackBikeApp
//
//  Created by Yasushi Sakai on 2/22/19.
//  Copyright © 2019 Yasushi Sakai. All rights reserved.
//

import UIKit
import CoreLocation
// import AVFoundation
import Foundation
// import CoreBluetooth

// enum VideoError : Error {
//     case noInput
//     case deviceNotFound
//     case unknown
// }

// enum BluetoothError: Error {
//     case powerOff
//     case unknown
//     case noCharacteristics
// }


// class ViewController: UIViewController, LocationPermissionDelegate, LocationDelegate, AVCaptureFileOutputRecordingDelegate, CBCentralManagerDelegate, CBPeripheralDelegate{

class ViewController: UIViewController, LocationPermissionDelegate, LocationDelegate{

    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var videoView: UIView!
    
    lazy var locationManager = {
        LocationManager(permissionDelegate: self, locationDelegate: self)
    }()
    
    // private var videoOutput = AVCaptureMovieFileOutput()
    var trip: Trip?
    
    // var centralManager: CBCentralManager?
    // var peripheral: CBPeripheral?
    // var characteristic: CBCharacteristic?
    
    // var isRaspberryReady = false
    
    // hardcoded by raspi
    
    // hackbicycle-earth UUIDs
    let targetServiceUUID = "0x7f075acf-ab17-40dd-b87d-c60f8dfc72d8"
    let targetCharacteristics = "0xb36c6c17-121d-49fd-8316-af28188e58a0"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            try locationManager.requestAuthorization()
        } catch let error {
            print("error: \(error)")
        }
        
        // let session = AVCaptureSession()
        //
        // // NOTE: since the simulator has no camera, you need to test it on a real
        // // device
        //
        // // get front camera
        //  guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
        //     fatalError("Error: couldn't find video device")
        // }
        //
        // guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
        //     fatalError("Error: couldn't find audio device")
        // }
        //
        // do {
        //     let videoInput = try AVCaptureDeviceInput.init(device: videoDevice)
        //     let audioInput = try AVCaptureDeviceInput.init(device: audioDevice)
        //     session.addInput(videoInput)
        //     session.addInput(audioInput)
        // } catch {
        //     // TODO: Error Handling
        // }
        //
        // session.addOutput(videoOutput)
        //
        // let videoLayer = AVCaptureVideoPreviewLayer.init(session: session)
        // videoLayer.frame = videoView.bounds
        // videoLayer.videoGravity = .resizeAspectFill
        // videoView.layer.addSublayer(videoLayer)
        //
        // session.startRunning()
        
        // // - bluetooth
        // centralManager = CBCentralManager(delegate: self, queue: nil)
        // isRaspberryReady = false
        
        // // - timer
        // Timer.scheduledTimer(timeInterval: 10.0, target: self, selector:#selector(ViewController.sendHeartBeat), userInfo: nil, repeats: true)
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
            
//            do{
//                let videoURL = try FileWriter.createFullPath(for: "\(now.epoch()).mp4", in: .Documents)
//                videoOutput.startRecording(to: videoURL, recordingDelegate: self)
//            } catch {
//                // TODO: Error Handling
//            }
            
            UIApplication.shared.isIdleTimerDisabled = true

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
            
            // videoOutput.stopRecording()
            
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
    
    // MARK: - Location Delegate Function
    
    func obtainedLocation(_ location: Location) {
        trip?.append(breadCrumb: location)
    }
    
    func failedWithError(_ error: LocationError) {
        fatalError("Location Error: \(error)")
    }
    
    // // MARK: - Video Recording Delegate Function
    // func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
    //     //
    // }
    
    // // MARK: - Bluetooth Central Manager Delegate
    //
    // func centralManagerDidUpdateState(_ central: CBCentralManager) {
    //
    //     guard let centralManager = centralManager else {
    //         print("centralManager missing")
    //         return
    //     }

    //     switch centralManager.state {
    //     case .poweredOn :
    //         let services: [CBUUID] = [CBUUID(string: targetServiceUUID)]
    //         centralManager.scanForPeripherals(withServices: services, options: nil)
    //     default :
    //         return
    //     }
    // }
    //
    // func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
    //     guard let centralManager = centralManager, let name = peripheral.name else {
    //         return
    //     }
    //
    //     print("found peripheral name: \(name)")
    //
    //     self.peripheral = peripheral
    //     centralManager.connect(peripheral, options: nil)
    //     centralManager.stopScan()
    // }
    //
    // func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    //
    //     print("connected to peripheral: \(peripheral.name ?? "undefined")")
    //
    //     peripheral.delegate = self
    //     let services: [CBUUID] = [CBUUID(string: targetServiceUUID)]
    //     peripheral.discoverServices(services)
    // }
    //
    // func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
    //     if let error = error {
    //         print("error connecting to peripheral: \(error)")
    //     }
    //
    // }
    //
    // func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    //     if let _ = error {
    //         print("error discovering service")
    //     }
    //
    //     guard let services = peripheral.services else {
    //         print("peripheral.services was nil")
    //         return
    //     }
    //
    //     print("found \(services.count)")
    //
    //     for service in services {
    //         if service.uuid == CBUUID(string: targetServiceUUID) {
    //             let characteristics: [CBUUID] = [CBUUID(string: targetCharacteristics)]
    //             peripheral.discoverCharacteristics(characteristics, for: service)
    //         }
    //     }
    // }
    //
    // func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    //     if let _ = error {
    //         print("error in discovering characteristics")
    //     }
    //
    //     guard let charcteristics = service.characteristics else {
    //         print("characteristics was nil")
    //         return
    //     }
    //
    //     for characteristic in charcteristics {
    //         if characteristic.uuid == CBUUID(string: targetCharacteristics) {
    //             isRaspberryReady = true
    //             self.peripheral = peripheral
    //             self.characteristic = characteristic
    //             guard let data = "start".data(using: String.Encoding.utf8, allowLossyConversion: true) else {
    //
    //                 print("enable to decode data")
    //                 return
    //
    //             }
    //             peripheral.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
    //
    //             sendHeartBeat()
    //         }
    //     }
    // }
    //
    // func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
    //     if let _ = error {
    //         print("error writing value for \(characteristic.uuid.uuidString)")
    //         return
    //     }
    //
    //     print("Success!")
    // }
    //
    // @objc func sendHeartBeat(){
    //
    //     guard let peripheral = peripheral, let characteristic = characteristic, let now = String(Date().timeIntervalSince1970).data(using: String.Encoding.utf8, allowLossyConversion: true) else {
    //         print("not ready for blue tooth")
    //         return
    //     }
    //
    //     peripheral.writeValue(now, for: characteristic, type: .withResponse)
    //
    // }
}

