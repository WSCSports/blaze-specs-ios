// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BlazeSDK",
    platforms: [
      .iOS(.v13)
    ],
    products: [
        .library(
          name: "BlazeSDK",
          targets: ["BlazeSDK"]),
    ],
    targets: [
      .binaryTarget(name: "BlazeSDK",
                    url: "https://github.com/WSCSports/blaze-specs-ios/releases/download/0.6.6/BlazeSDK.zip",
                    checksum: "7709d54d755d2a6d5545a3d5e5fb16a296f3b6bca28787c372b9d0f669ca2f2d")
    ]
)
