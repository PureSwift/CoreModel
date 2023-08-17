// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "CoreModel",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
    ],
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
                "CoreModel",
                .byName(
                    name: "CoreDataModel",
                    condition: .when(platforms: [.macOS, .iOS, .macCatalyst, .watchOS, .tvOS])
                )
            ]
        )
    ]
)
