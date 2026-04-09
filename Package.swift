// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "ForgeBackgroundTasks",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(name: "ForgeBackgroundTasks", targets: ["ForgeBackgroundTasks"]),
    ],
    dependencies: [
        .package(path: "../ForgeCore"),
        .package(path: "../ForgeObservers"),
    ],
    targets: [
        .target(
            name: "ForgeBackgroundTasks",
            dependencies: [
                .product(name: "ForgeCore", package: "ForgeCore"),
                .product(name: "ForgeObservers", package: "ForgeObservers"),
            ]
        ),
        .testTarget(
            name: "ForgeBackgroundTasksTests",
            dependencies: ["ForgeBackgroundTasks"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
