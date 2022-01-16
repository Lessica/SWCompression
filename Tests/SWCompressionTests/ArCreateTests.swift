//
//  ArCreateTests.swift
//  SWCompressionTests
//
//  Created by Lessica <82flex@gmail.com> on 2022/1/15.
//  Copyright © 2022 Timofey Solomko. All rights reserved.
//

import XCTest
import SWCompression

class ArCreateTests: XCTestCase {
    
    private static let testType: String = "ar"

    func test1() throws {
        var info = ArEntryInfo(name: "file.txt")
        info.ownerID = 501
        info.groupID = 20
        info.permissions = Permissions(rawValue: 0o644)
        
        // We have to convert time interval to int, since ar can't store fractional timestamps, so we lose in accuracy.
        let intTimeInterval = Int(Date().timeIntervalSince1970)
        let date = Date(timeIntervalSince1970: Double(intTimeInterval))
        info.modificationTime = date
        info.creationTime = date
        info.accessTime = date

        let data = Data("Hello, World!\n".utf8)
        let entry = ArEntry(info: info, data: data)
        let containerData = try ArContainer.create(from: [entry])
        XCTAssertEqual(try ArContainer.formatOf(container: containerData), .bsd)
        let newEntries = try ArContainer.open(container: containerData)

        XCTAssertEqual(newEntries.count, 1)
        XCTAssertEqual(newEntries[0].info.name, "file.txt")
        XCTAssertEqual(newEntries[0].info.type, .regular)
        XCTAssertEqual(newEntries[0].info.size, 14)
        XCTAssertEqual(newEntries[0].info.ownerID, 501)
        XCTAssertEqual(newEntries[0].info.groupID, 20)
        XCTAssertEqual(newEntries[0].info.permissions, Permissions(rawValue: 0o644))
        XCTAssertEqual(newEntries[0].info.modificationTime, date)
        XCTAssertNil(newEntries[0].info.creationTime)
        XCTAssertNil(newEntries[0].info.accessTime)
        XCTAssertEqual(newEntries[0].data, data)
    }

    func test2() throws {
        let dict = [
            "SWCompression/Tests/AR": "value",
            "key": "valuevaluevaluevaluevaluevaluevaluevaluevaluevaluevaluevaluevaluevaluevaluevaluevaluevalue22"
        ]
        let dictData = try JSONEncoder().encode(dict)

        var info = ArEntryInfo(name: "symbolic-link")
        info.accessTime = Date(timeIntervalSince1970: 1)
        info.creationTime = Date(timeIntervalSince1970: 2)
        info.modificationTime = Date(timeIntervalSince1970: 0)
        info.permissions = Permissions(rawValue: 0o644)
        info.permissions?.insert(.executeOwner)
        info.ownerID = 250
        info.groupID = 250

        let containerData = try ArContainer.create(from: [ArEntry(info: info, data: dictData)])
        XCTAssertEqual(try ArContainer.formatOf(container: containerData), .bsd)
        let newInfo = try ArContainer.open(container: containerData)[0]

        XCTAssertEqual(newInfo.info.name, "symbolic-link")
        XCTAssertEqual(newInfo.info.type, .regular)
        XCTAssertEqual(newInfo.info.permissions?.rawValue, 0o744)
        XCTAssertEqual(newInfo.info.ownerID, 250)
        XCTAssertEqual(newInfo.info.groupID, 250)
        XCTAssertEqual(newInfo.info.size, 137)
        XCTAssertEqual(newInfo.info.modificationTime?.timeIntervalSince1970, 0)
        XCTAssertNil(newInfo.info.accessTime?.timeIntervalSince1970)
        XCTAssertNil(newInfo.info.creationTime?.timeIntervalSince1970)
        XCTAssertEqual(newInfo.data, dictData)
    }

    func testLongName() throws {
        var info = ArEntryInfo(name: "")
        info.name = "path/to/"
        info.name.append(String(repeating: "readme/", count: 15))
        info.name.append("readme.txt")
        
        XCTAssertThrowsError(try ArContainer.create(from: [ArEntry(info: info, data: Data())]))

        let containerData = try ArContainer.create(from: [ArEntry(info: info, data: Data())], force: .bsd4_4)
        XCTAssertEqual(try ArContainer.formatOf(container: containerData), .bsd4_4)
        let newInfo = try ArContainer.open(container: containerData)[0].info

        // This name should fit into ustar format using "prefix" field
        XCTAssertEqual(newInfo.name, info.name)
    }

