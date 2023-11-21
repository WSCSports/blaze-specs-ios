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
                    url: "https://github.com/WSCSports/blaze-specs-ios/releases/download/0.3.7/BlazeSDK.zip",
                    checksum: "5750691541f103f02ec6ceaff151668ed3101a3fc6cbd95cda4f15f0b0d61f40")
    ]
)