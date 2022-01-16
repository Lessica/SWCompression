//
//  ArEntryInfo.swift
//  SWCompression
//
//  Created by Lessica <82flex@gmail.com> on 2022/1/15.
//  Copyright © 2022 Timofey Solomko. All rights reserved.
//

import Foundation

/// Provides access to information about an entry from the AR container.
public struct ArEntryInfo: ContainerEntryInfo {
    // MARK: ContainerEntryInfo

    /**
     Entry's name.

     - Note: When a new AR container is created, if `name` cannot be encoded with ASCII or its ASCII byte-representation
     is longer than 16 bytes then a `ArError.tooLongIdentifier` error will be thrown.
     - Note: When a new AR container is created, if `name` contains any ASCII space(s) then a `ArError.invalidIdentifier`
     error will be thrown.
     - Note: When creating new AR container, `name` is always encoded with ASCII in the basic Ar header.
     */
    public var name: String

    /**
     Entry's last modification time.

     - Note: Although the common format does not suffer from the
     [year 2038 problem](https://en.wikipedia.org/wiki/Year_2038_problem), many implementations of the ar utility
     do and may need to be modified in the future to handle correctly timestamps in excess of 2147483647.
     */
    public var modificationTime: Date?

    public var permissions: Permissions?

    /**
     Entry's data size.

     - Note: This property cannot be directly modified. Instead it is updated automatically to be equal to its parent's
     `entry.data.count`.
     */
    public internal(set) var size: Int?

    /**
     Only regular files are supported in AR container.
     */
    public internal(set) var type: ContainerEntryType = .regular

    /**
     Not used in AR container.
     */
    public var accessTime: Date?

    /**
     Not used in AR container.
     */
    public var creationTime: Date?

    // MARK: Ar specific

    /// Entry's compression method. Always `.copy` for the entries of AR containers.
    public let compressionMethod = CompressionMethod.copy

    /**
     ID of entry's owner.
     */
    public var ownerID: Int?

    /**
     ID of the group of entry's owner.
     */
    public var groupID: Int?
    
    /**
     Initializes the entry's info with its name and type.

     - Note: Entry's type cannot be modified after initialization.

     - Parameter name: Entry's name.
     - Parameter type: Entry's type.
     */
    public init(name: String) {
        self.name = name
    }
    
    init(_ header: ArHeader) {
        self.name = header.name
        self.modificationTime = header.mtime
        self.permissions = header.permissions
        self.size = header.dataSize
        self.accessTime = nil
        self.creationTime = nil
        self.ownerID = header.uid
        self.groupID = header.gid
    }
}
