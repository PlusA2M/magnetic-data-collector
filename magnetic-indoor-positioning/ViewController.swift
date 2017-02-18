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
    @IBOutlet weak var magneticFieldNormalizedLabel: UILabel!
    
    @IBOutlet weak var magneticFieldXProgress: UIProgressView!
    @IBOutlet weak var magneticFieldYProgress: UIProgressView!
    @IBOutlet weak var magneticFieldZProgress: UIProgressView!
    @IBOutlet weak var magneticFieldNormalizedProgress: UIProgressView!
    
    @IBOutlet weak var accelerometerXLabel: UILabel!
    @IBOutlet weak var accelerometerYLabel: UILabel!
    @IBOutlet weak var accelerometerZLabel: UILabel!
    @IBOutlet weak var accelerometerXProgress: UIProgressView!
    @IBOutlet weak var accelerometerYProgress: UIProgressView!
    @IBOutlet weak var accelerometerZProgress: UIProgressView!
    
    @IBOutlet var debugLabel: UILabel!
    
    @IBOutlet weak var xTextField: UITextField!
    @IBOutlet weak var yTextField: UITextField!
    @IBOutlet weak var intervalTextField: UITextField!
    
    @IBOutlet weak var onlineUpdateSwitch: UISwitch!
    
    @IBOutlet weak var dateLabel: UILabel!
    
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
    
    @IBAction func stopButtonPressed(_ sender: Any) {
        stopRecord()
        
    }
    
    func stopRecord() {
        self.motionManager.stopDeviceMotionUpdates()
        let alert = UIAlertController(title: "Stop", message: "Magnetometer Updates Stopped", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Gotcha", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        self.data = [["FINISHED"]]
        self.myTableView.reloadData()
    }
    
    @IBAction func startButtonPressed(_ sender: Any) {
        startRecord()
    }
    
    func startRecord() {
        self.data[0].append("TEST")
        if let x = xTextField.text, let y = yTextField.text, let interval = intervalTextField.text {
            guard let x = Int(x), let y = Int(y), let interval = TimeInterval(interval) else {
                let alert = UIAlertController(title: "Error", message: "Please input X, Y and s", preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: "Gotcha", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            self.locationManager.startUpdatingHeading()
            self.motionManager.showsDeviceMovementDisplay = true
            
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

                guard let magneticField = motion?.magneticField else {
                    return
                }
                
                let magX = Double(round(10000000*magneticField.field.x)/10000000)
                let magY = Double(round(10000000*magneticField.field.y)/10000000)
                let magZ = Double(round(10000000*magneticField.field.z)/10000000)
                let mag = sqrt(magX*magX + magY*magY + magZ*magZ)
                //created URL
                let requestURL = URL(string: self.URL_INSERT_DATA)!
                var request = URLRequest(url: requestURL)
                
                //creating http parameters
                let now = Date()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy/MM/dd hh:mm:ss"
                let dateString = dateFormatter.string(from: now)
                let postParameters = "x=\(x)&y=\(y)&magx=\(magX)&magy=\(magY)&magz=\(magZ)&date=\(dateString)"
                
                //setting the HTTP header and adding the parameters to request body
                request.httpMethod = "POST"
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
                request.httpBody = postParameters.data(using: String.Encoding.utf8)
                
                
                if (self.onlineUpdateSwitch.isOn) {
                    //creating a task to send the post request
                    let backgroundQueue = DispatchQueue.global(qos: .background)
                    backgroundQueue.async {
                        let session = URLSession.shared
                        session.dataTask(with: request) {
                            data, response, error in
                            guard let data = data, let _ = response, error == nil else {
                                print("error: \(error)")
                                return
                            }
                            
                            //print response value
                            //print(String(data: data!, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue)) as Any)
                            
                            //parsing the response
                            self.debugLabel?.numberOfLines = 0
                            self.debugLabel?.text = ""
                            do {
                                //converting resonse to NSDictionary
                                let myJSON =  try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String : AnyObject]
                                //parsing the json
                                if let myJSON = myJSON {
                                    for parseJSON in myJSON  {
                                        print("\(parseJSON.key) : \(parseJSON.value)")
                                        self.debugLabel.text = self.debugLabel?.text?.appending("\(parseJSON.key) : \(parseJSON.value)\n")
                                    }
                                } else {
                                    print(String(data: data, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue)) as Any)
                                }
                            } catch {
                                print(error)
                            }
                            
                            }.resume()
                    }
                }
                
                self.magneticFieldXLabel.text = "\(magX)"
                self.magneticFieldYLabel.text = "\(magY)"
                self.magneticFieldZLabel.text = "\(magZ)"
                self.magneticFieldNormalizedLabel.text = "\(mag)"
                self.dateLabel.text = "\(dateString)"
                
                
//                let originalCellLabel = "x: \(oriMagX), y:\(oriMagY), z:\(oriMagZ) -\(dateFormatter.string(from: now))"
                let cellLabel = "\(magX)|\(magY)|\(magZ) - \(dateFormatter.string(from: now))"
//                self.data[0][0] = originalCellLabel
//                self.data[0][1] = compareCellLabel
                self.data[0].append(cellLabel)
                self.myTableView.reloadData()
                
                let lastCellIndexPath = IndexPath(row: self.data[0].count-1, section: 0)
                self.myTableView.scrollToRow(at: lastCellIndexPath, at: .bottom, animated: false)
                
                self.magneticFieldXProgress.setProgress(Float(abs(magX)), animated: true)
                self.magneticFieldYProgress.setProgress(Float(abs(magY)), animated: true)
                self.magneticFieldZProgress.setProgress(Float(abs(magZ)), animated: true)
                self.magneticFieldNormalizedProgress.setProgress(Float(abs(mag)), animated: true)
                
            }
        } else {
            print("xTextField or yTextField has error.")
        }
    }
    
    func displayDate() {
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd hh:mm:ss"
        let dateString = dateFormatter.string(from: now)
        
        self.dateLabel.text = "\(dateString)"
    }
    
    let URL_INSERT_DATA = "http://findermacao.com/indoor-positioning/insert.php"
    
    var data = [["DATA START:"]]
    var myTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.displayDate), userInfo: nil, repeats: true)
        self.locationManager.delegate = self
        
        let fullScreenSize = UIScreen.main.bounds.size
        
        // 建立 UITableView 並設置原點及尺寸
        myTableView = UITableView(frame: CGRect(
            x: 0, y: fullScreenSize.height / 2 - 10,
            width: fullScreenSize.width,
            height: fullScreenSize.height / 2),
                                      style: .grouped)
        
        // 註冊 cell
        myTableView.register(
            UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        // 設置委任對象
        myTableView.delegate = self
        myTableView.dataSource = self
        
        // 分隔線的樣式
        myTableView.separatorStyle = .singleLine
        
        // 分隔線的間距 四個數值分別代表 上、左、下、右 的間距
        myTableView.separatorInset =
            UIEdgeInsetsMake(0, 20, 0, 20)
        
        // 是否可以點選 cell
        myTableView.allowsSelection = true
        
        // 是否可以多選 cell
        myTableView.allowsMultipleSelection = false
        
        // 加入到畫面中
        self.view.addSubview(myTableView)
    }
    
    // 必須實作的方法：每一組有幾個 cell
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return data[section].count
    }
    
    // 必須實作的方法：每個 cell 要顯示的內容
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
    
    // 有幾組 section
    func numberOfSections(
        in tableView: UITableView) -> Int {
        return data.count
    }
    
    // 每個 section 的標題
    func tableView(_ tableView: UITableView,
                   titleForHeaderInSection section: Int) -> String? {
        let title = section == 0 ? "DATA" : "DATA 2"
        return title
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.locationManager.startUpdatingHeading()
        
        self.motionManager.showsDeviceMovementDisplay = true
        self.motionManager.startDeviceMotionUpdates(using: CMAttitudeReferenceFrame.xMagneticNorthZVertical, to: OperationQueue.main) { motion, error in
            guard let attitude = motion?.attitude else {
                return
            }
            
//            self.motionManager.accelerometerUpdateInterval = 0.1
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

