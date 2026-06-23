// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "gita",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .target(
            name: "gita",
            path: "gita"
        ),
        .testTarget(
            name: "gitaTests",
            dependencies: ["gita"],
            path: "gitaTests"
        )
    ]
)
