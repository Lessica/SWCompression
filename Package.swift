// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "SWCompression",
    products: [
        .library(
            name: "SWCompression",
            targets: ["SWCompression"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/jakeheis/SwiftCLI",
                 from: "6.0.0"),
        .package(url: "https://github.com/tsolomko/BitByteData",
                 from: "2.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "swcomp",
            dependencies: ["SWCompression", "SwiftCLI"]
        ),
        .target(
            name: "SWCompression",
            dependencies: ["BitByteData"]
        ),
        .testTarget(
            name: "SWCompressionTests",
            dependencies: ["SWCompression"],
            exclude: [
                "Test Files/Results.md",
            ],
            resources: [
                .process("Test Files"),
            ]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
