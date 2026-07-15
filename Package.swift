// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "RaytoneCodex",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "RaytoneX", targets: ["RaytoneX"]),
        .executable(name: "RaytoneCodexCoreChecks", targets: ["RaytoneCodexCoreChecks"]),
        .library(name: "RaytoneCodexCore", targets: ["RaytoneCodexCore"])
    ],
    targets: [
        .target(name: "RaytoneCodexCore"),
        .executableTarget(
            name: "RaytoneX",
            dependencies: ["RaytoneCodexCore"],
            path: "Sources/RaytoneCodex"
        ),
        .executableTarget(
            name: "RaytoneCodexCoreChecks",
            dependencies: ["RaytoneCodexCore"]
        )
    ]
)
