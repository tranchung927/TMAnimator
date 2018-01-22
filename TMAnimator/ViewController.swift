//
//  ViewController.swift
//  TMAnimator
//
//  Created by Chung-Sama on 2018/01/22.
//  Copyright © 2018 Chung-Sama. All rights reserved.
//

import UIKit
import AVKit

struct Coordinate {
    var col: Int
    var row: Int
    var size: CGSize
    var originPoint: CGPoint {
        return CGPoint(x: CGFloat(col) * size.width , y: CGFloat(row) * size.height)
    }
    var originVideo: CGPoint {
        return CGPoint(x: CGFloat(col) * size.width , y: UIScreen.main.bounds.size.width - (CGFloat(row) + 1) * size.height)
    }
}

class ViewController: UIViewController, VideoExportServiceDelegate {

    @IBOutlet weak var pixelImageView: UIView!
    
    var itemSize: CGSize = CGSize(width: 0, height: 0)
    var numberOfCol: Int = 50
    var numberOfRow: Int = 50
    var indexsItem: [Coordinate] = []
    
    var duration = 0.005
    
    var playerViewController: AVPlayerViewController?
    let documentsDirectoryURL : URL = {
        let path = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first! as String
        return  URL(fileURLWithPath: path)
    }()
    
    var localBlankVideoPath: URL {
        get {
            return documentsDirectoryURL.appendingPathComponent("video").appendingPathExtension("mp4")
        }
    }
    
    var videoID = NSUUID().uuidString
    
    var localVideoPath: URL {
        get {
            return documentsDirectoryURL.appendingPathComponent("\(videoID)").appendingPathExtension("mp4")
        }
    }
    
    let videoService = VideoService()
    let videoExportService = VideoExportService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        videoExportService.delegate = self
        itemSize = CGSize(width: UIScreen.main.bounds.size.width / CGFloat(numberOfCol), height: UIScreen.main.bounds.size.width / CGFloat(numberOfRow))
        (0..<numberOfCol).forEach { col in
            (0..<numberOfRow).forEach { row in
                indexsItem.append(Coordinate(col: col, row: row, size: itemSize))
            }
        }
    }
    
    @IBAction func fill(sender: UIBarButtonItem) {
        videoService.makeBlankVideo(blankImage: UIImage(named: "whiteBg")!, videoSize: pixelImageView.bounds.size, outputPath: localBlankVideoPath, duration: 15) { () -> Void in
            print("localBlankVideoPath : \(self.localBlankVideoPath)")
            self.exportVideo()
        }
    }
    @IBAction func play(_ sender: UIBarButtonItem) {
        if pixelImageView.layer.sublayers != nil {
            for layer in pixelImageView.layer.sublayers! {
                layer.removeFromSuperlayer()
            }
        }
        let layer = createLayerAnimation(forExport: false)
        pixelImageView.layer.addSublayer(layer)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func createLayerAnimation(startTime: Double = CACurrentMediaTime(), forExport: Bool) -> CALayer {
        let parentLayer = CALayer()
        for coordinate in indexsItem {
            let layer = CALayer()
            layer.backgroundColor = UIColor.blue.cgColor
            layer.opacity = 0
            layer.frame = CGRect(origin: forExport ? coordinate.originVideo : coordinate.originPoint , size: itemSize)
            let triggerTime = (Double(coordinate.row * numberOfCol) + Double(coordinate.col)) * duration + startTime
            let animation = displayAnimation(beginTime: triggerTime)

            layer.add(animation, forKey: "opacity")
            parentLayer.addSublayer(layer)
        }
        return parentLayer
    }
    
    
    
    func exportVideo() {
        let input = VideoExportInput()
        videoID = NSUUID().uuidString
        input.videoPath = self.localVideoPath
        
        let asset = AVAsset(url: self.localBlankVideoPath)
        input.videoAsset = asset
        DispatchQueue.main.async {
            input.videoFrame = self.pixelImageView.bounds
            input.range = CMTimeRangeMake(kCMTimeZero, asset.duration)
            let layer = self.createLayerAnimation(startTime: AVCoreAnimationBeginTimeAtZero, forExport: true)
            input.animationLayer = layer
            self.videoExportService.exportVideoWithInput(input: input)
        }
    }
    
    func displayAnimation(beginTime: Double) -> CAAnimation {
        let animation = CABasicAnimation()
        animation.keyPath = "opacity"
        animation.fromValue = 0
        animation.toValue = 1
        animation.fillMode = kCAFillModeForwards
        animation.duration = 0.01
        animation.beginTime = beginTime
        animation.repeatCount = 0
        animation.isRemovedOnCompletion = false
        return animation
    }
    private func playVideo() {
        let url = self.localVideoPath
        let player = AVPlayer(url: url)
        self.playerViewController = AVPlayerViewController()
        self.playerViewController!.player = player
        self.present(self.playerViewController!, animated: true) {
            self.playerViewController!.player!.play()
        }
    }

    func videoExportServiceExportSuccess() {
        print("sucess")
        DispatchQueue.main.async {
            self.playVideo()
        }
    }
    
    func videoExportServiceExportFailedWithError(error: NSError) {
        print(error)
    }
    
    func videoExportServiceExportProgress(progress: Float) {
        
    }
    
}

