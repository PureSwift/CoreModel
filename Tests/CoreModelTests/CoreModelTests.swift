//
//  CoreModelTests.swift
//  CoreModelTests
//
//  Created by Alsey Coleman Miller on 11/4/18.
//

import Foundation
import XCTest
import Predicate
@testable import CoreModel

final class CoreModelTests: XCTestCase {
    
    func testEntityName() {
        
        XCTAssertEqual(Person.entityName, "Person")
        XCTAssertEqual(Event.entityName, "Event")
        XCTAssertEqual(Campground.entityName, "Campground")
        XCTAssertEqual(Campground.RentalUnit.entityName, "RentalUnit")
    }
}
