//
//  DataTableViewController.swift
//  magnetic-indoor-positioning
//
//  Created by meiinlam on 21/2/2017.
//  Copyright © 2017年 plusa. All rights reserved.
//

import UIKit

class DataTableViewController: UITableViewController {
    
    var data = [[]]
    var row: Int = 0
    let magneticDB: MagneticDB = MagneticDB()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.delegate = self
        self.tableView.dataSource = self
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return data.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return data[section].count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =
            tableView.dequeueReusableCell(
                withIdentifier: "Cell", for: indexPath as IndexPath) as
        UITableViewCell
        
        // 顯示的內容
        if let myLabel = cell.textLabel {
            myLabel.text =
            "\(data[indexPath.section][indexPath.row])"
        }
        
        return cell

    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            self.deleteData(forRowAtIndexPath: indexPath)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    func insertData(x: Int64, y: Int64, angle: Int64, magx: Double, magy: Double, magz: Double, mag: Double, date: String) {
        let simplfiedDate = date.substring(with: date.index(from: 2)..<date.endIndex)
        let cellLabel = "(\(x), \(y))(\(angle)): \(mag) - \(simplfiedDate)"
        self.data[0].append(cellLabel)
        let indexPath = IndexPath(row: data[0].count-1, section: 0)
        
        self.tableView.beginUpdates()
        self.tableView.insertRows(at: [indexPath], with: .fade)
        self.tableView.endUpdates()
        
        self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        
        if let rowid = self.magneticDB.insertData(x: x, y: y, angle: angle, magx: magx, magy: magy, magz: magz, mag: mag, date: date) {
            self.tableView.cellForRow(at: indexPath)?.tag = Int(rowid)
        }
        
    }
    
    func flushAllData() {
        self.data[0] = [""]
        self.tableView.reloadData()
        _ = self.magneticDB.flushAllData()
    }
    
    func displayAllData() {
        self.magneticDB.queryData() { (tmp) -> () in
            for dict in tmp {
                let x = dict["x"], y = dict["y"], angle = dict["angle"], mag = dict["mag"], date = dict["date"]!.substring(with: dict["date"]!.index(from: 2)..<dict["date"]!.endIndex)
                let cellLabel = "(\(x!), \(y!))(\(angle!)): \(mag!) - \(date)"
                let indexPath = IndexPath(row: self.row, section:0)
                self.data[0].append(cellLabel)
                self.tableView.beginUpdates()
                self.tableView.insertRows(at: [indexPath], with: .none)
                self.tableView.endUpdates()
            }
        }
    }
    
    
    func deleteData(forRowAtIndexPath: IndexPath) {
        let cell = self.tableView.cellForRow(at: forRowAtIndexPath)
        let regexp = try! NSRegularExpression(pattern: "\\(([0-9]), ([0-9])\\)\\(([-]?[0-9]{1,3})\\): ([0-9]*\\.[0-9]*) - ([0-9]{1,4}/[0-9]{2}/[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2})")
        let cellLabelString = (cell?.textLabel?.text)!
        let cellLabelNSString = NSString(string: cellLabelString)

        let arrayOfMatches = regexp.matches(in: cellLabelString as String, range: NSMakeRange(0, cellLabelNSString.length)).map {
            result in
            (1..<result.numberOfRanges).map{ result.rangeAt($0).location != NSNotFound ? cellLabelNSString.substring(with: result.rangeAt($0)) : "" }
            }
        if arrayOfMatches.count > 0 {
            let arrayOfData = arrayOfMatches[0]
            if let x = Int64(arrayOfData[0]), let y = Int64(arrayOfData[1]), let angle = Int64(arrayOfData[2]), let mag = NumberFormatter().number(from: arrayOfData[3])?.doubleValue, let date = String(arrayOfData[4]) {
                self.data[forRowAtIndexPath.section].remove(at: forRowAtIndexPath.row)
                self.magneticDB.deleteData(x: x, y: y, angle: angle, mag: mag, date: "20\(date)")
                tableView.deleteRows(at: [forRowAtIndexPath], with: .fade)
            }
        } else {
            print("Regular Expression cannot match")
        }
    }
}
