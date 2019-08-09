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
import CoreBluetooth

class ViewController:
UIViewController,
LocationPermissionDelegate,
LocationDelegate,
// AVCaptureFileOutputRecordingDelegate,
CBCentralManagerDelegate,
CBPeripheralDelegate
{
    
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var btStatus: UILabel!
    @IBOutlet weak var userId: UILabel!
    lazy var locationManager = {
        LocationManager(permissionDelegate: self, locationDelegate: self)
    }()
    
    var trip: Trip?
    var deviceId = UIDevice.current.identifierForVendor
    var centralManager: CBCentralManager?
    var peripheral: CBPeripheral?
    var characteristic: CBCharacteristic?
    
    var isRaspberryReady = false
    
    let RFC3339DateFormatter = DateFormatter()
    // hardcoded by raspi
    
    // hackbicycle-earth UUIDs
//    let targetServiceUUID = "0x7f075acf-ab17-40dd-b87d-c60f8dfc72d8"
//    let targetCharacteristics = "0xb36c6c17-121d-49fd-8316-af28188e58a0"
    
    // hackbike-saturn
//    let targetServiceUUID = "d7064211-e10c-4914-b1bd-53e1535ddc5c"
//    let targetCharacteristics = "b11bb9d4-9a36-48aa-94b3-9aa441c1d950"
    
    // hackbike-venus
//    let targetServiceUUID = "8a123c0f-fa18-4e5c-8e33-c4087ddca581"
//    let targetCharacteristics = "a5b30759-4b3f-46ef-a34a-3af6cf741d77"
    
    // hackbike-mercury
    
    let targetServiceUUID = "d5aa8ea0-4483-4b4e-9f4f-281237a623f4"
    let targetCharacteristics = "21dbc7b9-a472-4b43-bc00-298ed6c62d21"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            try locationManager.requestAuthorization()
        } catch let error {
            print("error: \(error)")
        }
        
        status.text = "loaded"
        btStatus.text = "bluetooth not loaded"
        
        guard let deviceId = deviceId else {
            fatalError("Error: couldn't find deviceId")
        }
        
        userId.text = deviceId.uuidString

        RFC3339DateFormatter.locale = Locale(identifier: "America/New_York")
        RFC3339DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        RFC3339DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
//        let session = AVCaptureSession()
        
        // NOTE: since the simulator has no camera, you need to test it on a real
        // device
            
        // get front camera
//         guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
//            fatalError("Error: couldn't find video device")
//        }
//
//        guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
//            fatalError("Error: couldn't find audio device")
//        }
        
//        do {
//            let videoInput = try AVCaptureDeviceInput.init(device: videoDevice)
//            let audioInput = try AVCaptureDeviceInput.init(device: audioDevice)
//            session.addInput(videoInput)
//            session.addInput(audioInput)
//        } catch {
//            // TODO: Error Handling
//        }
        
//        session.addOutput(videoOutput)
        
