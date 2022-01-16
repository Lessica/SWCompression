//
//  ArHeader.swift
//  SWCompression
//
//  Created by Lessica <82flex@gmail.com> on 2022/1/15.
//  Copyright © 2022 Timofey Solomko. All rights reserved.
//

import Foundation
import BitByteData

/// This type represents the low-level header structure of the AR format.
struct ArHeader {
    
    static let signature = "!<arch>\n"
    static let commonLength = 60
    static let longNameFlag = "#1/"
    
    enum HeaderEntryType {
        case signature
        case common(ContainerEntryType)
    }
    
    let name: String
    private(set) var mtime: Date?
    let uid: Int?
    let gid: Int?
    let permissions: Permissions?
    
    /**
     Length of long name.
     
     - Note: For `.bsd` format, it is always `0`.
     */
    let extraNameSize: Int
    let dataSize: Int
    
    /**
     It equals to `extraNameSize + dataSize`.
     */
    var size: Int { extraNameSize + dataSize }
    
    let type: HeaderEntryType
    
    let format: ArContainer.Format
    let blockStartIndex: Int
    
    init(_ reader: LittleEndianByteReader) throws {
        self.blockStartIndex = reader.offset
        let name = reader.arCString(maxLength: 16)
        
        if let mtime = reader.arInt(maxLength: 12) {
            self.mtime = Date(timeIntervalSince1970: TimeInterval(mtime))
        }
        
        self.uid = reader.arInt(maxLength: 6)
        self.gid = reader.arInt(maxLength: 6)
        
        if let posixAttributes = reader.tarInt(maxLength: 8) {
            // Sometimes file mode field also contains unix type, so we need to filter it out.
            self.permissions = Permissions(rawValue: UInt32(truncatingIfNeeded: posixAttributes) & 0xFFF)
        } else {
            self.permissions = nil
        }
        
        guard let size = reader.arInt(maxLength: 10)
            else { throw ArError.wrongField("size") }
        
        let endChar = reader.arCString(maxLength: 2)
        guard endChar == "`\n" else { throw ArError.wrongEndChar }
        
        self.type = .common(.regular)
        if name.hasPrefix(ArHeader.longNameFlag) {
            guard let longNameSize = Int(name.dropFirst(ArHeader.longNameFlag.count)) else {
                throw ArError.wrongField("identifier")
            }
            guard reader.bytesLeft >= longNameSize else {
                throw InternalArError.headerNeedsMoreBytes(longNameSize)
            }
            self.extraNameSize = longNameSize
            self.name = reader.arCString(maxLength: longNameSize)
            self.dataSize = size - longNameSize
            self.format = .bsd4_4
        } else {
            self.extraNameSize = 0
            self.name = name
            self.dataSize = size
            self.format = .bsd
        }
    }
    
}
