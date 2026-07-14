# CoreModel

[![Swift](https://img.shields.io/badge/swift-6.0-orange.svg?style=flat)](https://developer.apple.com/swift/)
[![License MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat)](https://tldrlegal.com/license/mit-license)
[![Release](https://img.shields.io/github/release/pureswift/CoreModel.svg)](https://github.com/PureSwift/CoreModel/releases)

[![SPM compatible](https://img.shields.io/badge/SPM-compatible-4BC51D.svg?style=flat)](https://github.com/apple/swift-package-manager)

Swift Object Graph

## Backends

- CoreData
- [SQLite](https://github.com/PureSwift/CoreModel-SQLite)
- [MongoDB](https://github.com/PureSwift/CoreModel-MongoDB)

## Embedded Swift

The `CoreModel` target compiles under [Embedded Swift](https://docs.swift.org/embedded/documentation/embedded), starting with WebAssembly (`wasm32-unknown-none-wasm` / `wasm32-unknown-wasip1` via the embedded Swift SDK). `CoreDataModel` remains a Foundation/CoreData-only target and is unaffected.

```
SWIFTPM_ENABLE_MACROS=0 swift build --swift-sdk swift-6.3.2-RELEASE_wasm-embedded
```

Macros must be disabled (`SWIFTPM_ENABLE_MACROS=0`) since `swift-syntax` isn't available under Embedded. This means a few things `@Entity` normally generates aren't available and must be written by hand:

- `Entity.entityName`, `attributes`, and `relationships` have no default implementation — implement them explicitly.
- `Entity.init(from:)` / `encode()` have no default Codable-derived implementation — implement them using `ModelData.decode(_:forKey:)` / `.encode(_:forKey:)` (see `Person` in `Tests/CoreModelTests/TestModel.swift` for the pattern).
- `enum CodingKeys: CodingKey { ... }` must declare an explicit `String` raw value — `enum CodingKeys: String, CodingKey { ... }` — since Embedded Swift has no `Codable`/`CodingKey` synthesis; `CoreModel` provides its own `CodingKey` protocol under Embedded that relies on the raw value.
- `Model(entities: any Entity.Type...)` is unavailable (calls a generic initializer through an existential); use `Model(entities: [EntityDescription(entity: Person.self), ...])` with concrete types instead.
- `ModelStorage`'s generic `Entity`-based convenience methods (`fetch<T>`, `insert<T>`, `delete<T>`, `count<T>`) and `ViewContext` are unavailable under Embedded (a compiler limitation in `async` default protocol-extension methods). Call the `ModelStorage` protocol requirements directly with `ModelData`/`ObjectID`.
- `UUID`, `Date`, `Data`, `URL`, and `Decimal` are Foundation-free storage-layer replacements on platforms without Foundation — sufficient for round-tripping through `AttributeValue`, not general-purpose Foundation substitutes.
