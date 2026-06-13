// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DayLog",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "DayLogCore", targets: ["DayLogCore"]),
        .executable(name: "DayLog", targets: ["DayLogApp"]),
        .executable(name: "DayLogCoreCheck", targets: ["DayLogCoreCheck"])
    ],
    targets: [
        .target(name: "DayLogCore"),
        .executableTarget(
            name: "DayLogApp",
            dependencies: ["DayLogCore"]
        ),
        .executableTarget(
            name: "DayLogCoreCheck",
            dependencies: ["DayLogCore"]
        )
    ]
)
