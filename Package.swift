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
                    url: "https://github.com/WSCSports/blaze-specs-ios/releases/download/0.17.0/BlazeSDK.zip",
                    checksum: "ee1ccdaf04f8f22a94e2aeb1b07c68cf846370a395c6bb17d0e0c625b1f47731")
    ]
)
