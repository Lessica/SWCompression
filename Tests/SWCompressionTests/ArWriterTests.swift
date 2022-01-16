//
//  ArWriterTests.swift
//  SWCompressionTests
//
//  Created by Lessica <82flex@gmail.com> on 2022/1/16.
//  Copyright © 2022 Timofey Solomko. All rights reserved.
//

import XCTest
import SWCompression

class ArWriterTests: XCTestCase {
    
    private static let testType: String = "ar"
    private static let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent("TestSWCompression-" + UUID().uuidString, isDirectory: true)

    class override func setUp() {
        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)
        } catch let error {
            fatalError("ArWriterTests.setUp(): unable to create temporary directory: \(error)")
        }
    }

    class override func tearDown() {
        do {
            try FileManager.default.removeItem(at: tempDir)
        } catch let error {
            fatalError("ArWriterTests.tearDown(): unable to remove temporary directory: \(error)")
        }
    }

    private static func generateContainerData(_ entries: [ArEntry], format: ArContainer.Format = .bsd) throws -> Data {
        let tempFileUrl = tempDir.appendingPathComponent(UUID().uuidString, isDirectory: false)
        try "".write(to: tempFileUrl, atomically: true, encoding: .utf8)
        let handle = try FileHandle(forWritingTo: tempFileUrl)
        var writer = try ArWriter(fileHandle: handle, force: format)
        for entry in entries {
            try writer.append(entry)
        }
        try writer.finalize()
        try handle.closeCompat()
        return try Data(contentsOf: tempFileUrl)
    }

    func test1() throws {
        var info = ArEntryInfo(name: "file.txt")
        info.ownerID = 501
        info.groupID = 20
        info.permissions = Permissions(rawValue: 420)
        // We have to convert time interval to int, since tar can't store fractional timestamps, so we lose in accuracy.
        let intTimeInterval = Int(Date().timeIntervalSince1970)
        let date = Date(timeIntervalSince1970: Double(intTimeInterval))
        info.modificationTime = date
        info.creationTime = date
        info.accessTime = date
        let data = Data("Hello, World!\n".utf8)
        let entry = ArEntry(info: info, data: data)

        let containerData = try ArWriterTests.generateContainerData([entry])
        XCTAssertEqual(try ArContainer.formatOf(container: containerData), .bsd)
        let newEntries = try ArContainer.open(container: containerData)

        XCTAssertEqual(newEntries.count, 1)
        XCTAssertEqual(newEntries[0].info.name, "file.txt")
        XCTAssertEqual(newEntries[0].info.type, .regular)
        XCTAssertEqual(newEntries[0].info.size, 14)
        XCTAssertEqual(newEntries[0].info.ownerID, 501)
        XCTAssertEqual(newEntries[0].info.groupID, 20)
        XCTAssertEqual(newEntries[0].info.permissions, Permissions(rawValue: 420))
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
        
        let entry = ArEntry(info: info, data: dictData)
        let containerData = try ArWriterTests.generateContainerData([entry])
        XCTAssertEqual(try ArContainer.formatOf(container: containerData), .bsd)
        let newInfo = try ArContainer.open(container: containerData)[0]

        XCTAssertEqual(newInfo.info.name, "symbolic-link")
        XCTAssertEqual(newInfo.info.type, .regular)
        XCTAssertEqual(newInfo.info.permissions, Permissions(rawValue: 0o744))
        XCTAssertEqual(newInfo.info.ownerID, 250)
        XCTAssertEqual(newInfo.info.groupID, 250)
        XCTAssertEqual(newInfo.info.size, dictData.count)
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
        let entry = ArEntry(info: info, data: Data())
        
        XCTAssertThrowsError(try ArWriterTests.generateContainerData([entry], format: .bsd))

        let containerData = try ArWriterTests.generateContainerData([entry], format: .bsd4_4)
        XCTAssertEqual(try ArContainer.formatOf(container: containerData), .bsd4_4)
        let newInfo = try ArContainer.open(container: containerData)[0].info
        
        XCTAssertEqual(newInfo.name, info.name)
    }

    func testVeryLongName() throws {
        var info = ArEntryInfo(name: "")
        info.name = "path/to/"
        info.name.append(String(repeating: "readme/", count: 25))
        info.name.append("readme.txt")
        let entry = ArEntry(info: info, data: Data())

        let containerData = try ArWriterTests.generateContainerData([entry], format: .bsd4_4)
        XCTAssertEqual(try ArContainer.formatOf(container: containerData), .bsd4_4)
        let newInfo = try ArContainer.open(container: containerData)[0].info

        XCTAssertEqual(newInfo.name, info.name)
    }
    
    func testNegativeMtime() throws {
        let date = Date(timeIntervalSince1970: -1300000)
        var info = ArEntryInfo(name: "file.txt")
        info.modificationTime = date
        let entry = ArEntry(info: info, data: Data())

        let containerData = try ArWriterTests.generateContainerData([entry])
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
        testData = try Constants.data(forTest: "test_classdump", withType: ArWriterTests.testType)
        XCTAssertEqual(try ArContainer.formatOf(container: testData), .bsd)
        
        let testEnteries = try ArContainer.open(container: testData)
        XCTAssertEqual(testEnteries.count, 3)
        
        testData = try ArWriterTests.generateContainerData(testEnteries, format: .bsd4_4)
        XCTAssertEqual(try ArContainer.formatOf(container: testData), .bsd4_4)
        
        testData = try ArWriterTests.generateContainerData(testEnteries, format: .bsd)
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
