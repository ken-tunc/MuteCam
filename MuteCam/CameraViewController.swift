//
//  ViewController.swift
//  MuteCam
//
//  Created by ken_tunc on 2016/09/06.
//  Copyright © 2016年 ken_tunc. All rights reserved.
//

import UIKit

class CameraViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    
    var cameraManager: CameraManager!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        cameraManager = CameraManager(cameraViewController: self)
    }
    
    @IBAction func takePhoto(_ sender: UIButton) {
        if let image = cameraManager.getImage() {
            // Add image to photo album
            UIImageWriteToSavedPhotosAlbum(image, self, nil, nil)
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        cameraManager.setupAVCapture()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        cameraManager.stopAVCapture()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // Hide status bar
    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }

}

