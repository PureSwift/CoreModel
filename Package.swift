import PackageDescription

let package = Package(
    name: "CoreModel",
    dependencies: [
        .Package(url: "https://github.com/PureSwift/SwiftFoundation.git", majorVersion: 1),
    ]
)