//
//  FoundationShims.swift
//  CoreModel
//
//  Re-exports Foundation value types from `FoundationEmbedded`
//  (https://github.com/PureSwift/swift-embedded-foundation) for platforms
//  without Foundation (e.g. Embedded Swift).
//

#if !canImport(FoundationEssentials) && !canImport(Foundation)
import FoundationEmbedded

public typealias Data = FoundationEmbedded.Data
public typealias UUID = FoundationEmbedded.UUID
public typealias Date = FoundationEmbedded.Date
public typealias TimeInterval = FoundationEmbedded.TimeInterval
public typealias Decimal = FoundationEmbedded.Decimal
public typealias URL = FoundationEmbedded.URL
#endif
