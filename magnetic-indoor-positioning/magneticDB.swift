//
//  magneticDB.swift
//  magnetic-indoor-positioning
//
//  Created by Alex on 5/1/2017.
//  Copyright © 2017年 plusa. All rights reserved.
//

import SQLite

class magneticDB {
    fileprivate let db: Connection?
    fileprivate let data = Table("magnetic")
    fileprivate let id = Expression<Int64>("id")
    fileprivate let x = Expression<Int64>("x")
    fileprivate let y = Expression<Int64>("y")
    fileprivate let magx = Expression<Double>("magx")
    fileprivate let magy = Expression<Double>("magy")
    fileprivate let magz = Expression<Double>("magz")
    fileprivate let time = Expression<String>("time")
    
    fileprivate init() {
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
                table.column(id, primaryKey: true)
                table.column(x)
                table.column(y)
                table.column(magx)
                table.column(magy)
                table.column(magz)
                table.column(time, unique: true)
            })
        } catch {
            print("Unable to create table")
        }
    }
}