    func testVeryLongName() throws {
        var info = ArEntryInfo(name: "")
        info.name = "path/to/"
        info.name.append(String(repeating: "readme/", count: 25))
        info.name.append("readme.txt")

        let containerData = try ArContainer.create(from: [ArEntry(info: info, data: Data())], force: .bsd4_4)
        XCTAssertEqual(try ArContainer.formatOf(container: containerData), .bsd4_4)
        let newInfo = try ArContainer.open(container: containerData)[0].info

        XCTAssertEqual(newInfo.name, info.name)
    }
    
    func testNegativeMtime() throws {
        let date = Date(timeIntervalSince1970: -1300000)
        var info = ArEntryInfo(name: "file.txt")
        info.modificationTime = date

        let containerData = try ArContainer.create(from: [ArEntry(info: info, data: Data())])
        XCTAssertEqual(try ArContainer.formatOf(container: containerData), .bsd)
        let newInfo = try ArContainer.open(container: containerData)[0].info

        XCTAssertEqual(newInfo.name, "file.txt")
        XCTAssertEqual(newInfo.type, .regular)
        XCTAssertEqual(newInfo.size, 0)
        XCTAssertEqual(newInfo.modificationTime?.timeIntervalSince1970, -1300000)
        XCTAssertEqual(newInfo.permissions, Permissions(rawValue: 0o644))
        XCTAssertEqual(newInfo.ownerID, 0)
        XCTAssertEqual(newInfo.groupID, 0)
        XCTAssertNil(newInfo.accessTime)
        XCTAssertNil(newInfo.creationTime)
    }
    
    func testDebianPackage() throws {
        var testData: Data
        testData = try Constants.data(forTest: "test_classdump", withType: ArCreateTests.testType)
        XCTAssertEqual(try ArContainer.formatOf(container: testData), .bsd)
        
        let testEnteries = try ArContainer.open(container: testData)
        XCTAssertEqual(testEnteries.count, 3)
        
        testData = try ArContainer.create(from: testEnteries, force: .bsd4_4)
        XCTAssertEqual(try ArContainer.formatOf(container: testData), .bsd4_4)
        
        testData = try ArContainer.create(from: testEnteries, force: .bsd)
        XCTAssertEqual(try ArContainer.formatOf(container: testData), .bsd)
        
        let entries = try ArContainer.open(container: testData)
        XCTAssertEqual(entries.count, 3)
        
        XCTAssertEqual(entries[0].info.name, "debian-binary")
        XCTAssertEqual(entries[0].info.size, 4)
        XCTAssertEqual(entries[0].info.type, .regular)
        XCTAssertEqual(entries[0].info.ownerID, 0)
        XCTAssertEqual(entries[0].info.groupID, 0)
        XCTAssertEqual(entries[0].info.permissions, Permissions(rawValue: 0o644))
        XCTAssertNotNil(entries[0].info.modificationTime)
        XCTAssertEqual(Int(entries[0].info.modificationTime!.timeIntervalSinceReferenceDate), 661757961)
        XCTAssertEqual(entries[0].data, "2.0\n".data(using: .ascii))
        
        XCTAssertEqual(entries[1].info.name, "control.tar.gz")
        XCTAssertEqual(entries[1].info.size, 337)
        XCTAssertEqual(entries[1].info.type, .regular)
        XCTAssertEqual(entries[1].info.ownerID, 0)
        XCTAssertEqual(entries[1].info.groupID, 0)
        XCTAssertEqual(entries[1].info.permissions, Permissions(rawValue: 0o644))
        XCTAssertEqual(entries[1].info.modificationTime, entries[0].info.modificationTime)
        XCTAssertEqual(entries[1].data?.subdata(in: 0..<3), Data([0x1f, 0x8b, 0x08]))
        
        XCTAssertEqual(entries[2].info.name, "data.tar.lzma")
        XCTAssertEqual(entries[2].info.size, 162_493)
        XCTAssertEqual(entries[2].info.type, .regular)
        XCTAssertEqual(entries[2].info.ownerID, 0)
        XCTAssertEqual(entries[2].info.groupID, 0)
        XCTAssertEqual(entries[2].info.permissions, Permissions(rawValue: 0o644))
        XCTAssertEqual(entries[2].info.modificationTime, entries[0].info.modificationTime)
        XCTAssertEqual(entries[2].data?.suffix(3), Data([0xa2, 0x1e, 0x8f]))
    }

}
