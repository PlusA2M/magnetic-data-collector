//
//  magneticDB.swift
//  magnetic-indoor-positioning
//

import SQLite

class MagneticDB {
    fileprivate let db: Connection?
    fileprivate let data = Table("data")
    
    fileprivate let id = Expression<Int64>("id")
    fileprivate let x = Expression<Int64>("x")
    fileprivate let y = Expression<Int64>("y")
    fileprivate let angle = Expression<Int64>("angle")
    fileprivate let magx = Expression<Double>("magx")
    fileprivate let magy = Expression<Double>("magy")
    fileprivate let magz = Expression<Double>("magz")
    fileprivate let mag = Expression<Double>("mag")
    fileprivate let date = Expression<String>("date")
    
    init() {
        let path = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true
            ).first!
        
        do {
            db = try Connection("\(path)/data.sqlite3")
        } catch {
            db = nil
            print ("Unable to open database")
        }
        
        createTable()
    }
    
    func createTable() {
        do {
            try db!.run(data.create(ifNotExists: true) { table in
                table.column(id, primaryKey: .autoincrement)
                table.column(x)
                table.column(y)
                table.column(angle)
                table.column(magx)
                table.column(magy)
                table.column(magz)
                table.column(mag)
                table.column(date, unique: true)
            })
        } catch {
            print("Unable to create table")
        }
    }
    
    func insertData(valueX: Int64, valueY: Int64, valueAngle: Int64, valueMagx: Double, valueMagy: Double, valueMagz: Double, valueMag: Double, valueDate: String) -> Int64? {
        do {
            let rowid = try db?.run(data.insert(x <- valueX, y <- valueY, angle <- valueAngle, magx <- valueMagx, magy <- valueMagy, magz <- valueMagz, mag <- valueMag, date <- valueDate))
            print("inserted id: \(rowid)")
            return rowid!
        } catch {
            print("insertion failed: \(error)")
            return nil
        }
    }
}
