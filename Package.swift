// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Scroll",
    platforms: [.iOS(.v26), .macOS(.v26)],
    targets: [
        .executableTarget(
            name: "Scroll",
            path: "Sources/Scroll"
        )
    ]
)
