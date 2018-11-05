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
        ),
        .library(
            name: "CoreDataModel",
            targets: [
                "CoreDataModel"
            ]
        ),
        .library(
            name: "SQLiteModel",
            targets: [
                "SQLiteModel"
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
        .target(
            name: "CoreDataModel",
            dependencies: [
                "CoreModel"
            ]
        ),
        .target(
            name: "SQLiteModel",
            dependencies: [
                "CoreModel"
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
