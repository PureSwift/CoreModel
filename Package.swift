// swift-tools-version:5.7
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
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/PureSwift/Predicate.git",
            branch: "master"
        )
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
        .testTarget(
            name: "CoreModelTests",
            dependencies: [
                "CoreModel"
            ]
        )
    ]
)
