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

class ViewController: UIViewController, CLLocationManagerDelegate, URLSessionDelegate {
    
    let locationManager = CLLocationManager()
    let motionManager = CMMotionManager()
    
    var myTableViewController: DataTableViewController!
    var myTableView: UITableView!
    
    var debugTimer: Timer?
    var duration: Double = -1.0
    var recordCount: Int = -1
    
    var x: Int64?
    var y: Int64?
    var angle: Int64?
    var magX: Double?
    var magY: Double?
    var magZ: Double?
    var mag: Double?
    var dateString: String?
    
    @IBOutlet var disk: UIImageView?
    @IBOutlet var container: UIView?
    @IBOutlet var labels: [UILabel]?
    @IBOutlet var headingLabel: UILabel?
    
    @IBOutlet weak var pitchLabel: UILabel!
    @IBOutlet weak var rollLabel: UILabel!
    @IBOutlet weak var yawLabel: UILabel!
    
    @IBOutlet weak var magneticFieldXLabel: UILabel!
    @IBOutlet weak var magneticFieldYLabel: UILabel!
    @IBOutlet weak var magneticFieldZLabel: UILabel!
    @IBOutlet weak var magneticFieldNormalizedLabel: UILabel!
    
    @IBOutlet weak var accelerometerXLabel: UILabel!
    @IBOutlet weak var accelerometerYLabel: UILabel!
    @IBOutlet weak var accelerometerZLabel: UILabel!
    
    @IBOutlet var debugLabel: UILabel!
    
    @IBOutlet weak var xTextField: UITextField!
    @IBOutlet weak var yTextField: UITextField!
    @IBOutlet weak var intervalTextField: UITextField!
    @IBOutlet weak var durationTextField: UITextField!
    
    @IBOutlet weak var shouldRecordSwitch: UISwitch!
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var recordWaySegmentedControl: UISegmentedControl!
    
    
    @IBAction func flushDataButtonTapped(_ sender: Any) {
        let alert = UIAlertController(title: "FLUSH ALL DATA", message: "I know what am I fucking doing!", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "DELETE!", style: .destructive, handler: { (alert: UIAlertAction!) in
            _ = self.myTableViewController.flushAllData()
        }))
        alert.addAction(UIAlertAction(title: "RETURN", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func shouldRecordSwitchValueChanged(_ sender: UISwitch) {
        self.xTextField.endEditing(true)
        self.yTextField.endEditing(true)
        self.intervalTextField.endEditing(true)
        self.durationTextField.endEditing(true)
        
        var interval = TimeInterval(0)
        if sender.isOn {
            interval = (TimeInterval(self.intervalTextField.text!) == nil) ? 0 : TimeInterval(self.intervalTextField.text!)!
        }

        self.motionManager.deviceMotionUpdateInterval = interval
        self.motionManager.gyroUpdateInterval = interval
        self.motionManager.accelerometerUpdateInterval = interval
        self.motionManager.magnetometerUpdateInterval = interval
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "DataTableSegue" {
            self.myTableViewController = segue.destination as! DataTableViewController
            self.myTableView = self.myTableViewController.tableView
        }
    }

    func startTimer(duraction: Double) {
        if let duration = Double(durationTextField.text!) {
            self.duration = duration
        }
        self.debugTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateTimer), userInfo: nil, repeats: true)
    }
    
    func updateTimer() {
        self.debugLabel.text = "Stop Record In \(self.duration)s"

        if self.duration-1.0 < 0.0 {
            debugTimer?.invalidate()
            self.stopRecord()
        }
        self.duration -= 1
    }
    
    func stopRecord() {
        self.shouldRecordSwitch.setOn(false, animated: true)
        self.motionManager.deviceMotionUpdateInterval = 0
        self.motionManager.gyroUpdateInterval = 0
        self.motionManager.accelerometerUpdateInterval = 0
        self.motionManager.magnetometerUpdateInterval = 0
    }
    
