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
    static let length = 60
    
    enum HeaderEntryType {
        case signature
        case normal(ContainerEntryType)
    }
    
    let name: String
    private(set) var mtime: Date?
    let uid: Int?
    let gid: Int?
    let permissions: Permissions?
    let size: Int
    let type: HeaderEntryType
    
    let format: ArContainer.Format
    let blockStartIndex: Int
    
    init(_ reader: LittleEndianByteReader) throws {
        self.blockStartIndex = reader.offset
        self.name = reader.arCString(maxLength: 16)
        
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
            else { throw ArError.wrongField }
        self.size = size
        
        let endChar = reader.arCString(maxLength: 2)
        guard endChar == "`\n" else { throw ArError.wrongEndChar }
        
        self.type = .normal(.regular)
        self.format = .bsd
    }
    
}
