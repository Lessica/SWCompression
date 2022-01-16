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
            isFinished = try reader.process { (entry: ArEntry?) -> Bool in
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
                }
                
                entriesCount += 1
                return false
            }
        }
        XCTAssertEqual(entriesCount, 3)

        try testHandle.closeCompat()
    }
    
//    func testEmptyFile() throws {
//        let testHandle = try Constants.handle(forTest: "test_empty_file", withType: TarReaderTests.testType)
//        var reader = TarReader(fileHandle: testHandle)
//        try reader.process { (entry: TarEntry?) in
//            XCTAssertNotNil(entry)
//            XCTAssertEqual(entry!.info.name, "empty_file")
//            XCTAssertEqual(entry!.info.type, .regular)
//            XCTAssertEqual(entry!.info.size, 0)
//            XCTAssertEqual(entry!.info.ownerID, 501)
//            XCTAssertEqual(entry!.info.groupID, 20)
//            XCTAssertEqual(entry!.info.ownerUserName, "timofeysolomko")
//            XCTAssertEqual(entry!.info.ownerGroupName, "staff")
//            XCTAssertEqual(entry!.info.permissions, Permissions(rawValue: 420))
//            XCTAssertNil(entry!.info.comment)
//            XCTAssertEqual(entry!.data, Data())
//
//        }
//        try testHandle.closeCompat()
//    }
//
//    func testEmptyDirectory() throws {
//        let testHandle = try Constants.handle(forTest: "test_empty_dir", withType: TarReaderTests.testType)
//        var reader = TarReader(fileHandle: testHandle)
//        try reader.process { (entry: TarEntry?) in
//            XCTAssertNotNil(entry)
//            XCTAssertEqual(entry!.info.name, "empty_dir/")
//            XCTAssertEqual(entry!.info.type, .directory)
//            XCTAssertEqual(entry!.info.size, 0)
//            XCTAssertEqual(entry!.info.ownerID, 501)
//            XCTAssertEqual(entry!.info.groupID, 20)
//            XCTAssertEqual(entry!.info.ownerUserName, "timofeysolomko")
//            XCTAssertEqual(entry!.info.ownerGroupName, "staff")
//            XCTAssertEqual(entry!.info.permissions, Permissions(rawValue: 493))
//            XCTAssertNil(entry!.info.comment)
//            XCTAssertNil(entry!.data)
//        }
//        try testHandle.closeCompat()
//    }
//
//    func testOnlyDirectoryHeader() throws {
//        // This tests the correct handling of the situation when there is nothing in the container but one basic header,
//        // even no EOF marker (two blocks of zeros).
//        let testHandle = try Constants.handle(forTest: "test_only_dir_header", withType: TarReaderTests.testType)
//        var reader = TarReader(fileHandle: testHandle)
//        try reader.process { (entry: TarEntry?) in
//            XCTAssertNotNil(entry)
//            XCTAssertEqual(entry!.info.name, "empty_dir/")
//            XCTAssertEqual(entry!.info.type, .directory)
//            XCTAssertEqual(entry!.info.size, 0)
//            XCTAssertEqual(entry!.info.ownerID, 501)
//            XCTAssertEqual(entry!.info.groupID, 20)
//            XCTAssertEqual(entry!.info.ownerUserName, "timofeysolomko")
//            XCTAssertEqual(entry!.info.ownerGroupName, "staff")
//            XCTAssertEqual(entry!.info.permissions, Permissions(rawValue: 493))
//            XCTAssertNil(entry!.info.comment)
//            XCTAssertNil(entry!.data)
//
//        }
//        try testHandle.closeCompat()
//    }
//
//    func testEmptyContainer() throws {
//        let testHandle = try Constants.handle(forTest: "test_empty_cont", withType: TarReaderTests.testType)
//        var reader = TarReader(fileHandle: testHandle)
//        XCTAssertNil(try reader.read())
//        try testHandle.closeCompat()
//    }
//
//    func testBigContainer() throws {
//        let testHandle = try Constants.handle(forTest: "SWCompressionSourceCode", withType: TarReaderTests.testType)
//        var reader = TarReader(fileHandle: testHandle)
//        while try reader.read() != nil { }
//        try testHandle.closeCompat()
//    }
//
//    func testUnicodeUstar() throws {
//        let testHandle = try Constants.handle(forTest: "test_unicode_ustar", withType: TarReaderTests.testType)
//        var reader = TarReader(fileHandle: testHandle)
//        try reader.process { (entry: TarEntry?) in
//            XCTAssertNotNil(entry)
//            XCTAssertEqual(entry!.info.name, "текстовый файл.answer")
//            XCTAssertEqual(entry!.info.type, .regular)
//            XCTAssertEqual(entry!.info.ownerID, 501)
//            XCTAssertEqual(entry!.info.groupID, 20)
//            XCTAssertEqual(entry!.info.ownerUserName, "timofeysolomko")
//            XCTAssertEqual(entry!.info.ownerGroupName, "staff")
//            XCTAssertEqual(entry!.info.permissions, Permissions(rawValue: 420))
//            XCTAssertNil(entry!.info.comment)
//            let answerData = try Constants.data(forAnswer: "текстовый файл")
//            XCTAssertEqual(entry!.data, answerData)
//
//        }
//        try testHandle.closeCompat()
//    }
//
//    func testUnicodePax() throws {
//        let testHandle = try Constants.handle(forTest: "test_unicode_pax", withType: TarReaderTests.testType)
//        var reader = TarReader(fileHandle: testHandle)
//        try reader.process { (entry: TarEntry?) in
//            XCTAssertNotNil(entry)
//            XCTAssertEqual(entry!.info.name, "текстовый файл.answer")
//            XCTAssertEqual(entry!.info.type, .regular)
//            XCTAssertEqual(entry!.info.ownerID, 501)
//            XCTAssertEqual(entry!.info.groupID, 20)
//            XCTAssertEqual(entry!.info.ownerUserName, "timofeysolomko")
//            XCTAssertEqual(entry!.info.ownerGroupName, "staff")
//            XCTAssertEqual(entry!.info.permissions, Permissions(rawValue: 420))
//            XCTAssertNil(entry!.info.comment)
//            let answerData = try Constants.data(forAnswer: "текстовый файл")
//            XCTAssertEqual(entry!.data, answerData)
//
//        }
//        try testHandle.closeCompat()
//    }
//
//    func testGnuIncrementalFormat() throws {
//        let testHandle = try Constants.handle(forTest: "test_gnu_inc_format", withType: TarReaderTests.testType)
//        var reader = TarReader(fileHandle: testHandle)
//        var isFinished = false
//        var entriesCount = 0
//        while !isFinished {
//            isFinished = try reader.process { (entry: TarEntry?) -> Bool in
//                if entry == nil {
//                    return true
//                }
//                XCTAssertEqual(entry!.info.ownerID, 501)
//                XCTAssertEqual(entry!.info.groupID, 20)
//                XCTAssertEqual(entry!.info.ownerUserName, "timofeysolomko")
//                XCTAssertEqual(entry!.info.ownerGroupName, "staff")
//                XCTAssertNotNil(entry!.info.accessTime)
//                XCTAssertNotNil(entry!.info.creationTime)
//                entriesCount += 1
//                return false
//            }
//        }
//        XCTAssertEqual(entriesCount, 3)
//        try testHandle.closeCompat()
//    }
//
//    // This test is impossible to implement using TarReader since the test file doesn't contain actual entry data.
//    // func testBigNumField() throws { }
//
//    func testNegativeMtime() throws {
//        let testHandle = try Constants.handle(forTest: "test_negative_mtime", withType: TarReaderTests.testType)
//        var reader = TarReader(fileHandle: testHandle)
//        try reader.process { (entry: TarEntry?) in
//            XCTAssertEqual(entry!.info.name, "file")
//            XCTAssertEqual(entry!.info.type, .regular)
//            XCTAssertEqual(entry!.info.size, 27)
//            XCTAssertEqual(entry!.info.ownerID, 501)
//            XCTAssertEqual(entry!.info.groupID, 20)
//            XCTAssertEqual(entry!.info.ownerUserName, "timofeysolomko")
//            XCTAssertEqual(entry!.info.ownerGroupName, "staff")
//            XCTAssertEqual(entry!.info.permissions, Permissions(rawValue: 420))
//            XCTAssertEqual(entry!.info.modificationTime, Date(timeIntervalSince1970: -313006414))
//            XCTAssertNil(entry!.info.comment)
//            XCTAssertEqual(entry!.data, "File with negative mtime.\n\n".data(using: .utf8))
//        }
//        // Test that reading after reaching EOF returns nil.
//        XCTAssertNil(try reader.read())
//        try testHandle.closeCompat()
//    }

}
