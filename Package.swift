// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Securitator",
    products: [
        .executable(name: "securitator", targets: ["Securitator"]),
        .library(name: "SecuritatorKit", targets: ["SecuritatorKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.4.0"),
        .package(url: "https://github.com/JohnSundell/Files", from: "4.0.0"),
        .package(url: "https://github.com/JohnSundell/ShellOut.git", from: "2.0.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "4.0.5"),
        .package(url: "https://github.com/onevcat/Rainbow", .upToNextMajor(from: "4.0.0"))
    ],
    targets: [
        .target(
            name: "Securitator",
            dependencies: [
                "SecuritatorKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Files", package: "Files"),
                .product(name: "Rainbow", package: "Rainbow")
            ],
            path: "Sources/Securitator"
        ),
        .target(
            name: "SecuritatorKit",
            dependencies: [
                .product(name: "Files", package: "Files"),
                .product(name: "ShellOut", package: "ShellOut"),
                .product(name: "Yams", package: "Yams"),
                .product(name: "Rainbow", package: "Rainbow")
            ],
            path: "Sources/SecuritatorKit"
        ),
        .testTarget(
            name: "SecuritatorTests",
            dependencies: ["Securitator"]),
    ]
)
