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
                    url: "https://blazeprodeus2.blob.core.windows.net/ios-sdk/0.0.65/BlazeSDK.zip",
                    checksum: "97b63a4676cb41c0f0925638b65d6f2d8d30bd279b95d5fb52254251cfbfed75")
    ]
)
