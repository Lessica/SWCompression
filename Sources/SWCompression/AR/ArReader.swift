//
//  ArReader.swift
//  SWCompression
//
//  Created by Lessica <82flex@gmail.com> on 2022/1/15.
//  Copyright © 2022 Timofey Solomko. All rights reserved.
//

import BitByteData
import Foundation

public struct ArReader {
    private let handle: FileHandle

    public init(fileHandle: FileHandle) throws {
        handle = fileHandle

        guard try getData(size: ArHeader.signature.count) == ArHeader.signature.data(using: .ascii) else {
            throw ArError.wrongMagic
        }
    }

    public mutating func process<T>(_ transform: (ArEntry?) throws -> T) throws -> T {
        return try autoreleasepool {
            let entry = try read()
            return try transform(entry)
        }
    }
    
    @discardableResult
    public mutating func read() throws -> ArEntry? {
        guard let header = try nextHeader() else {
            return nil
        }
        
        let currentOffset = try Int(getOffset())
        let entryData = try getData(size: header.dataSize)
        guard entryData.count == header.dataSize
        else { throw DataError.truncated }
        
        let nextOffset = UInt64(truncatingIfNeeded: (currentOffset + header.dataSize).roundToEven())

        let info = ArEntryInfo(header)
        try set(offset: nextOffset)
        return ArEntry(info: info, data: entryData)
    }
    
    @discardableResult
    public mutating func next() throws -> ArEntryInfo? {
        guard let header = try nextHeader() else {
            return nil
        }

        let currentOffset = try Int(getOffset())
        
        // Will not copy actual data in this context
        let nextOffset = UInt64(truncatingIfNeeded: (currentOffset + header.dataSize).roundToEven())
        
        let info = ArEntryInfo(header)
        try set(offset: nextOffset)
        return info
    }
    
    private func nextHeader() throws -> ArHeader? {
        let beginOffset = try getOffset()
        let headerData = try getData(size: ArHeader.commonLength)
        if headerData.count == 0 {
            return nil
        } else if headerData.count < ArHeader.commonLength {
            throw DataError.truncated
        }
        assert(headerData.count == ArHeader.commonLength)
        
        var headerReader: LittleEndianByteReader
        var header: ArHeader
        do {
            headerReader = LittleEndianByteReader(data: headerData)
            header = try ArHeader(headerReader)
        } catch InternalArError.headerNeedsMoreBytes(let bytesRequired) {
            
            // Rollback to original offset
            try set(offset: beginOffset)
            
            let headerLength = ArHeader.commonLength + bytesRequired
            let headerData = try getData(size: headerLength)
            if headerData.count == 0 {
                return nil
            } else if headerData.count < headerLength {
                throw DataError.truncated
            }
            assert(headerData.count == headerLength)
            
            headerReader = LittleEndianByteReader(data: headerData)
            header = try ArHeader(headerReader)
        }

        // Differ from `TarReader`, we must proceed all 60 bytes initialized for the header.
        assert(headerReader.isFinished)

        // Check, just in case, since we use blockStartIndex = -1 when creating AR containers.
        assert(header.blockStartIndex >= 0)
        
        return header
    }

    private func getOffset() throws -> UInt64 {
        #if compiler(<5.2)
            return handle.offsetInFile
        #else
            if #available(macOS 10.15.4, iOS 13.4, watchOS 6.2, tvOS 13.4, *) {
                return try handle.offset()
            } else {
                return handle.offsetInFile
            }
        #endif
    }

    private func set(offset: UInt64) throws {
        #if compiler(<5.2)
            handle.seek(toFileOffset: offset)
        #else
            if #available(macOS 10.15.4, iOS 13.4, watchOS 6.2, tvOS 13.4, *) {
                try handle.seek(toOffset: offset)
            } else {
                handle.seek(toFileOffset: offset)
            }
        #endif
    }

    private func getData(size: Int) throws -> Data {
        assert(size >= 0, "ArReader.getData(size:): negative size.")
        guard size > 0 else { return Data() }
        #if compiler(<5.2)
            return handle.readData(ofLength: size)
        #else
            if #available(macOS 10.15.4, iOS 13.4, watchOS 6.2, tvOS 13.4, *) {
                guard let chunkData = try handle.read(upToCount: size) else {
                    /**
                     The documentation said it will return an empty NSData object if the handle is at the file’s end
                     or if the communications channel returns an end-of-file indicator.
                    */
                    let readOffset = try handle.offset()
                    let endOffset = try handle.seekToEnd()
                    if readOffset == endOffset {
                        return Data()
                    }
                    try handle.seek(toOffset: readOffset)
                    throw DataError.truncated
                }
                return chunkData
            } else {
                // Technically, this can throw NSException, but since it is ObjC exception we cannot handle it in Swift.
                return handle.readData(ofLength: size)
            }
        #endif
    }
}

#if os(Linux) || os(Windows)
    @discardableResult
    fileprivate func autoreleasepool<T>(_ block: () throws -> T) rethrows -> T {
        return try block()
    }
#endif
