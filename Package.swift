// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "CheckoutFlow",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "CheckoutFlow",
            targets: ["CheckoutFlow"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/alegelos/iOSCleanNetwork", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "CheckoutFlow",
            dependencies: [
                .product(name: "iOSCleanNetwork", package: "iOSCleanNetwork")
            ]
        ),
        .testTarget(
            name: "CheckoutFlowTests",
            dependencies: [
                "CheckoutFlow",
                .product(name: "iOSCleanNetworkTesting", package: "iOSCleanNetwork")
            ],
            resources: [
                .process("Data/Providers/CheckoutAPI/Jsons")
            ]
        ),
    ]
)
