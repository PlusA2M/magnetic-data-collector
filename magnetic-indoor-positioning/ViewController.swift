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
import SQLite

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
    
    
    @IBOutlet weak var accelerometerXLabel: UILabel!
    @IBOutlet weak var accelerometerYLabel: UILabel!
    @IBOutlet weak var accelerometerZLabel: UILabel!
    @IBOutlet weak var accelerometerXProgress: UIProgressView!
    @IBOutlet weak var accelerometerYProgress: UIProgressView!
    @IBOutlet weak var accelerometerZProgress: UIProgressView!
    
    @IBOutlet var debugLabel: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.locationManager.delegate = self
        
//        do {
//
//            let insert = data.insert(locx <- 0, locy <- 0, magx <- 0.1, magy <- 0.2, magz <- 0.3, time <- "2017-01-05 17:53:11")
//            _ = try db.run(insert)
//            
//            for _ in try db.prepare(data) {
//                print("id: \(data[locx]), locy: \(data[locy]), time: \(data[time])")
//            }
//             SELECT * FROM "users"
//            
//            let alice = users.filter(id == rowid)
//            
//            try db.run(alice.update(email <- email.replace("mac.com", with: "me.com")))
//            // UPDATE "users" SET "email" = replace("email", 'mac.com', 'me.com')
//            // WHERE ("id" = 1)
//
//            try db.run(alice.delete())
//            // DELETE FROM "users" WHERE ("id" = 1)
//            
//            try db.scalar(data.count) // 0
//            // SELECT count(*) FROM "users"
//        } catch {
//            print("anything")
//        }
        
        
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
            
            self.motionManager.accelerometerUpdateInterval = 0.1
            self.motionManager.startAccelerometerUpdates(to: OperationQueue.main) {
                [weak self] (accelerometerData: CMAccelerometerData?, error: Error?) in
                
                let accelerometerX = Float((accelerometerData?.acceleration.x)!)
                let accelerometerY = Float((accelerometerData?.acceleration.y)!)
                let accelerometerZ = Float((accelerometerData?.acceleration.z)!)
                
                self?.accelerometerXLabel.text = "\(accelerometerX)"
                self?.accelerometerYLabel.text = "\(accelerometerY)"
                self?.accelerometerZLabel.text = "\(accelerometerZ)"
//                print("\(accelerometerData?.acceleration)")
                
                self?.accelerometerXProgress.setProgress(abs(accelerometerX), animated: true)
                self?.accelerometerYProgress.setProgress(abs(accelerometerY), animated: true)
                self?.accelerometerZProgress.setProgress(abs(accelerometerZ), animated: true)
                
            }
            
//            print("\(motion?.magneticField.accuracy.hashValue)")
//            print("\(motion?.magneticField.field)")
            

            
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

