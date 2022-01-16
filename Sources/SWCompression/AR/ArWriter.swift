//
//  ArWriter.swift
//  SWCompression
//
//  Created by Lessica <82flex@gmail.com> on 2022/1/16.
//  Copyright © 2022 Timofey Solomko. All rights reserved.
//

import Foundation

public struct ArWriter {

    private let format: ArContainer.Format
    private let handle: FileHandle

    public init(fileHandle: FileHandle, force format: ArContainer.Format = .bsd) throws {
        self.handle = fileHandle
        self.format = format
        
        // Write signature immediately
        guard let signatureData = ArHeader.signature.data(using: .ascii) else {
            throw ArError.asciiNonEncodable
        }
        try write(signatureData)
    }

    public mutating func append(_ entry: ArEntry) throws {
        let entryData = try ArContainer.data(for: entry, force: format)
        assert(entryData.count % 2 == 0)
        try write(entryData)
    }

    public func finalize() throws {
        // No EOF marker needed
        #if compiler(<5.2)
            handle.synchronizeFile()
        #else
            if #available(macOS 10.15.4, iOS 13.4, watchOS 6.2, tvOS 13.4, *) {
                try handle.synchronize()
            } else {
                handle.synchronizeFile()
            }
        #endif
    }

    private func write(_ data: Data) throws {
        #if compiler(<5.2)
            handle.write(data)
        #else
            if #available(macOS 10.15.4, iOS 13.4, watchOS 6.2, tvOS 13.4, *) {
                try handle.write(contentsOf: data)
                try handle.synchronize()
            } else {
                handle.write(data)
                handle.synchronizeFile()
            }
        #endif
    }

}
