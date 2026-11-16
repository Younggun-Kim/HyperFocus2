// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        productTypes: [
            "Dependencies": .framework,
        ]
    )
#endif

let package = Package(
    name: "HyperFocus",
    dependencies: [
          .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.0.0")
    ]
)