    func recordOnce() {
        if let x = Int64(xTextField.text!), let y = Int64(yTextField.text!) {
            self.x = x
            self.y = y
            
            xTextField.endEditing(true)
            yTextField.endEditing(true)
            intervalTextField.endEditing(true)
            durationTextField.endEditing(true)
                
            if (self.shouldRecordSwitch.isOn) {
                    _ = self.myTableViewController.insertData(x: self.x!, y: self.y!, angle: Int64(self.angle!), magx: self.magX!, magy: self.magY!, magz: self.magZ!, mag: self.mag!, date: self.dateString!)
            }
        } else {
            let alert = UIAlertController(title: "Error", message: "Please input X, Y and s", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Gotcha", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
    }
    
    func displayDate() {
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd hh:mm:ss"
        self.dateString = dateFormatter.string(from: now)
        self.dateLabel.text = "\(self.dateString!)"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.myTableViewController.displayAllData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let _ = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.displayDate), userInfo: nil, repeats: true)
        self.locationManager.delegate = self
        self.locationManager.startUpdatingHeading()
        
        self.motionManager.startDeviceMotionUpdates(using: CMAttitudeReferenceFrame.xMagneticNorthZVertical, to: OperationQueue.main) { motion, error in

            self.motionManager.showsDeviceMovementDisplay = true
            
            guard let attitude = motion?.attitude else {
                return
            }
            guard let magneticField = motion?.magneticField else {
                return
            }
            
            self.magX = Double(round(10000000*magneticField.field.x)/10000000)
            self.magY = Double(round(10000000*magneticField.field.y)/10000000)
            self.magZ = Double(round(10000000*magneticField.field.z)/10000000)
            self.mag = sqrt(self.magX!*self.magX! + self.magY!*self.magY! + self.magZ!*self.magZ!)
            
            self.magneticFieldXLabel.text = String(self.magX!)
            self.magneticFieldYLabel.text = String(self.magY!)
            self.magneticFieldZLabel.text = String(self.magZ!)
            self.magneticFieldNormalizedLabel.text = String(self.mag!)
            
            if self.recordCount == 0 {
                self.stopRecord()
                self.recordCount = -1
            }
            if self.recordWaySegmentedControl.selectedSegmentIndex == 1 && self.shouldRecordSwitch.isOn && self.duration != 0.0 {
                if self.duration == -1.0 {
                    if let duration = Double(self.durationTextField.text!), let interval = Double(self.intervalTextField.text!) {
                        self.duration = duration
                        self.startTimer(duraction: self.duration)
                        self.recordCount = (interval == 0.0) ? Int(self.duration / 0.01) : Int(self.duration / interval)
                    }
                }
                self.recordCount -= 1
                self.recordOnce()
            }
            
            self.motionManager.startAccelerometerUpdates(to: OperationQueue.main) {
                [weak self] (accelerometerData: CMAccelerometerData?, error: Error?) in
                
                let accelerometerX = Float((accelerometerData?.acceleration.x)!)
                let accelerometerY = Float((accelerometerData?.acceleration.y)!)
                let accelerometerZ = Float((accelerometerData?.acceleration.z)!)
                
                self?.accelerometerXLabel.text = "\(accelerometerX)"
                self?.accelerometerYLabel.text = "\(accelerometerY)"
                self?.accelerometerZLabel.text = "\(accelerometerZ)"
//                print("\(accelerometerData?.acceleration)")
                
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
    }
    
    var heading: CGFloat? = nil
    var headingArray: [Int64] = [0, 45, 90, 135, 180, -135, -90, -45]

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard newHeading.headingAccuracy > 0 else { return }
        
        let magnetic = newHeading.magneticHeading // the degree (-180 ~ 180)
        let readable = magnetic > 180.5 ? magnetic - 360 : magnetic // the degree (0 ~ 360)
        let headingInteger: Int64 = Int64(round(readable))
        self.angle = headingInteger
        self.headingLabel?.text = "\(headingInteger)"

        if self.recordWaySegmentedControl.selectedSegmentIndex == 0 && self.shouldRecordSwitch.isOn && headingArray[0]-1 <= headingInteger && headingInteger <= headingArray[0]+1 {
                self.debugLabel.text = "\(headingInteger)"
                self.recordOnce()
                headingArray = headingArray.shiftRight()
        }
        
        let y = CGFloat( 0 - (M_PI) * (readable/180) ) // radian
        self.heading = y
        
    }
    
}

