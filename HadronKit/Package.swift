// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HadronKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "HadronKit", targets: ["HadronKit"])
    ],
    targets: [
        .target(
            name: "HadronKit",
            swiftSettings: [
                // The consuming apps are UI-driven and single-actor by design;
                // Swift 5 mode keeps the concurrency checking pragmatic.
                // Migrate to Swift 6 mode together with both apps.
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
