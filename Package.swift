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
                      url: "https://github.com/WSCSports/blaze-specs-ios/releases/download/1.6.2/BlazeSDK.zip",
                      checksum: "2a651b294dee489725a00ce37ef3547aafbb49e9c28d12b59eb610ba2d28c2bd"),
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
