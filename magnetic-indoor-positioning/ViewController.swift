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

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate, URLSessionDelegate {
    
    let locationManager = CLLocationManager()
    
    let motionManager = CMMotionManager()
    
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
    
    @IBOutlet weak var onlineUpdateSwitch: UISwitch!
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var recordWaySegmentedControl: UISegmentedControl!
    
    @IBAction func timerButtonPressed(_ sender: Any) {
        let alert = UIAlertController(title: "Duration", message: "Please input the duration:", preferredStyle: .alert)
        alert.addTextField(configurationHandler: {
            (textField) in
            textField.placeholder = "Duration in seconds"
        })
        alert.addAction(UIAlertAction(title: "Start", style: .default, handler: {
            (_) in self.startRecord()
            if let textField = alert.textFields?[0] {
                if let text = Double(textField.text!) {
                    self.perform(#selector(self.stopRecord), with: nil, afterDelay: text)
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func stopRecord() {
        self.onlineUpdateSwitch.setOn(false, animated: true)
        self.data = [["FINISHED"]]
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
                    //creating a task to send the post request
                    let backgroundQueue = DispatchQueue.global(qos: .background)
                    backgroundQueue.async {
                        self.magneticDB.insertData(valueX: self.x!, valueY: self.y!, valueAngle: Int64(self.angle!), valueMagx: self.magX!, valueMagy: self.magY!, valueMagz: self.magZ!, valueMag: self.mag!, valueDate: self.dateString!)
                    }
                }
                
                self.magneticFieldXLabel.text = "\(self.magX!)"
                self.magneticFieldYLabel.text = "\(self.magY!)"
                self.magneticFieldZLabel.text = "\(self.magZ!)"
                self.magneticFieldNormalizedLabel.text = "\(self.mag!)"
                self.dateLabel.text = "\(self.dateString!)"

                let cellLabel = "Point(\(self.x!), \(self.y!))(\(self.angle!)): \(self.mag!) - \(self.dateString!)"
                self.data[0].append(cellLabel)
                self.myTableView.reloadData()
                
                let lastCellIndexPath = IndexPath(row: self.data[0].count-1, section: 0)
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
                
            if (self.onlineUpdateSwitch.isOn && self.recordWaySegmentedControl.selectedSegmentIndex == 0) {
                let backgroundQueue = DispatchQueue.global(qos: .background)
                backgroundQueue.async {
                    self.magneticDB.insertData(valueX: self.x!, valueY: self.y!, valueAngle: Int64(self.angle!), valueMagx: self.magX!, valueMagy: self.magY!, valueMagz: self.magZ!, valueMag: self.mag!, valueDate: self.dateString!)
                    let cellLabel = "Point(\(self.x!), \(self.y!))(\(self.angle!)): \(self.mag!) - \(self.dateString!)"
                    self.data[0].append(cellLabel)
                    self.myTableView.reloadData()
                }
            }
            let lastCellIndexPath = IndexPath(row: self.data[0].count-1, section: 0)
            self.myTableView.scrollToRow(at: lastCellIndexPath, at: .bottom, animated: false)
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
    
    var data = [[]]

    @IBOutlet weak var myTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.displayAllData()
        myTableView.register(
            UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        myTableView.delegate = self
        myTableView.dataSource = self
        
        myTableView.separatorStyle = .singleLine
        myTableView.separatorInset =
            UIEdgeInsetsMake(0, 20, 0, 20)
        
        myTableView.allowsSelection = true
        myTableView.allowsMultipleSelection = false
        
        self.view.addSubview(myTableView)
    }
    
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return data[section].count
    }
    
    func tableView(_ tableView: UITableView,
                           cellForRowAt indexPath: IndexPath)
        -> UITableViewCell {
            // 取得 tableView 目前使用的 cell
            let cell =
                tableView.dequeueReusableCell(
                    withIdentifier: "Cell", for: indexPath as IndexPath) as
            UITableViewCell
            
            // 設置 Accessory 按鈕樣式
            if indexPath.section == 1 {
                if indexPath.row == 0 {
                    cell.accessoryType = .checkmark
                } else if indexPath.row == 1 {
                    cell.accessoryType = .detailButton
                } else if indexPath.row == 2 {
                    cell.accessoryType =
                        .detailDisclosureButton
                } else if indexPath.row == 3 {
                    cell.accessoryType = .disclosureIndicator
                }
            }
            
            // 顯示的內容
            if let myLabel = cell.textLabel {
                myLabel.text = 
                "\(data[indexPath.section][indexPath.row])"
            }
            
            return cell
    }
    
    func numberOfSections(
        in tableView: UITableView) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView,
                   titleForHeaderInSection section: Int) -> String? {
        let title = section == 0 ? "DATA" : "DATA 2"
        return title
    }
    
    func displayAllData() {
        self.magneticDB.queryData() { (tmp) -> () in
            for dict in tmp {
                let x = dict["x"], y = dict["y"], angle = dict["angle"], mag = dict["mag"], date = dict["date"]
                let cellLabel = "Point(\(x!), \(y!))(\(angle!)): \(mag!) - \(date!)"
                self.data[0].append(cellLabel)
            }
        }
        self.myTableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let _ = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.displayDate), userInfo: nil, repeats: true)
        self.locationManager.delegate = self
        self.locationManager.startUpdatingHeading()
        
        self.motionManager.showsDeviceMovementDisplay = true
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
            
            self.motionManager.accelerometerUpdateInterval = 0
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
        
//        self.locationManager.stopUpdatingHeading()
//        self.motionManager.stopDeviceMotionUpdates()
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

        if self.recordWaySegmentedControl.selectedSegmentIndex == 0 && headingArray[0]-1 <= headingInteger && headingArray[0]+1 >= headingInteger {
                print("\(headingInteger)")
                self.recordOnce()
                headingArray = headingArray.shiftRight()
        }
        
        let y = CGFloat( 0 - (M_PI) * (readable/180) ) // radian
        self.heading = y
        
    }
    
}

