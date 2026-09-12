// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CrocoCross",
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [.library(name: "CrocoCrossCore", targets: ["CrocoCrossCore"])],
    targets: [
        .target(name: "CrocoCrossCore"),
        .testTarget(name: "CrocoCrossCoreTests", dependencies: ["CrocoCrossCore"])
    ]
)
