//
//  ArReaderTests.swift
//  SWCompressionTests
//
//  Created by Lessica <82flex@gmail.com> on 2022/1/15.
//  Copyright © 2022 Timofey Solomko. All rights reserved.
//

import XCTest
import SWCompression

class ArReaderTests: XCTestCase {

    private static let testType: String = "ar"

    func testBadFile_invalid() throws {
        // This is potentially a misleading test, since there is no way to guarantee that a file is not a AR container.
        let testHandle = try Constants.handle(forTest: "test7", withType: "answer")
        var reader: ArReader?
        XCTAssertThrowsError(reader = try ArReader(fileHandle: testHandle))
        XCTAssertNil(reader)
        try testHandle.closeCompat()
    }

    func test() throws {
        let testHandle = try Constants.handle(forTest: "test_classdump", withType: ArReaderTests.testType)
        var reader = try ArReader(fileHandle: testHandle)
        
        var isFinished = false
        var entriesCount = 0
        while !isFinished {
            isFinished = try reader.process { entry -> Bool in
                guard let entry = entry else {
                    return true
                }
                
                if entriesCount == 0 {
                    XCTAssertEqual(entry.info.name, "debian-binary")
                    XCTAssertEqual(entry.info.size, 4)
                    XCTAssertEqual(entry.info.type, .regular)
                    XCTAssertEqual(entry.info.ownerID, 0)
                    XCTAssertEqual(entry.info.groupID, 0)
                    XCTAssertEqual(entry.info.permissions, Permissions(rawValue: 0o644))
                    XCTAssertNotNil(entry.info.modificationTime)
                    XCTAssertEqual(Int(entry.info.modificationTime!.timeIntervalSinceReferenceDate), 661757961)
                    XCTAssertEqual(entry.data, "2.0\n".data(using: .ascii))
                }
                else if entriesCount == 1 {
                    XCTAssertEqual(entry.info.name, "control.tar.gz")
                    XCTAssertEqual(entry.info.size, 337)
                    XCTAssertEqual(entry.info.type, .regular)
                    XCTAssertEqual(entry.info.ownerID, 0)
                    XCTAssertEqual(entry.info.groupID, 0)
                    XCTAssertEqual(entry.info.permissions, Permissions(rawValue: 0o644))
                    XCTAssertNotNil(entry.info.modificationTime)
                    XCTAssertEqual(Int(entry.info.modificationTime!.timeIntervalSinceReferenceDate), 661757961)
                    XCTAssertEqual(entry.data?.subdata(in: 0..<3), Data([0x1f, 0x8b, 0x08]))
                }
                else if entriesCount == 2 {
                    XCTAssertEqual(entry.info.name, "data.tar.lzma")
                    XCTAssertEqual(entry.info.size, 162_493)
                    XCTAssertEqual(entry.info.type, .regular)
                    XCTAssertEqual(entry.info.ownerID, 0)
                    XCTAssertEqual(entry.info.groupID, 0)
                    XCTAssertEqual(entry.info.permissions, Permissions(rawValue: 0o644))
                    XCTAssertNotNil(entry.info.modificationTime)
                    XCTAssertEqual(Int(entry.info.modificationTime!.timeIntervalSinceReferenceDate), 661757961)
                    XCTAssertEqual(entry.data?.suffix(3), Data([0xa2, 0x1e, 0x8f]))
                }
                
                entriesCount += 1
                return false
            }
        }
        XCTAssertEqual(entriesCount, 3)
        
        // Test that reading after reaching EOF returns nil.
        XCTAssertNil(try reader.read())

        try testHandle.closeCompat()
    }
    
    func testSingleFile() throws {
        let testHandle = try Constants.handle(forTest: "test_single_file", withType: ArReaderTests.testType)
        var reader = try ArReader(fileHandle: testHandle)
        try reader.process { entry in
            XCTAssertNotNil(entry)
            guard let entry = entry else { return }
            
            XCTAssertEqual(entry.info.name, "debian-binary")
            XCTAssertEqual(entry.info.size, 4)
            XCTAssertEqual(entry.info.type, .regular)
            XCTAssertEqual(entry.info.ownerID, 0)
            XCTAssertEqual(entry.info.groupID, 0)
            XCTAssertEqual(entry.info.permissions, Permissions(rawValue: 0o644))
            XCTAssertNotNil(entry.info.modificationTime)
            XCTAssertEqual(Int(entry.info.modificationTime!.timeIntervalSinceReferenceDate), 661757961)
            XCTAssertEqual(entry.data, "2.0\n".data(using: .ascii))
        }
        
        // Test that reading after reaching EOF returns nil.
        XCTAssertNil(try reader.read())
        
        try testHandle.closeCompat()
    }
    
    func testEmptyFiles() throws {
        let testHandle = try Constants.handle(forTest: "test_empty_files", withType: ArReaderTests.testType)
        var reader = try ArReader(fileHandle: testHandle)
        
        var fileIndex = 1
        var isFinished = false
        while !isFinished {
            isFinished = try reader.process { entry in
                guard let entry = entry else {
                    fileIndex -= 1
                    return true
                }
                
                XCTAssertEqual(entry.info.name, "empty_file_\(fileIndex)")
                XCTAssertEqual(entry.info.type, .regular)
                XCTAssertEqual(entry.info.size, 0)
                XCTAssertEqual(entry.info.ownerID, 0)
                XCTAssertEqual(entry.info.groupID, 0)
                XCTAssertEqual(entry.info.permissions, Permissions(rawValue: 0o644))
                XCTAssertNotNil(entry.info.modificationTime)
                XCTAssertEqual(Int(entry.info.modificationTime!.timeIntervalSinceReferenceDate), 661757961)
                XCTAssertEqual(entry.data, Data())
                
                fileIndex += 1
                return false
            }
        }
        
        XCTAssertEqual(fileIndex, 5)
        
        // Test that reading after reaching EOF returns nil.
        XCTAssertNil(try reader.read())
        
        try testHandle.closeCompat()
    }

