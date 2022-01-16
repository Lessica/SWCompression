//
//  ArContainer.swift
//  SWCompression
//
//  Created by Lessica <82flex@gmail.com> on 2022/1/15.
//  Copyright © 2022 Timofey Solomko. All rights reserved.
//

import BitByteData
import Foundation

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
            case let .entryInfo(_, format, _):
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
     Creates a new AR container with `entries` as its content and generates its `Data`.

     - Parameter entries: AR entries to store in the container.

     - SeeAlso: `ArEntryInfo` properties documenation to see how their values are connected with the specific AR
     format used during container creation.
     */
    public static func create(from entries: [ArEntry]) throws -> Data {
        return try create(from: entries, force: .bsd)
    }

    /**
     Creates a new AR container with `entries` as its content and generates its `Data` using the specified `format`.

     This function forces the usage of the `format`, meaning that certain properties about the `entries` may be missing
     from the resulting container data if the chosen format doesn't support certain features. For example, relatively
     long names (and linknames) will be truncated if the `.bsd` format is specified.

     It is highly recommended to use the `ArContainer.create(from:)` function (or use the `.bsd` format) to ensure the
     best compatible of the `entries` in the output. Other (non-PAX) formats should only be used if you have a
     specific need for them and you understand limitations of those formats.

     - Parameter entries: AR entries to store in the container.
     - Parameter force: For the usage of the specified format.

     - SeeAlso: `ArEntryInfo` properties documenation to see how their values are connected with the specific AR
     format used during container creation.
     */
    public static func create(from entries: [ArEntry], force format: ArContainer.Format) throws -> Data {
        var out = Data()
        try out.append(arString: ArHeader.signature)
        
        for entry in entries {
            let entryOffset = out.count
            let entryName = entry.info.name
            let entryNameLength = entryName.lengthOfBytes(using: .ascii).roundToEven()

            switch format {
            case .bsd:
                guard entryNameLength <= 16 else {
                    throw ArError.tooLongIdentifier
                }
                try out.append(arString: entry.info.name, maxLength: 16)
            case .bsd4_4:
                try out.append(arString: ArHeader.longNameFlag)
                try out.append(arInt: entryNameLength, maxLength: 13)
            case .systemV:
                fatalError("Not implemented")
            }

            let entryModificationTime = entry.info.modificationTime ?? Date()
            let mtime = Int(entryModificationTime.timeIntervalSince1970)
            try out.append(arInt: mtime, maxLength: 12)

            let entryOwnerID = entry.info.ownerID ?? 0
            try out.append(arInt: entryOwnerID, maxLength: 6)

            let entryGroupID = entry.info.groupID ?? 0
            try out.append(arInt: entryGroupID, maxLength: 6)

            let entryPermissions = entry.info.permissions?.rawValue ?? 0o100644
            let entryMode = String(entryPermissions, radix: 8, uppercase: false)
            try out.append(arString: entryMode, maxLength: 8)

            var entrySize = entry.data?.count ?? 0
            switch format {
            case .bsd4_4:
                entrySize += entryNameLength
            default: break
            }
            try out.append(arInt: entrySize, maxLength: 10)

            try out.append(arString: "`\n")
            assert(out.count - entryOffset == 60)

            switch format {
            case .bsd4_4:
                try out.append(arString: entryName, padChar: 0x00, maxLength: entryNameLength)
            default: break
            }
            
            out.appendAsArBlock(entry.data ?? Data())
        }
        
        return out
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
            case let .entryInfo(info, _, dataRange):
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
            case let .entryInfo(info, _, _):
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
