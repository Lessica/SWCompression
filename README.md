# SWCompression

We authorize the original author of this repo to merge the code from here to the upstream repo. 

This repo is waiting for pickup to it's upstream base. 

[![Swift 5.5+](https://img.shields.io/badge/Swift-5.5+-blue.svg)](https://developer.apple.com/swift/)
[![GitHub license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://raw.githubusercontent.com/tsolomko/SWCompression/master/LICENSE)

A framework with (de)compression algorithms and functions for working with various archives and containers.

This is another maintained fork of [tsolomko](https://github.com/tsolomko)'s [SWCompression](https://github.com/tsolomko/SWCompression) with following changes:

- AR support
- Debian Package (.deb) support
- Remove obsolete package managers
- Embedded unit tests

## What is this?

SWCompression is a framework with a collection of functions for:

1. Decompression (and sometimes compression) using different algorithms.
2. Reading (and sometimes writing) archives of different formats.
3. Reading (and sometimes writing) containers such as ZIP, TAR and 7-Zip.

**This fork tested on Apple platforms only.**

All features are listed in the tables below. "TBD" means that feature is planned but not implemented (yet).

|               | Deflate | BZip2 | LZMA/LZMA2 | LZ4 |
| ------------- | ------- | ----- | ---------- | --- | 
| Decompression | ✅      | ✅     | ✅         | ✅  |
| Compression   | ✅      | ✅     | TBD        | ✅  |

|       | Zlib | GZip | XZ  | ZIP | TAR | 7-Zip | AR  |
| ----- | ---- | ---- | --- | --- | --- | ----- | --- |
| Read  | ✅   | ✅    | ✅  | ✅  | ✅   | ✅    | ✅  |
| Write | ✅   | ✅    | TBD | TBD | ✅   | TBD   | ✅ |

Also, SWCompression is _written with Swift only._

## Installation

This fork of [SWCompression](https://github.com/tsolomko/SWCompression) can be integrated into your project using *Swift Package Manager*.

**Obsolete package managers like *Cocoapods* and *Carthage* were removed.**

### Swift Package Manager

To install using SPM, add SWCompression to you package dependencies and specify it as a dependency for your target, e.g.:

```swift
import PackageDescription

let package = Package(
    name: "PackageName",
    dependencies: [
        .package(url: "https://github.com/Lessica/SWCompression.git",
                 from: "4.7.0")
    ],
    targets: [
        .target(
            name: "TargetName",
            dependencies: ["SWCompression"]
        )
    ]
)
```

More details you can find in [Swift Package Manager's Documentation](https://github.com/apple/swift-package-manager/tree/main/Documentation).

## Usage

### Basic Example

For example, if you want to decompress "deflated" data just use:

```swift
// let data = <Your compressed data>
let decompressedData = try? Deflate.decompress(data: data)
```

However, it is unlikely that you will encounter deflated data outside of any archive. So, in the case of GZip archive
you should use:

```swift
let decompressedData = try? GzipArchive.unarchive(archive: data)
```

### Handling Errors

Most SWCompression functions can throw errors and you are responsible for handling them. If you look at the list of
available error types and their cases, you may be frightened by their number. However, most of the cases (such as
`XZError.wrongMagic`) exist for diagnostic purposes.

Thus, you only need to handle the most common type of error for your archive/algorithm. For example:

```swift
do {
    // let data = <Your compressed data>
    let decompressedData = try XZArchive.unarchive(archive: data)
} catch let error as XZError {
    // <handle XZ related error here>
} catch let error {
    // <handle all other errors here>
}
```

## More Info?

See [SWCompression](https://github.com/tsolomko/SWCompression).
