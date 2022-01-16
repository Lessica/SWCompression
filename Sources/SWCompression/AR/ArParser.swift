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
        case entryInfo(
            _ info: ArEntryInfo,
            _ format: ArContainer.Format,
            _ dataRange: Range<Int>
        )
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
        
        guard reader.bytesLeft >= ArHeader.commonLength else {
            return .truncated
        }
        
        let header = try ArHeader(reader)
        
        // Check, just in case, since we use blockStartIndex = -1 when creating AR containers.
        assert(header.blockStartIndex >= 0)
        
        // For header we read at least 60 bytes.
        assert(reader.offset - header.blockStartIndex >= ArHeader.commonLength)
        
        // Skip file data.
        let info = ArEntryInfo(header)
        let startIndex = header.blockStartIndex + ArHeader.commonLength
        let dataStartIndex = startIndex + header.extraNameSize
        let dataEndIndex = startIndex + header.size
        reader.offset = dataEndIndex.roundToEven()
        
        return .entryInfo(info, header.format, dataStartIndex..<dataEndIndex)
    }
}
