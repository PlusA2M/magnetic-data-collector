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
    
    let magneticDB: MagneticDB = MagneticDB()
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
    @IBOutlet weak var periodTextField: UITextField!
    
    @IBOutlet weak var onlineUpdateSwitch: UISwitch!
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var recordWaySegmentedControl: UISegmentedControl!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "DataTableSegue" {
            self.myTableViewController = segue.destination as! DataTableViewController
            self.myTableView = self.myTableViewController.tableView
        }
    }

    func startTimer(duraction: Double) {
        if let duration = Double(periodTextField.text!) {
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
        self.onlineUpdateSwitch.setOn(false, animated: true)
        myTableViewController.data = [["FINISHED"]]
        self.myTableView.reloadData()
    }
    
    func startRecord() {
        if let x = xTextField.text, let y = yTextField.text, let interval = intervalTextField.text {
            guard let x = Int64(x), let y = Int64(y), let interval = TimeInterval(interval) else {
                let alert = UIAlertController(title: "Error", message: "Please input X, Y and s", preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: "Gotcha", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            self.locationManager.startUpdatingHeading()
            self.motionManager.showsDeviceMovementDisplay = true
            
            self.x = x
            self.y = y
            xTextField.endEditing(true)
            yTextField.endEditing(true)
            intervalTextField.endEditing(true)
            self.motionManager.deviceMotionUpdateInterval = interval
            self.motionManager.startDeviceMotionUpdates(using: CMAttitudeReferenceFrame.xMagneticNorthZVertical, to: OperationQueue.main) { motion, error in
                guard let attitude = motion?.attitude else {
                    return
                }

                self.motionManager.accelerometerUpdateInterval = interval
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

                guard let magneticField = motion?.magneticField else {
                    return
                }
                
                self.magX = Double(round(10000000*magneticField.field.x)/10000000)
                self.magY = Double(round(10000000*magneticField.field.y)/10000000)
                self.magZ = Double(round(10000000*magneticField.field.z)/10000000)
                self.mag = sqrt(self.magX!*self.magX! + self.magY!*self.magY! + self.magZ!*self.magZ!)
                
                if (self.onlineUpdateSwitch.isOn) {
                    let backgroundQueue = DispatchQueue.global(qos: .background)
                    backgroundQueue.async {
                        let _ = self.magneticDB.insertData(valueX: self.x!, valueY: self.y!, valueAngle: Int64(self.angle!), valueMagx: self.magX!, valueMagy: self.magY!, valueMagz: self.magZ!, valueMag: self.mag!, valueDate: self.dateString!)
                    }
                }
                
                self.magneticFieldXLabel.text = "\(self.magX!)"
                self.magneticFieldYLabel.text = "\(self.magY!)"
                self.magneticFieldZLabel.text = "\(self.magZ!)"
                self.magneticFieldNormalizedLabel.text = "\(self.mag!)"
                self.dateLabel.text = "\(self.dateString!)"

                let cellLabel = "Point(\(self.x!), \(self.y!))(\(self.angle!)): \(self.mag!) - \(self.dateString!)"
                self.myTableViewController.data[0].append(cellLabel)
                self.myTableView.reloadData()
                
                let lastCellIndexPath = IndexPath(row: self.myTableViewController.data[0].count-1, section: 0)
                self.myTableView.scrollToRow(at: lastCellIndexPath, at: .bottom, animated: false)
                
            }
        } else {
            print("xTextField or yTextField has error.")
        }
    }

    func recordOnce() {
        if let x = Int64(xTextField.text!), let y = Int64(yTextField.text!) {
            self.x = x
            self.y = y
            
            xTextField.endEditing(true)
            yTextField.endEditing(true)
            intervalTextField.endEditing(true)
                
            if (self.onlineUpdateSwitch.isOn) {
                let backgroundQueue = DispatchQueue.global(qos: .background)
                backgroundQueue.async {
                    _ = self.magneticDB.insertData(valueX: self.x!, valueY: self.y!, valueAngle: Int64(self.angle!), valueMagx: self.magX!, valueMagy: self.magY!, valueMagz: self.magZ!, valueMag: self.mag!, valueDate: self.dateString!)
                    let cellLabel = "Point(\(self.x!), \(self.y!))(\(self.angle!)): \(self.mag!) - \(self.dateString!)"
                    self.myTableViewController.data[0].append(cellLabel)
                    self.myTableView.reloadData()
                    self.myTableView.setNeedsDisplay()
                    let lastCellIndexPath = IndexPath(row: self.myTableViewController.data[0].count-1, section: 0)
//                    self.myTableView.scrollToRow(at: lastCellIndexPath, at: .bottom, animated: false)
                }
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
    
    func displayAllData() {
        self.magneticDB.queryData() { (tmp) -> () in
            for dict in tmp {
                let x = dict["x"], y = dict["y"], angle = dict["angle"], mag = dict["mag"], date = dict["date"]
                let cellLabel = "Point(\(x!), \(y!))(\(angle!)): \(mag!) - \(date!)"
                myTableViewController.data[0].append(cellLabel)
            }
        }
        self.myTableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.displayAllData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let _ = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.displayDate), userInfo: nil, repeats: true)
        self.locationManager.delegate = self
        self.locationManager.startUpdatingHeading()
        
        let interval = TimeInterval(intervalTextField.text!)!
        self.motionManager.showsDeviceMovementDisplay = true
        self.motionManager.deviceMotionUpdateInterval = interval
        self.motionManager.magnetometerUpdateInterval = interval
        self.motionManager.startDeviceMotionUpdates(using: CMAttitudeReferenceFrame.xMagneticNorthZVertical, to: OperationQueue.main) { motion, error in
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
            
            if self.recordWaySegmentedControl.selectedSegmentIndex == 1 && self.onlineUpdateSwitch.isOn {
                if self.duration == -1.0 {
                    if let duration = Double(self.periodTextField.text!) {
                        self.duration = duration
                        self.startTimer(duraction: self.duration)
                    }
                }
                self.recordOnce()
            }
            
            self.motionManager.accelerometerUpdateInterval = interval
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

        if self.recordWaySegmentedControl.selectedSegmentIndex == 0 && self.onlineUpdateSwitch.isOn && headingArray[0]-1 <= headingInteger && headingInteger <= headingArray[0]+1 {
                self.debugLabel.text = "\(headingInteger)"
                self.recordOnce()
                headingArray = headingArray.shiftRight()
        }
        
        let y = CGFloat( 0 - (M_PI) * (readable/180) ) // radian
        self.heading = y
        
    }
    
}

