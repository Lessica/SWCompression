//
//  ArTests.swift
//  SWCompressionTests
//
//  Created by Lessica <82flex@gmail.com> on 2022/1/15.
//  Copyright © 2022 Timofey Solomko. All rights reserved.
//

import XCTest
import SWCompression

class ArTests: XCTestCase {

    private static let testType: String = "ar"

    func testBadFile_short() {
        XCTAssertThrowsError(try ArContainer.open(container: Data([0, 1, 2])))
    }

    func testBadFile_invalid() throws {
        // This is potentially a misleading test, since there is no way to guarantee that a file is not a AR container.
        let testData = try Constants.data(forAnswer: "test7")
        XCTAssertThrowsError(try ArContainer.open(container: testData))
    }

    func test() throws {
        let testData = try Constants.data(forTest: "test_classdump", withType: ArTests.testType)

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
    
    func testSingleFile() throws {
        let testData = try Constants.data(forTest: "test_single_file", withType: ArTests.testType)

        XCTAssertEqual(try ArContainer.formatOf(container: testData), .bsd)

        let entries = try ArContainer.open(container: testData)

        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].info.name, "debian-binary")
        XCTAssertEqual(entries[0].info.size, 4)
        XCTAssertEqual(entries[0].info.type, .regular)
        XCTAssertEqual(entries[0].info.ownerID, 0)
        XCTAssertEqual(entries[0].info.groupID, 0)
        XCTAssertEqual(entries[0].info.permissions, Permissions(rawValue: 0o644))
        XCTAssertNotNil(entries[0].info.modificationTime)
        XCTAssertEqual(Int(entries[0].info.modificationTime!.timeIntervalSinceReferenceDate), 661757961)
        XCTAssertEqual(entries[0].data, "2.0\n".data(using: .ascii))
    }
    
    func testEmptyFiles() throws {
        let testData = try Constants.data(forTest: "test_empty_files", withType: ArTests.testType)

        XCTAssertEqual(try ArContainer.formatOf(container: testData), .bsd)

        let entries = try ArContainer.open(container: testData)

        XCTAssertEqual(entries.count, 5)
        XCTAssertEqual(entries[0].info.name, "empty_file_1")
        XCTAssertEqual(entries[0].info.type, .regular)
        XCTAssertEqual(entries[0].info.size, 0)
        XCTAssertEqual(entries[0].info.ownerID, 0)
        XCTAssertEqual(entries[0].info.groupID, 0)
        XCTAssertEqual(entries[0].info.permissions, Permissions(rawValue: 0o644))
        XCTAssertNotNil(entries[0].info.modificationTime)
        XCTAssertEqual(Int(entries[0].info.modificationTime!.timeIntervalSinceReferenceDate), 661757961)
        XCTAssertEqual(entries[0].data, Data())
        
        XCTAssertEqual(entries[4].info.name, "empty_file_5")
        XCTAssertEqual(entries[4].info.type, .regular)
        XCTAssertEqual(entries[4].info.size, 0)
        XCTAssertEqual(entries[4].info.ownerID, 0)
        XCTAssertEqual(entries[4].info.groupID, 0)
        XCTAssertEqual(entries[4].info.permissions, Permissions(rawValue: 0o644))
        XCTAssertNotNil(entries[0].info.modificationTime)
        XCTAssertEqual(Int(entries[0].info.modificationTime!.timeIntervalSinceReferenceDate), 661757961)
        XCTAssertEqual(entries[4].data, Data())
    }

    func testEmptyContainer() throws {
        let testData = try Constants.data(forTest: "test_empty", withType: ArTests.testType)
        XCTAssertEqual(try ArContainer.formatOf(container: testData), .bsd)
        let entries = try ArContainer.open(container: testData)
        XCTAssertEqual(entries.isEmpty, true)
    }

    func testBigContainer() throws {
        let testData = try Constants.data(forTest: "test_big_container", withType: ArTests.testType)

        XCTAssertEqual(try ArContainer.formatOf(container: testData), .bsd)

        let entryInfoList = try ArContainer.info(container: testData)
        XCTAssertNotNil(entryInfoList.last?.size)
        XCTAssertGreaterThan(entryInfoList.last!.size!, 20_000_000)
        
        let entryList = try ArContainer.open(container: testData)
        XCTAssertNotNil(entryList.last?.data)
        XCTAssertGreaterThan(entryList.last!.data!.count, 20_000_000)
    }

    func testBigNumField() throws {
        // This file is truncated because of its size (8.6 GB): it doesn't contain any actual file data.
        let testData = try Constants.data(forTest: "test_big_num_field", withType: ArTests.testType)

        XCTAssertEqual(try ArContainer.formatOf(container: testData), .bsd)

        let entries = try ArContainer.info(container: testData)

        XCTAssertEqual(entries.count, 2)
        XCTAssertEqual(entries[1].name, "fake_huge_file")
        XCTAssertEqual(entries[1].type, .regular)
        XCTAssertEqual(entries[1].size, 8_606_060_606)
        XCTAssertEqual(entries[1].ownerID, 501)
        XCTAssertEqual(entries[1].groupID, 20)
        XCTAssertEqual(entries[1].permissions, Permissions(rawValue: 0o644))
        XCTAssertEqual(entries[1].modificationTime, Date(timeIntervalSince1970: 1581517823))
    }

    func testNegativeMtime() throws {
        let testData = try Constants.data(forTest: "test_negative_mtime", withType: ArTests.testType)

        XCTAssertEqual(try ArContainer.formatOf(container: testData), .bsd)

        let entries = try ArContainer.open(container: testData)

        XCTAssertEqual(entries.count, 3)
        XCTAssertEqual(entries[1].info.name, "control.tar.gz")
        XCTAssertEqual(entries[1].info.type, .regular)
        XCTAssertEqual(entries[1].info.size, 398)
        XCTAssertEqual(entries[1].info.ownerID, 0)
        XCTAssertEqual(entries[1].info.groupID, 0)
        XCTAssertEqual(entries[1].info.permissions, Permissions(rawValue: 0o755))
        XCTAssertEqual(entries[1].info.modificationTime, Date(timeIntervalSince1970: -597_958_170))
        XCTAssertEqual(entries[1].data?.subdata(in: 0..<3), Data([0x1f, 0x8b, 0x08]))
    }
    
    func testLongName() throws {
        let testData = try Constants.data(forTest: "test_long_name", withType: ArTests.testType)

        XCTAssertEqual(try ArContainer.formatOf(container: testData), .bsd4_4)

        let entries = try ArContainer.open(container: testData)
        
        XCTAssertEqual(entries.count, 2)
        XCTAssertEqual(entries[0].info.name, "Deb_File_Structure.svg")
        XCTAssertEqual(entries[0].info.type, .regular)
        XCTAssertEqual(entries[0].info.size, 270_136)
        XCTAssertEqual(entries[0].info.ownerID, 501)
        XCTAssertEqual(entries[0].info.groupID, 20)
        XCTAssertEqual(entries[0].info.permissions, Permissions(rawValue: 0o644))
        XCTAssertNotNil(entries[0].info.modificationTime)
        XCTAssertEqual(Int(entries[0].info.modificationTime!.timeIntervalSinceReferenceDate), 663923440)
        XCTAssertEqual(entries[0].data?.prefix(5), "<?xml".data(using: .utf8))
        XCTAssertEqual(entries[0].data?.suffix(8), "</svg>\r\n".data(using: .utf8))
        
        XCTAssertEqual(entries[1].info.name, "FileHandleBehavior.swift")
        XCTAssertEqual(entries[1].info.type, .regular)
        XCTAssertEqual(entries[1].info.size, 526)
        XCTAssertEqual(entries[1].info.ownerID, 501)
        XCTAssertEqual(entries[1].info.groupID, 20)
        XCTAssertEqual(entries[1].info.permissions, Permissions(rawValue: 0o644))
        XCTAssertNotNil(entries[1].info.modificationTime)
        XCTAssertEqual(Int(entries[1].info.modificationTime!.timeIntervalSinceReferenceDate), 663958844)
        XCTAssertEqual(entries[1].data?.prefix(13), "import Cocoa\n".data(using: .utf8))
        XCTAssertEqual(entries[1].data?.suffix(15), "dump(dataRead)\n".data(using: .utf8))
    }

}
