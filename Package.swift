// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LiftRelayCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "LiftRelayCore", targets: ["LiftRelayCore"])],
    targets: [
        .target(name: "LiftRelayCore", path: "Sources/LiftRelayCore"),
        .testTarget(name: "LiftRelayCoreTests", dependencies: ["LiftRelayCore"], path: "Tests/LiftRelayCoreTests")
    ]
)
