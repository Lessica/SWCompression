//
//  ArError.swift
//  SWCompression
//
//  Created by Lessica <82flex@gmail.com> on 2022/1/15.
//  Copyright © 2022 Timofey Solomko. All rights reserved.
//

import Foundation

/**
 Represents an error which happened while processing a AR container.
 It may indicate that either container is damaged or it might not be AR container at all.
 */
public enum ArError: Error {
    /// 'Magic' ASCII string is not `!<arch>\n`
    case wrongMagic
    /// Data is unexpectedly truncated.
    case tooSmallFileIsPassed
    /// File identifier is too long (> 16 bytes).
    case tooLongIdentifier
    /// File identifier contains non-ASCII character(s).
    case invalidIdentifier
    /// Failed to process a *required* AR header's field.
    case wrongField(_ fieldName: String)
    /// A header doesn't end with `` `\n ``.
    case wrongEndChar
}

enum InternalArError: Error {
    case headerNeedsMoreBytes(_ bytesRequired: Int)
}
