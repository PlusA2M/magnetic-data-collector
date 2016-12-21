//
//  ViewController.swift
//  magnetic-indoor-positioning
//
//  Created by PlusA2M on 8/11/2016.
//  Copyright © 2016年 PlusA. All rights reserved.
//


import UIKit
import CoreLocation
import CoreMotion

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    let locationManager = CLLocationManager()
    
    let motionManager = CMMotionManager()
    
    @IBOutlet var disk: UIImageView?
    
    @IBOutlet var container: UIView?
    
    @IBOutlet var labels: [UILabel]?
    
    @IBOutlet var headingLabel: UILabel?
    
    @IBOutlet weak var pitchLabel: UILabel!
    @IBOutlet weak var rollLabel: UILabel!
    @IBOutlet weak var yawLabel: UILabel!
    @IBOutlet weak var pitchProgress: UIProgressView!
    @IBOutlet weak var rollProgress: UIProgressView!
    @IBOutlet weak var yawProgress: UIProgressView!
    
    @IBOutlet weak var magneticFieldXLabel: UILabel!
    @IBOutlet weak var magneticFieldYLabel: UILabel!
    @IBOutlet weak var magneticFieldZLabel: UILabel!
    @IBOutlet weak var magneticFieldXProgress: UIProgressView!
    @IBOutlet weak var magneticFieldYProgress: UIProgressView!
    @IBOutlet weak var magneticFieldZProgress: UIProgressView!
    
    @IBOutlet var debugLabel: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.locationManager.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.locationManager.startUpdatingHeading()
        
        self.motionManager.startMagnetometerUpdates(to: OperationQueue.main) { magnetometer, error in
            guard let magneticField = magnetometer?.magneticField else {
                return
            }
            
            let x = magneticField.x
            let y = magneticField.y
            let z = magneticField.z
            
            self.magneticFieldXLabel.text = "\(x)"
            self.magneticFieldYLabel.text = "\(y)"
            self.magneticFieldZLabel.text = "\(z)"
            
            self.magneticFieldXProgress.setProgress(Float(abs(x)), animated: true)
            self.magneticFieldYProgress.setProgress(Float(abs(y)), animated: true)
            self.magneticFieldZProgress.setProgress(Float(abs(z)), animated: true)
            
        }
        
        self.motionManager.showsDeviceMovementDisplay = true
        self.motionManager.startDeviceMotionUpdates(using: CMAttitudeReferenceFrame.xArbitraryCorrectedZVertical, to: OperationQueue.main) { motion, error in
            guard let attitude = motion?.attitude else {
                return
            }
            
            
            print("\(motion?.magneticField.accuracy.hashValue)")
            print("\(motion?.magneticField.field)")
            

            
            let roll = CGFloat(attitude.roll)
            let pitch = CGFloat(attitude.pitch)
            let yaw = self.heading ?? 0 // Pitch (x), Roll (y), Yaw (z)
            //print(attitude)
            
            self.pitchLabel?.text = "\( (180 / M_PI) * (attitude.pitch) )"
            self.rollLabel?.text = "\( (180 / M_PI) * (attitude.roll) )"
            self.yawLabel?.text = "\( (180 / M_PI) * (attitude.yaw) )"
            
            self.pitchProgress.setProgress(Float(abs((180 / M_PI) * (attitude.pitch) / 90)), animated: true)
            self.rollProgress.setProgress(Float(abs((180 / M_PI) * (attitude.roll) / 180)), animated: true)
            self.yawProgress.setProgress(Float(abs((180 / M_PI) * (attitude.yaw) / 180)), animated: true)
            
            var diskTransform = CATransform3DIdentity
            diskTransform.m34 = 1.0/500.0
            diskTransform = CATransform3DRotate(diskTransform, roll, 0, 1, 0)
            diskTransform = CATransform3DRotate(diskTransform, pitch, -1, 0, 0)
            diskTransform = CATransform3DRotate(diskTransform, yaw, 0, 0, 1)
            self.disk?.layer.transform = diskTransform
            self.container?.layer.transform = diskTransform
            
            var labelTransform = CATransform3DIdentity
            labelTransform.m34 = 1.0/500.0
            labelTransform = CATransform3DRotate(labelTransform, yaw, 0, 0, -1)
            if abs(roll) > CGFloat(M_PI_2) {
                labelTransform = CATransform3DRotate(labelTransform, CGFloat(M_PI), 0, -1, 0)
            }
            for label in self.labels ?? [] {
                label.layer.transform = labelTransform
            }
            
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.locationManager.stopUpdatingHeading()
        self.motionManager.stopDeviceMotionUpdates()
    }
    
    var heading: CGFloat? = nil
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard newHeading.headingAccuracy > 0 else { return }
        
        let magnetic = newHeading.magneticHeading // the degree (-180 ~ 180)
        
        let readable = magnetic > 180.5 ? magnetic - 360 : magnetic // the degree (0 ~ 360)
        self.headingLabel?.text = "\(Int(round(readable)))"
        
        let y = CGFloat( 0 - (M_PI) * (readable/180) ) // radian
        self.heading = y
        
    }
    
}

