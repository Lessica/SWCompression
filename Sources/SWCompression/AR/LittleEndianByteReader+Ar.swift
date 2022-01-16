//
//  LittleEndianByteReader+Ar.swift
//  SWCompression
//
//  Created by Lessica <82flex@gmail.com> on 2022/1/15.
//  Copyright © 2022 Timofey Solomko. All rights reserved.
//

import BitByteData
import Foundation

extension LittleEndianByteReader {
    
    /**
     Reads a `String` field from AR container. The end of the field is defined by either:
     1. NULL or SPACE character (thus CString in the name of the function).
     2. Reaching specified maximum length.

     Strings are encoded in AR using ASCII encoding. We are treating them as UTF-8 encoded instead since UTF-8 is
     backwards compatible with ASCII.

     We use `String(cString:)` initalizer because AR's NULL-ending ASCII fields are basically CStrings (especially,
     since we are treating them as UTF-8 strings). As a bonus, this initializer is not failable: it replaces unparsable
     as UTF-8 sequences of bytes with UTF-8 Replacement Character, so we don't need to throw any error.
     */
    func arCString(maxLength: Int) -> String {
        var buffer = self.bytes(count: maxLength)
        if let spaceIndex = buffer.firstIndex(of: 0x20) {
            buffer.insert(0, at: spaceIndex)
        } else {
            if buffer.last != 0 {
                buffer.append(0)
            }
        }
        return buffer.withUnsafeBufferPointer { String(cString: $0.baseAddress!) }
    }
    
    /**
     Reads an `Int` field from AR container. The end of the field is defined by either:
     1. NULL or SPACE (in containers created by certain old implementations) character.
     2. Reaching specified maximum length.

     Integers are encoded in AR as ASCII text. We are treating them as UTF-8 encoded strings since UTF-8 is backwards
     compatible with ASCII.
     */
    func arInt(maxLength: Int) -> Int? {
        guard maxLength > 0
        else { return nil }

        var buffer = [UInt8]()
        buffer.reserveCapacity(maxLength)

        // Normal, decimal encoding.
        let startOffset = offset

        for _ in 0..<maxLength {
            let byte = self.byte()
            guard byte != 0 && byte != 0x20
                else { break }
            buffer.append(byte)
        }
        self.offset = startOffset + maxLength
        guard let string = String(bytes: buffer, encoding: .utf8)
            else { return nil }
        
        return Int(string)
    }
    
}
