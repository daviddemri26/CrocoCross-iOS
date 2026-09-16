// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CrocoCross",
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [.library(name: "CrocoCrossCore", targets: ["CrocoCrossCore"])],
    targets: [
        .target(name: "CBox2D", path: "ThirdParty/Box2D", exclude: ["LICENSE", "PROVENANCE.md"],
                sources: ["src"], publicHeadersPath: "include",
                cSettings: [.headerSearchPath("src"), .unsafeFlags(["-ffp-contract=off"])]),
        .target(name: "CrocoCrossCore", dependencies: ["CBox2D"]),
        .testTarget(name: "CrocoCrossCoreTests", dependencies: ["CrocoCrossCore"])
    ],
    cLanguageStandard: .c17
)
