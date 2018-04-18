//
//  AttachmentVideoViewController.swift
//  ochamochi
//
//

import UIKit
import AVFoundation
import AVKit

class AttachmentVideoViewController: AVPlayerViewController {
    var url: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.player = AVPlayer(url: URL(string: url!)!)
        self.player?.play()
    }
}
