// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "imagetron",
  platforms: [
    .macOS(.v13)
  ],
  products: [
    .executable(name: "imagetron", targets: ["imagetron"])
  ],
  targets: [
    // Library with reusable functions
    .target(
      name: "PhotoPasteboardLib",
      path: "Sources/PhotoPasteboardLib"
    ),
    // Main application
    .executableTarget(
      name: "imagetron",
      dependencies: ["PhotoPasteboardLib"],
      path: "Sources/imagetron"
    ),
  ]
)
