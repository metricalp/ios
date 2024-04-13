// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "metricalpios",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "metricalpios",
            targets: ["metricalpios"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "metricalpios"),
        .testTarget(
            name: "metricalpiosTests",
            dependencies: ["metricalpios"]),
    ]
)
