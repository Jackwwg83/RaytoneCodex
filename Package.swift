// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "RaytoneCodex",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "RaytoneCodex", targets: ["RaytoneCodex"]),
        .executable(name: "RaytoneCodexCoreChecks", targets: ["RaytoneCodexCoreChecks"]),
        .library(name: "RaytoneCodexCore", targets: ["RaytoneCodexCore"])
    ],
    targets: [
        .target(name: "RaytoneCodexCore"),
        .executableTarget(
            name: "RaytoneCodex",
            dependencies: ["RaytoneCodexCore"]
        ),
        .executableTarget(
            name: "RaytoneCodexCoreChecks",
            dependencies: ["RaytoneCodexCore"]
        )
    ]
)
