//
//  ArEntry.swift
//  SWCompression
//
//  Created by Lessica <82flex@gmail.com> on 2022/1/15.
//  Copyright © 2022 Timofey Solomko. All rights reserved.
//

import Foundation

/// Represents an entry from the AR container.
public struct ArEntry: ContainerEntry {

    public var info: ArEntryInfo

    /**
     Entry's data (`nil` if entry is a directory or data isn't available).

     - Note: Accessing setter of this property causes `info.size` to be updated as well so it remains equal to
     `data.count`. If `data` is set to be `nil` then `info.size` is set to zero.
     */
    public var data: Data? {
        didSet {
            info.size = data?.count ?? 0
        }
    }

    /**
     Initializes the entry with its info and data. The stored `info.size` will also be updated to be equal to
     `data.count`. If `data` is `nil` then `info.size` will be set to zero.

     - Parameter info: Information about entry.
     - Parameter data: Entry's data; `nil` if entry is a directory or data isn't available.
     */
    public init(info: ArEntryInfo, data: Data?) {
        self.info = info
        self.info.size = data?.count ?? 0
        self.data = data
    }

}
