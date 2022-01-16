//
//  ArParser.swift
//  SWCompression
//
//  Created by Lessica <82flex@gmail.com> on 2022/1/15.
//  Copyright © 2022 Timofey Solomko. All rights reserved.
//

import BitByteData
import Foundation

struct ArParser {
    
    enum ParsingResult {
        case truncated
        case finished
        case specialEntry(ArHeader.HeaderEntryType)
        case entryInfo(ArEntryInfo, Int, ArContainer.Format)
    }
    
    private let reader: LittleEndianByteReader
    private var signature: String?
    
    init(_ data: Data) {
        self.reader = LittleEndianByteReader(data: data)
    }
    
    mutating func next() throws -> ParsingResult {
        guard !reader.isFinished else {
            return .finished
        }
        
        guard signature != nil else {
            let signatureLength = ArHeader.signature.count
            if reader.bytesLeft < signatureLength {
                return .truncated
            }
            
            let sign = reader.arCString(maxLength: signatureLength)
            assert(reader.offset == signatureLength)
            
            guard sign == ArHeader.signature else {
                throw ArError.wrongMagic
            }
            
            self.signature = sign
            return .specialEntry(.signature)
        }
        
        guard reader.bytesLeft >= ArHeader.length else {
            return .truncated
        }
        
        let header = try ArHeader(reader)
        // For header we read at 60 bytes exactly.
        assert(reader.offset - header.blockStartIndex == ArHeader.length)
        // Check, just in case, since we use blockStartIndex = -1 when creating AR containers.
        assert(header.blockStartIndex >= 0)
        
        let dataStartIndex = header.blockStartIndex + ArHeader.length
        let info = ArEntryInfo(header)
        // Skip file data.
        reader.offset = dataStartIndex + header.size.roundToEven()
        return .entryInfo(info, header.blockStartIndex, header.format)
    }
}
