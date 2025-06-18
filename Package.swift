// swift-tools-version:6.0
import PackageDescription
import CompilerPluginSupport

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
            url: "https://github.com/apple/swift-syntax.git",
            from: "600.0.1"
        )
    ],
    targets: [
        .target(
            name: "CoreModel",
            dependencies: [
                "CoreModelMacros"
            ]
        ),
        .target(
            name: "CoreDataModel",
            dependencies: [
                "CoreModel"
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .macro(
          name: "CoreModelMacros",
          dependencies: [
              .product(
                  name: "SwiftSyntaxMacros",
                  package: "swift-syntax"
              ),
              .product(
                  name: "SwiftCompilerPlugin",
                  package: "swift-syntax"
              )
          ]
        ),
        .testTarget(
            name: "CoreModelTests",
            dependencies: [
                "CoreModel",
                "CoreModelMacros",
                .byName(
                    name: "CoreDataModel",
                    condition: .when(platforms: [.macOS, .iOS, .macCatalyst, .watchOS, .tvOS, .visionOS])
                )
            ]
        )
    ]
)
