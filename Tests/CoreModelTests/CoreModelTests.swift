//
//  CoreModelTests.swift
//  CoreModelTests
//
//  Created by Alsey Coleman Miller on 11/4/18.
//

import Foundation
import Testing
@testable import CoreModel

@Suite struct CoreModelTests {
    
    @Test func entityName() {
        
        #expect(Person.entityName == "Person")
        #expect(Event.entityName == "Event")
        #expect(Campground.entityName == "Campground")
        #expect(Campground.RentalUnit.entityName == "RentalUnit")
    }
}
