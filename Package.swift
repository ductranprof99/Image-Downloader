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
      exclude: [],
      sources: nil,
      publicHeadersPath: "include",
      cSettings: [
        .headerSearchPath("LibraryPublics"),
        .headerSearchPath("UI+Helper")
      ],
      linkerSettings: [
        .linkedFramework("UIKit", .when(platforms: [.iOS]))
      ]
    ),

    .testTarget(
      name: "ImageDownloaderTests",
      dependencies: ["ImageDownloader"],
      path: "Tests/ImageDownloaderTests"
    )
  ]
)
