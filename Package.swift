// swift-tools-version:4.1
import PackageDescription

let package = Package(
    name: "CoreModel",
    products: [
        .library(
            name: "CoreModel",
            targets: [
                "CoreModel"
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/PureSwift/Predicate.git", .branch("master"))
    ],
    targets: [
        .target(
            name: "CoreModel",
            dependencies: [
                "Predicate"
            ]
        ),
        .testTarget(
            name: "CoreModelTests",
            dependencies: [
                "CoreModel"
            ]
        )
    ],
    swiftLanguageVersions: [4]
)
