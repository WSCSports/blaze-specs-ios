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
                    url: "https://github.com/WSCSports/blaze-specs-ios/releases/download/0.3.2/BlazeSDK.zip",
                    checksum: "cdb7b37e15b16d01bf9579bcc3e8e1b7418eb4a23c8aaeaccb9f8c89a187705c")
    ]
)