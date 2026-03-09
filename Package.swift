// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "JWLibraryRedesign",
    platforms: [.iOS(.v26), .macOS(.v26)],
    targets: [
        .executableTarget(
            name: "JWLibraryRedesign",
            path: "Sources/JWLibraryRedesign"
        )
    ]
)
