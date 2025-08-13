// swift-tools-version:6.0
import PackageDescription
import CompilerPluginSupport
import class Foundation.ProcessInfo

// get environment variables
let environment = ProcessInfo.processInfo.environment
let dynamicLibrary = environment["SWIFT_BUILD_DYNAMIC_LIBRARY"] == "1"
let enableMacros = environment["SWIFTPM_ENABLE_MACROS"] != "0"
let buildDocs = environment["BUILDING_FOR_DOCUMENTATION_GENERATION"] == "1"

// force building as dynamic library
let libraryType: PackageDescription.Product.Library.LibraryType? = dynamicLibrary ? .dynamic : nil

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
            type: libraryType,
            targets: [
                "CoreModel"
            ]
        )
    ],
    targets: [
        .target(
            name: "CoreModel"
        ),
        .testTarget(
            name: "CoreModelTests",
            dependencies: [
                "CoreModel"
            ]
        )
    ]
)

package.products.append(
    .library(
        name: "CoreDataModel",
        type: libraryType,
        targets: [
            "CoreDataModel"
        ]
    )
)
package.targets.insert(
    .target(
        name: "CoreDataModel",
        dependencies: [
            "CoreModel"
        ],
        swiftSettings: [
            .swiftLanguageMode(.v5)
        ]
    ),
    at: 1
)
package.targets[package.targets.count - 1] = .testTarget(
    name: "CoreModelTests",
    dependencies: [
        "CoreModel",
        .byName(
            name: "CoreDataModel",
            condition: .when(platforms: [
                .macOS,
                .iOS,
                .macCatalyst,
                .watchOS,
                .tvOS,
                .visionOS
            ])
        )
    ]
)

// SwiftPM plugins
if buildDocs {
    package.dependencies += [
        .package(
            url: "https://github.com/swiftlang/swift-docc-plugin.git",
            from: "1.4.5"
        )
    ]
}

if enableMacros {
    let version: Version
    #if swift(>=6.1)
    version = "601.0.1"
    #else
    version = "600.0.1"
    #endif
    package.targets[0].swiftSettings = [
        .define("SWIFTPM_ENABLE_MACROS")
    ]
    package.dependencies += [
        .package(
            url: "https://github.com/swiftlang/swift-syntax.git",
            from: version
        )
    ]
    package.targets += [
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
        )
    ]
    package.targets[0].dependencies += [
        "CoreModelMacros"
    ]
}
