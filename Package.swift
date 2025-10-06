// swift-tools-version:5.9
import PackageDescription

let package = Package(
  name: "ImageDownloader",
  platforms: [
    .iOS(.v13)
  ],
  products: [
    .library(
      name: "ImageDownloader",
      targets: ["ImageDownloader"]
    ),
    .library(
      name: "ImageDownloaderUI",
      targets: ["ImageDownloaderUI"]
    )
  ],
  dependencies: [
    // Dev plugin to enable `swift package generate-documentation`
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.4.3")
  ],
  targets: [
    .target(
      name: "ImageDownloader",
      dependencies: [],
      path: "Sources/ImageDownloader",
      linkerSettings: [
        .linkedFramework("UIKit", .when(platforms: [.iOS]))
      ]
    ),

    .target(
      name: "ImageDownloaderUI",
      dependencies: ["ImageDownloader"],
      path: "Sources/ImageDownloaderUI"
    ),


    .testTarget(
      name: "ImageDownloaderTests",
      dependencies: ["ImageDownloader"],
      path: "Tests/ImageDownloaderTests"
    )
  ]
)
