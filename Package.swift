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
        .library(
            name: "BlazeIMA",
            targets: ["BlazeIMA"]),
        .library(
            name: "BlazeGAM",
            targets: ["BlazeGAM"])
    ],
    dependencies: [
        .package(url: "https://github.com/googleads/swift-package-manager-google-interactive-media-ads-ios.git",
                 "3.18.4"..<"4.0.0"), 
        .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git",
                 "10.0.0"..<"12.0.0")
    ],
    targets: [
        .binaryTarget(name: "BlazeSDK",
                      url: "https://github.com/WSCSports/blaze-specs-ios/releases/download/1.3.0/BlazeSDK.zip",
                      checksum: "9fd6b9eba38a9c43590a11538fd590871c1f22e506a72654dcf6bfb34cad9d8a"),
        .target(name: "BlazeIMA",
                dependencies: ["BlazeSDK",
                               .product(name: "GoogleInteractiveMediaAds",
                                        package: "swift-package-manager-google-interactive-media-ads-ios")
                ],
                path: "Sources/BlazeIMA"), 
        .target(name: "BlazeGAM",
                dependencies: ["BlazeSDK",
                               .product(name: "GoogleMobileAds",
                                        package: "swift-package-manager-google-mobile-ads")
                    ],
                path: "Sources/BlazeGAM")
    ]
)