    func testEmptyContainer() throws {
        let testHandle = try Constants.handle(forTest: "test_empty", withType: ArReaderTests.testType)
        var reader = try ArReader(fileHandle: testHandle)
        XCTAssertNil(try reader.read())
        try testHandle.closeCompat()
    }
    
    func testBigContainer() throws {
        let testHandle = try Constants.handle(forTest: "test_big_container", withType: ArReaderTests.testType)
        var reader = try ArReader(fileHandle: testHandle)
        var hasLargeEntry = false
        while !hasLargeEntry {
            hasLargeEntry = try reader.process { entry -> Bool in
                guard let entrySize = entry?.info.size else { return false }
                return entrySize > 20_000_000
            }
        }
        XCTAssertTrue(hasLargeEntry)
    }
    
    // This test is impossible to implement using ArReader since the test file doesn't contain actual entry data.
    // func testBigNumField() throws { }

    func testNegativeMtime() throws {
        let testHandle = try Constants.handle(forTest: "test_negative_mtime", withType: ArReaderTests.testType)
        var reader = try ArReader(fileHandle: testHandle)
        
        let firstEntry = try reader.read()
        XCTAssertNotNil(firstEntry)
        
        XCTAssertEqual(firstEntry!.info.name, "debian-binary")
        XCTAssertEqual(firstEntry!.info.size, 4)
        XCTAssertEqual(firstEntry!.info.type, .regular)
        XCTAssertEqual(firstEntry!.info.ownerID, 0)
        XCTAssertEqual(firstEntry!.info.groupID, 0)
        XCTAssertEqual(firstEntry!.info.permissions, Permissions(rawValue: 0o644))
        XCTAssertNotNil(firstEntry!.info.modificationTime)
        XCTAssertEqual(firstEntry!.info.modificationTime, Date(timeIntervalSinceReferenceDate: 619650970))
        XCTAssertEqual(firstEntry!.data, "2.0\n".data(using: .ascii))
        
        try reader.process { entry in
            XCTAssertNotNil(entry)
            guard let entry = entry else { return }
            
            XCTAssertEqual(entry.info.name, "control.tar.gz")
            XCTAssertEqual(entry.info.type, .regular)
            XCTAssertEqual(entry.info.size, 398)
            XCTAssertEqual(entry.info.ownerID, 0)
            XCTAssertEqual(entry.info.groupID, 0)
            XCTAssertEqual(entry.info.permissions, Permissions(rawValue: 0o755))
            XCTAssertEqual(entry.info.modificationTime, Date(timeIntervalSince1970: -597_958_170))
            XCTAssertEqual(entry.data?.subdata(in: 0..<3), Data([0x1f, 0x8b, 0x08]))
        }
        try reader.next()
        
        // Test that reading after reaching EOF returns nil.
        XCTAssertNil(try reader.read())
        
        try testHandle.closeCompat()
    }
    
    func testLongName() throws {
        let testHandle = try Constants.handle(forTest: "test_long_name", withType: ArReaderTests.testType)
        var reader = try ArReader(fileHandle: testHandle)
        
        var entriesCount = 0
        var isFinished = false
        while !isFinished {
            isFinished = try reader.process { entry in
                guard let entry = entry else {
                    return true
                }
                
                if entriesCount == 0 {
                    XCTAssertEqual(entry.info.name, "Deb_File_Structure.svg")
                    XCTAssertEqual(entry.info.type, .regular)
                    XCTAssertEqual(entry.info.size, 270_136)
                    XCTAssertEqual(entry.info.ownerID, 501)
                    XCTAssertEqual(entry.info.groupID, 20)
                    XCTAssertEqual(entry.info.permissions, Permissions(rawValue: 0o644))
                    XCTAssertNotNil(entry.info.modificationTime)
                    XCTAssertEqual(Int(entry.info.modificationTime!.timeIntervalSinceReferenceDate), 663923440)
                    XCTAssertEqual(entry.data?.prefix(5), "<?xml".data(using: .ascii))
                    XCTAssertEqual(entry.data?.suffix(8), "</svg>\r\n".data(using: .ascii))
                }
                else if entriesCount == 1 {
                    XCTAssertEqual(entry.info.name, "FileHandleBehavior.swift")
                    XCTAssertEqual(entry.info.type, .regular)
                    XCTAssertEqual(entry.info.size, 526)
                    XCTAssertEqual(entry.info.ownerID, 501)
                    XCTAssertEqual(entry.info.groupID, 20)
                    XCTAssertEqual(entry.info.permissions, Permissions(rawValue: 0o644))
                    XCTAssertNotNil(entry.info.modificationTime)
                    XCTAssertEqual(Int(entry.info.modificationTime!.timeIntervalSinceReferenceDate), 663958844)
                    XCTAssertEqual(entry.data?.prefix(13), "import Cocoa\n".data(using: .utf8))
                    XCTAssertEqual(entry.data?.suffix(15), "dump(dataRead)\n".data(using: .utf8))
                }
                
                entriesCount += 1
                return false
            }
        }
        XCTAssertEqual(entriesCount, 2)
        
        // Test that reading after reaching EOF returns nil.
        XCTAssertNil(try reader.read())
        
        try testHandle.closeCompat()
    }

}
