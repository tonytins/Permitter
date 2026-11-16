// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Permitter",
    products: [
        .executable(name: "permitter", targets: ["Permitter"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/tonytins/GitVersion.git", from: "0.2.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "Permitter",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "GitVersion", package: "GitVersion"),
            ],
            plugins: [
                .plugin(name: "GitVersionPlugin", package: "GitVersion")
            ]
        ),
        .testTarget(
            name: "PermitterTests",
            dependencies: ["Permitter"],
            resources: [.copy("Fixtures")]
        ),
    ],
    swiftLanguageModes: [.v6]
)
