//
//  magneticDB.swift
//  magnetic-indoor-positioning
//
//  Created by Alex on 5/1/2017.
//  Copyright © 2017年 plusa. All rights reserved.
//

import SQLite

class magneticDB {
    private let db: Connection?
    private let data = Table("magnetic")
    private let id = Expression<Int64>("id")
    private let x = Expression<Int64>("x")
    private let y = Expression<Int64>("y")
    private let magx = Expression<Double>("magx")
    private let magy = Expression<Double>("magy")
    private let magz = Expression<Double>("magz")
    private let time = Expression<String>("time")
    
    private init() {
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
