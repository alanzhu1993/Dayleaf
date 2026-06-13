// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Dayleaf",
    platforms: [
        .macOS("26.0")
    ],
    products: [
        .library(name: "DayleafCore", targets: ["DayleafCore"]),
        .executable(name: "Dayleaf", targets: ["DayleafApp"]),
        .executable(name: "DayleafCoreCheck", targets: ["DayleafCoreCheck"])
    ],
    targets: [
        .target(name: "DayleafCore"),
        .executableTarget(
            name: "DayleafApp",
            dependencies: ["DayleafCore"]
        ),
        .executableTarget(
            name: "DayleafCoreCheck",
            dependencies: ["DayleafCore"]
        )
    ]
)
