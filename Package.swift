// swift-tools-version:5.9
import PackageDescription

let package = Package(
  name: "CNI",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15)
  ],
  products: [
    .library(
      name: "CNI",
      targets: ["CNI"]
    ),
    .library(
      name: "CNIUIKit",
      targets: ["CNIUIKit"]
    ),
    .library(
      name: "CNIComponentKit",
      targets: ["CNIComponentKit"]
    )
  ],
  dependencies: [],
  targets: [
    .target(
      name: "CNI",
      dependencies: [],
      path: "Sources/CNI",
      exclude: ["include"],
      publicHeadersPath: "include",
      cSettings: [
        .headerSearchPath("Manager"),
        .headerSearchPath("CacheAgent"),
        .headerSearchPath("NetworkAgent"),
        .headerSearchPath("StorageAgent"),
        .headerSearchPath("Observer"),
        .headerSearchPath("Model"),
      ]
    ),

    .target(
      name: "CNIUIKit",
      dependencies: ["CNI"],
      path: "Sources/CNIUIKit"
    ),

    .target(
      name: "CNIComponentKit",
      dependencies: ["CNI"],
      path: "Sources/CNIComponentKit",
      cxxSettings: [
        .headerSearchPath("."),
      ]
    ),

    .testTarget(
      name: "CNITests",
      dependencies: ["CNI"],
      path: "Tests/CNITests"
    )
  ],
  cLanguageStandard: .c11,
  cxxLanguageStandard: .cxx17
)
