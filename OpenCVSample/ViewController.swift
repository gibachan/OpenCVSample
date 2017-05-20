//
//  ViewController.swift
//  OpenCVSample
//
//  Created by gibachan on 2014/10/19.
//  Copyright (c) 2014年 gibachan. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    @IBOutlet weak var imageView: UIImageView!

    // セッション
    var mySession : AVCaptureSession!
    // カメラデバイス
    var myDevice : AVCaptureDevice!
    // 出力先
    var myOutput : AVCaptureVideoDataOutput!
    
    // 顔検出オブジェクト
    let detector = Detector()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // カメラを準備
        if initCamera() {
            // 撮影開始
            mySession.startRunning()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // カメラの準備処理
    func initCamera() -> Bool {
        // セッションの作成.
        mySession = AVCaptureSession()
        
        // 解像度の指定.
        mySession.sessionPreset = AVCaptureSessionPresetMedium
        
        
        // デバイス一覧の取得.
        let devices = AVCaptureDevice.devices()
        
        // バックカメラをmyDeviceに格納.
        for device in devices! {
            if((device as AnyObject).position == AVCaptureDevicePosition.front){
//                if(device.position == AVCaptureDevicePosition.Back){
                myDevice = device as! AVCaptureDevice
            }
        }
        if myDevice == nil {
            return false
        }
        
        // バックカメラからVideoInputを取得.
        var myInput: AVCaptureDeviceInput! = nil
        do {
            myInput = try AVCaptureDeviceInput(device: myDevice) as AVCaptureDeviceInput
        } catch let error {
            print(error)
        }
        
        // セッションに追加.
        if mySession.canAddInput(myInput) {
            mySession.addInput(myInput)
        } else {
            return false
        }
        
        // 出力先を設定
        myOutput = AVCaptureVideoDataOutput()
        myOutput.videoSettings = [ kCVPixelBufferPixelFormatTypeKey as AnyHashable: Int(kCVPixelFormatType_32BGRA) ]
        
        
        
        // FPSを設定
        do {
            try myDevice.lockForConfiguration()

            myDevice.activeVideoMinFrameDuration = CMTimeMake(1, 15)
            myDevice.unlockForConfiguration()
        } catch let error {
            print("lock error: \(error)")
            return false
        }
        
        // デリゲートを設定
        let queue: DispatchQueue = DispatchQueue(label: "myqueue",  attributes: [])
        myOutput.setSampleBufferDelegate(self, queue: queue)

        
        // 遅れてきたフレームは無視する
        myOutput.alwaysDiscardsLateVideoFrames = true
        
        // セッションに追加.
        if mySession.canAddOutput(myOutput) {
            mySession.addOutput(myOutput)
        } else {
            return false
        }
 
        // カメラの向きを合わせる
        for connection in myOutput.connections {
            if let conn = connection as? AVCaptureConnection {
                if conn.isVideoOrientationSupported {
                    conn.videoOrientation = AVCaptureVideoOrientation.portrait
                }
            }
        }
        
        return true
    }


    // 毎フレーム実行される処理
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!)
    {
        DispatchQueue.main.sync(execute: {
            // UIImageへ変換
            let image = CameraUtil.imageFromSampleBuffer(sampleBuffer)
            
            // 顔認識
            let faceImage = self.detector?.recognizeFace(image)
            
            // 表示
            self.imageView.image = faceImage
        })
    }
    

}

