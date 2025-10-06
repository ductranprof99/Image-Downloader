// swift-tools-version:5.9
import PackageDescription

let package = Package(
  name: "ImageDownloader",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15)
  ],
  products: [
    .library(
      name: "ImageDownloader",
      targets: ["ImageDownloader"]
    ),
    .library(
      name: "ImageDownloaderUI",
      targets: ["ImageDownloaderUI"]
    ),
    .library(
      name: "ImageDownloaderComponentKit",
      targets: ["ImageDownloaderComponentKit", "ImageDownloaderComponentKitBridge"]
    )
  ],
  dependencies: [],
  targets: [
    .target(
      name: "ImageDownloader",
      dependencies: [],
      path: "Sources/ImageDownloader",
      linkerSettings: [
        .linkedFramework("UIKit", .when(platforms: [.iOS])),
        .linkedFramework("AppKit", .when(platforms: [.macOS]))
      ]
    ),

    .target(
      name: "ImageDownloaderUI",
      dependencies: ["ImageDownloader"],
      path: "Sources/ImageDownloaderUI"
    ),

    // Objective-C++ bridge for ComponentKit C++ interop
    .target(
      name: "ImageDownloaderComponentKitBridge",
      dependencies: ["ImageDownloader"],
      path: "Sources/ImageDownloaderComponentKit",
      exclude: [
        "ComponentImageDownloader.swift",
        "NetworkImageView.swift"
      ],
      publicHeadersPath: "include",
      cxxSettings: [
        .headerSearchPath(".")
      ]
    ),

    // Swift layer for ComponentKit
    .target(
      name: "ImageDownloaderComponentKit",
      dependencies: [
        "ImageDownloader",
        "ImageDownloaderComponentKitBridge"
      ],
      path: "Sources/ImageDownloaderComponentKit",
      exclude: [
        "NetworkImageViewBridge.h",
        "NetworkImageViewBridge.mm",
        "include"
      ]
    ),

    .testTarget(
      name: "ImageDownloaderTests",
      dependencies: ["ImageDownloader"],
      path: "Tests/ImageDownloaderTests"
    )
  ]
)