//        let videoLayer = AVCaptureVideoPreviewLayer.init(session: session)
//        videoLayer.frame = videoView.bounds
//        videoLayer.videoGravity = .resizeAspectFill
//        videoView.layer.addSublayer(videoLayer)
//
//        session.startRunning()
        // - bluetooth
        centralManager = CBCentralManager(delegate: self, queue: nil)
        isRaspberryReady = false
        
        // - timer
        Timer.scheduledTimer(timeInterval: 10.0, target: self, selector:#selector(ViewController.sendHeartBeat), userInfo: nil, repeats: true)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func requestLocation(){
        locationManager.requestLocation()
    }
    
    @objc func toggleUpdatingLocation(){
        
        if !isRaspberryReady {
            return
        }
        
        locationManager.toggleUpdate()
        if locationManager.isUpdating {
            // reset the trip
            let now = Date()
            let tmpTrip = Trip(started: now)
            
//            do{
//                let videoURL = try FileWriter.createFullPath(for: "\(now.epoch()).mp4", in: .Documents)
//                videoOutput.startRecording(to: videoURL, recordingDelegate: self)
//            } catch {
//                // TODO: Error Handling
//            }
            
            let date = RFC3339DateFormatter.string(from: now)
            send(string: "s, \(date), \(tmpTrip.uuid)")
            UIApplication.shared.isIdleTimerDisabled = true
            locationButton.setTitle("stop recording", for: .normal)
            trip = tmpTrip
            status.text = "new trip \(tmpTrip.uuid) started"
        } else {
            // save the trip to a file
            if let trip = trip, let deviceId = deviceId{
                let fmt = DateFormatter()
                fmt.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                let fileName = "trip_\(fmt.string(from: trip.started))_\(trip.uuid)_\(deviceId.uuidString).csv"
                do {
                    try FileWriter.write(to: fileName, contents: trip.breadCrumbString())
                } catch let error {
                    fatalError(error.localizedDescription)
                }
                status.text = "saved trip \(trip.uuid)"
                send(string: "e")
            }
            
            UIApplication.shared.isIdleTimerDisabled = false
            locationButton.setTitle("start recording", for: .normal)
        }
    }
    
    // MARK: - Location Permission Delegate Function
    
    func authGranted() {
        // locationButton.isEnabled = false
        locationButton.addTarget(self, action: #selector(ViewController.toggleUpdatingLocation), for:.touchUpInside)
        locationButton.setTitle("looking for bike", for: .normal)
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
    
    // // MARK: - Video Recording Delegate Function
    // func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
    //     //
    // }
    
     // MARK: - Bluetooth Central Manager Delegate
     func centralManagerDidUpdateState(_ central: CBCentralManager) {
    
         guard let centralManager = centralManager else {
             print("centralManager missing")
             return
         }

        switch centralManager.state {
            case .poweredOn, .resetting :
                connect(to: centralManager)
            default :
                return
        }
    }
    
    func connect(to cm: CBCentralManager) {
        let services: [CBUUID] = [CBUUID(string: targetServiceUUID)]
        cm.scanForPeripherals(withServices: services, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let centralManager = centralManager, let name = peripheral.name else {
            return
        }
        
        btStatus.text = "found peripheral name: \(name)"
        
        self.peripheral = peripheral
        centralManager.connect(peripheral, options: nil)
        centralManager.stopScan()
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        btStatus.text = "connected to peripheral: \(peripheral.name ?? "undefined")"
        
        peripheral.delegate = self
        let services: [CBUUID] = [CBUUID(string: targetServiceUUID)]
        peripheral.discoverServices(services)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            btStatus.text = "error connecting to peripheral: \(error)"
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let _ = error {
            btStatus.text = "error discovering service"
        }
        
        guard let services = peripheral.services else {
            print("peripheral.services was nil")
            return
        }
     
        print("found \(services.count)")
        
        for service in services {
            if service.uuid == CBUUID(string: targetServiceUUID) {
                let characteristics: [CBUUID] = [CBUUID(string: targetCharacteristics)]
                peripheral.discoverCharacteristics(characteristics, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let _ = error {
            print("error in discovering characteristics")
        }
        
        guard let charcteristics = service.characteristics else {
            print("characteristics was nil")
            return
        }
        
        for characteristic in charcteristics {
            if characteristic.uuid == CBUUID(string: targetCharacteristics) {
                isRaspberryReady = true
                self.peripheral = peripheral
                self.characteristic = characteristic
                guard let data = "start".data(using: String.Encoding.utf8, allowLossyConversion: true) else {
                    print("enable to decode data")
                    return
                }
                peripheral.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
                locationButton.isEnabled = true
                locationButton.setTitle("start recording", for: .normal)
                // sendHeartBeat()
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let _ = error {
            btStatus.text = "error writing value for \(characteristic.uuid.uuidString)"
            return
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let _ = error {
            btStatus.text = "error updating(reading) value for \(characteristic.uuid.uuidString)"
            return
        }
        let value = characteristic.value ?? "no data".data(using: String.Encoding.utf8)!;
        print("Success updating (reading), \(String(describing: String(data: value, encoding: String.Encoding.utf8)))")
    }
    
    @objc func sendHeartBeat(){
        guard let peripheral = peripheral, let characteristic = characteristic else {
            return
        }
        
        let now = RFC3339DateFormatter.string(from:Date());
        let data = "h,\(now)".data(using: String.Encoding.utf8)!;
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
    
    @objc func send(byte: UInt8){
        guard let peripheral = peripheral, let characteristic = characteristic else {
            btStatus.text = "Bluetooth not ready"
            return
        }
        var b = byte
        let data = NSData(bytes: &b, length: 1)
        peripheral.writeValue(data as Data, for: characteristic, type: .withResponse)
    }
    
    @objc func read(string: String){
        guard let peripheral = peripheral, let characteristic = characteristic else {
            btStatus.text = "Bluetooth not ready"
            return
        }
        peripheral.readValue(for: characteristic)
    }
    
    @objc func send(string: String) {
        guard let peripheral = peripheral, let characteristic = characteristic,
            let data = string.data(using: String.Encoding.ascii, allowLossyConversion: true) else {
                btStatus.text = "bluetooth not ready, could not send \(string)"
            return
        }
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
        peripheral.readValue(for: characteristic)
        btStatus.text = "successfully written \(string) to \(characteristic.uuid)"
    }
}

