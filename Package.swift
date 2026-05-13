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
        .package(url: "https://github.com/stefanprojchev/ForgeCore.git", from: "1.0.0"),
        .package(url: "https://github.com/stefanprojchev/ForgeObservers.git", from: "1.0.0"),
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
