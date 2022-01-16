//
//  Data+Ar.swift
//  SWCompression
//
//  Created by Lessica <82flex@gmail.com> on 2022/1/16.
//  Copyright © 2022 Timofey Solomko. All rights reserved.
//

import Foundation

extension Data {

    @inline(__always)
    mutating func appendAsArBlock(_ data: Data) {
        self.append(data)
        if count % 2 != 0 {
            self.append(Data([0x0a]))
        }
    }

    mutating func append(arInt value: Int, maxLength: Int) throws {
        let valueString = String(value)
        if valueString.lengthOfBytes(using: .ascii) > maxLength {
            throw ArError.overflow
        }
        guard let valueData = valueString.data(using: .ascii) else {
            throw ArError.asciiNonEncodable
        }
        self.append(valueData.rightPad(maxLength, padChar: 0x20))
    }

    mutating func append(arString string: String, padChar: UInt8 = 0x20, maxLength: Int? = nil) throws {
        guard let valueData = string.data(using: .ascii) else {
            throw ArError.asciiNonEncodable
        }
        if let maxLength = maxLength {
            if valueData.count > maxLength {
                throw ArError.overflow
            }
            self.append(valueData.rightPad(maxLength, padChar: padChar))
        } else {
            self.append(valueData)
        }
    }

    /// This should work in the same way as `String.padding(toLength: length, withPad: " ", startingAt: 0)`.
    @inline(__always)
    private func rightPad(_ length: Int, padChar: UInt8) -> Data {
        var out = length < self.count ? self.prefix(upTo: length) : self
        out.append(Data([UInt8](repeating: padChar, count: length - out.count)))
        return out
    }

}
