//
//  VideoRecorder.swift
//  HackBikeApp
//
//  Created by Yasushi Sakai on 2/24/19.
//  Copyright © 2019 Yasushi Sakai. All rights reserved.
//

import Foundation
import AVFoundation
import Photos

enum VideoError: Error {
    case deviceNotFound
}

extension FileWriter {
    static func createVideoPath(for fileName: String) throws -> URL {
        return try FileWriter.createFullPath(for: fileName, in: .Documents)
    }
}

class VideoRecorder: NSObject, AVCaptureFileOutputRecordingDelegate {
    
    let clipFile: AVCaptureMovieFileOutput
    let captureSession: AVCaptureSession
    
    init(view: UIView){
        self.clipFile = AVCaptureMovieFileOutput()
        self.captureSession = AVCaptureSession()
        
        let videoInput: AVCaptureDeviceInput
        let audioInput: AVCaptureDeviceInput
        
        super.init()
        
        do{
            let (videoDevice, audioDevice) = try VideoRecorder.getDevices()
            videoInput = try AVCaptureDeviceInput(device: videoDevice)
            captureSession.addInput(videoInput)
            audioInput = try AVCaptureDeviceInput(device: audioDevice)
            captureSession.addInput(audioInput)
        } catch {
            // TODO: error handling
        }
        
        let videoLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        videoLayer.frame = view.bounds
        videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        view.layer.addSublayer(videoLayer)
        
        captureSession.startRunning()
    }
    
    func startRecording(for fileName: String) {
        let videoURL:URL
        do{
            videoURL = try FileWriter.createVideoPath(for: fileName)
        } catch let error{
            fatalError("\(error)")
        }
        clipFile.startRecording(to: videoURL, recordingDelegate: self)
    }
    
    func stopRecording() {
        clipFile.stopRecording()
    }

    
    static func getDevices() throws -> (AVCaptureDevice, AVCaptureDevice) {
        guard let video = AVCaptureDevice.default(for: .video), let audio = AVCaptureDevice.default(for: .audio) else {
            throw VideoError.deviceNotFound
        }
        return (video, audio)
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        //
        
    }
    
}
