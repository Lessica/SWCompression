//
//  ArContainer.swift
//  SWCompression
//
//  Created by Lessica <82flex@gmail.com> on 2022/1/15.
//  Copyright © 2022 Timofey Solomko. All rights reserved.
//

import Foundation
import BitByteData

/// Provides functions for work with AR containers.
public class ArContainer: Container {
    
    /**
     Represents the "format" of a AR container: a minimal set of extensions to basic AR format required to
     successfully read a particular container.
     */
    public enum Format {
        /// BSD variant used in Debian packages (.deb)
        case bsd
        /// BSD variant with long filenames (> 16 bytes)
        case bsd4_4
        /// not implemented
        case systemV
    }
    
    /**
     Processes AR container and returns its "format": a minimal set of extensions to basic AR format required to
     successfully read this container.

     - Parameter container: AR container's data.

     - Throws: `ArError`, which may indicate that either container is damaged or it might not be AR container at all.

     - SeeAlso: `ArContainer.Format`
     */
    public static func formatOf(container data: Data) throws -> Format {
        var parser = ArParser(data)
        
        parsingLoop: while true {
            let result = try parser.next()
            switch result {
            case .specialEntry:
                continue parsingLoop
            case .entryInfo(_, let format, _):
                switch format {
                case .systemV:
                    fatalError("Unexpected format of basic header: systemV.")
                case .bsd4_4:
                    fallthrough
                case .bsd:
                    return format
                }
            case .truncated:
                // We don't have an error with a more suitable name.
                throw ArError.tooSmallFileIsPassed
            case .finished:
                break parsingLoop
            }
        }

        // If the container is empty, we assume that it's a common format.
        return .bsd
    }
    
    /**
     Processes AR container and returns an array of `ArEntry` with information and data for all entries.

     - Important: The order of entries is defined by AR container and, particularly, by the creator of a given AR
     container. It is likely that directories will be encountered earlier than files stored in those directories, but no
     particular order is guaranteed.

     - Parameter container: AR container's data.

     - Throws: `ArError`, which may indicate that either container is damaged or it might not be AR container at all.

     - Returns: Array of `ArEntry`.
     */
    public static func open(container data: Data) throws -> [ArEntry] {
        var parser = ArParser(data)
        var entries = [ArEntry]()

        parsingLoop: while true {
            let result = try parser.next()
            switch result {
            case .specialEntry:
                continue parsingLoop
            case .entryInfo(let info, _, let dataRange):
                // Verify that data is not truncated.
                guard dataRange.startIndex > data.startIndex && dataRange.endIndex <= data.endIndex
                    else { throw ArError.tooSmallFileIsPassed }
                let entryData = data.subdata(in: dataRange)
                entries.append(ArEntry(info: info, data: entryData))
            case .truncated:
                // We don't have an error with a more suitable name.
                throw ArError.tooSmallFileIsPassed
            case .finished:
                break parsingLoop
            }
        }

        return entries
    }

    /**
     Processes AR container and returns an array of `ArEntryInfo` with information about entries in this container.

     - Important: The order of entries is defined by AR container and, particularly, by the creator of a given AR
     container. It is likely that directories will be encountered earlier than files stored in those directories, but no
     particular order is guaranteed.

     - Parameter container: AR container's data.

     - Throws: `ArError`, which may indicate that either container is damaged or it might not be AR container at all.

     - Returns: Array of `ArEntryInfo`.
     */
    public static func info(container data: Data) throws -> [ArEntryInfo] {
        var parser = ArParser(data)
        var entries = [ArEntryInfo]()

        parsingLoop: while true {
            let result = try parser.next()
            switch result {
            case .specialEntry:
                continue parsingLoop
            case .entryInfo(let info, _, _):
                entries.append(info)
            case .truncated:
                // We don't have an error with a more suitable name.
                throw ArError.tooSmallFileIsPassed
            case .finished:
                break parsingLoop
            }
        }

        return entries
    }
    
}
