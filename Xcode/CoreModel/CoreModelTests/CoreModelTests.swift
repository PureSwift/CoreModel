//
//  CoreModelTests.swift
//  CoreModelTests
//
//  Created by Alsey Coleman Miller on 6/24/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

import XCTest
import CoreModel
import CoreData
import SwiftFoundation

class CoreModelTests: XCTestCase {
    static var managedObjectModel: NSManagedObjectModel!
    static var managedObjectContext: NSManagedObjectContext!
    static var temporaryFolder: NSURL!
    
    static var store: StoreType!
    static var model: Model!
    
    static let testEntityName = "TestEntity"
    static let testIdentifiers = ["red", "green", "blue", "purple", "grey"]
    
    var resourceRed: Resource!
    var resourceBlue: Resource!
    var entity: Entity!
    
    override class func setUp() {
        super.setUp()
        
        let bundle = NSBundle(forClass: self)
        guard let modelURL = bundle.URLForResource("CoreDataModel", withExtension: "momd"),
            mom = NSManagedObjectModel(contentsOfURL: modelURL) else {
                return
        }
        
        managedObjectModel = mom
        
        let man = NSFileManager.defaultManager()
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        
        do {
            temporaryFolder = try man.URLForDirectory(.ItemReplacementDirectory, inDomain: .UserDomainMask, appropriateForURL: bundle.resourceURL, create: true)
            try persistentStoreCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: temporaryFolder.URLByAppendingPathComponent("CoreDataModelTest.store"), options: nil)
        } catch {
            fatalError("Couldn't create a temporary folder or a persistent store")
        }
        
        managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        
        guard let m = CoreModelTests.managedObjectModel.toModel(),
            let st = CoreDataStore(model: m, managedObjectContext: CoreModelTests.managedObjectContext) else {
                XCTFail("Expected to be able to convert the NSManagedObjectModel to a CoreModel.Model and to build a CoreDataStore")
                return
        }
        
        model = m
        store = st
        
        // Test data
        
        let colours = [NSColor.redColor(), NSColor.greenColor(), NSColor.blueColor(), NSColor.purpleColor(), NSColor.grayColor()]
        
        let zipt = zip(testIdentifiers, colours)
        
        var integer = 47
        var yn = false
        
        zipt.forEach { key, colour in
            let nte = Resource(testEntityName, key)
            let vals: ValuesObject = [
                "myInteger": .Attribute(.Number(.Integer(integer))),
                "myBool": .Attribute(.Number(.Boolean(yn))),
                "myColour": .Attribute(.Transformable(colour))
            ]
            
            do {
                try store.create(nte, initialValues: vals)
            } catch {
                XCTFail("Unable to create test entity \(key) with values \(vals)")
            }
            
            integer += 1
            yn = !yn
        }
        
        InstantiatorRegistry.register(typeName: "NSColor", instantiator: NSColor.fromData)
    }
    
    override class func tearDown() {
        guard let psc = managedObjectContext.persistentStoreCoordinator else {
            fatalError("No persistent store coordinator")
        }
        
        let man = NSFileManager.defaultManager()
        
        do {
            try psc.persistentStores.forEach { store in
                try psc.removePersistentStore(store)
            }
            
            try man.removeItemAtURL(temporaryFolder)
        } catch {
            fatalError("Failed to cleanup the persistent store and temporary folder \(temporaryFolder): \(error)")
        }
     
        super.tearDown()
    }
    
    override func setUp() {
        super.setUp()
        
        guard let firstID = CoreModelTests.testIdentifiers.first else {
            XCTFail("testIdentifiers should not have been empty")
            return
        }
        
        entity = CoreModelTests.model[CoreModelTests.testEntityName]
        
        var fetcher = FetchRequest(entityName: CoreModelTests.testEntityName)
        let comparison = ComparisonPredicate(propertyName: "id", value: .Attribute(.String(firstID)))
        fetcher.predicate = Predicate.Comparison(comparison)
        
        let bluePredicate = ComparisonPredicate(propertyName: "id", value: .Attribute(.String("blue")))
        
        do {
            let results = try CoreModelTests.store.fetch(fetcher)
            
            resourceRed = results.first
            
            fetcher.predicate = Predicate.Comparison(bluePredicate)
            
            let moreResults = try CoreModelTests.store.fetch(fetcher)
            
            resourceBlue = moreResults.first
            
        } catch {
            XCTFail("Error when fetching resources: \(error)")
        }
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testToJSON() {
        XCTAssertNotNil(resourceBlue)
        
        var values: ValuesObject? = nil
        
        do {
            values = try CoreModelTests.store.values(resourceBlue)
        } catch {
            XCTFail("Failed to retrieve the values for resource \(resourceBlue) with error: \(error)")
            return
        }
        
        guard let unwrappedValues = values else {
            XCTFail("No values retrieved for resource \(resourceBlue)")
            return
        }
        
        let json = JSON.Value.Object(JSON.fromValues(unwrappedValues))

        let jsonString: String!
        
        do {
            jsonString = try json.toString()
        } catch {
            XCTFail("Couldn't print \(json) because of error: \(error)")
            return
        }
        
        let expectedJSON = "{\"myBool\":false,\"myColour\":\"NSColor&IzAwMDBmZg==\",\"myInteger\":49}"
        
        XCTAssertEqual(jsonString, expectedJSON, "JSON output should have been \(expectedJSON); got \(jsonString)")
    }
    
    func testFromJSON() {
        let jsonValuesString = "{\"myBool\":true,\"myColour\":\"NSColor&I0ZGMDAwMA==\",\"myInteger\":26}"
        
        var values: ValuesObject!
        
        do {
            let json = try JSON.Value(string: jsonValuesString)
            
            if let jobj = json.objectValue {
                values = entity.convert(jobj)
            
                XCTAssertNotNil(values, "This JSON values string parsed as empty, yet didn't throw an error: \(jsonValuesString)")
            }
        } catch {
            XCTFail("Failed to parse JSON string: \"\(jsonValuesString)\"; Error: \(error)")
        }
        
        do {
            try CoreModelTests.store.edit(resourceRed, changes: values)
        } catch {
            XCTFail("Failed to edit \(resourceRed) with changes: \(values). Error: \(error)")
        }
        
        do {
            let changedValues = try CoreModelTests.store.values(resourceRed)
            
            if let v = values {
               
                for (attrName, _) in entity.attributes {
                    
                    guard let vattr = v[attrName],
                        let chattr = changedValues[attrName] else {
                            continue
                    }
                    
                    XCTAssert(vattr == chattr, "Parsed \(attrName) doesn't match stored version: \(vattr) vs. \(chattr)")
                }
            }
        } catch {
            XCTFail("Couldn't retrieve values")
        }
    }
    
    func testModelConversion() {
        guard let _ = CoreModelTests.managedObjectModel.toModel() else {
            XCTFail("Expected to be able to convert the NSManagedObjectModel to a CoreModel.Model")
            return
        }
        
        XCTAssert(true, "Successfully converted the NSManagedObjectModel to a CoreModel.Model")
    }
    
    func testStoreConversion() {
        guard let model = CoreModelTests.managedObjectModel.toModel(),
            let _ = CoreDataStore(model: model, managedObjectContext: CoreModelTests.managedObjectContext) else {
            XCTFail("Expected to be able to convert the NSManagedObjectModel to a CoreModel.Model and to build a CoreDataStore")
            return
        }
        
        XCTAssert(true, "Built a CoreDataStore")
    }
    

    func testValidInsertAndCheck() {
        guard let _ = CoreModelTests.model[CoreModelTests.testEntityName] else {
            XCTFail("Unable to find an entity named \(CoreModelTests.testEntityName) in the model \(CoreModelTests.model)")
            return
        }
        
        let identifier = "88"
        
        let newTestEntity = Resource(CoreModelTests.testEntityName, identifier)
        let valuesObject: ValuesObject = [
            "myInteger": .Attribute(.Number(.Integer(Int(arc4random())))),
            "myBool": .Attribute(.Number(.Boolean(true))),
            "myColour": .Attribute(.Transformable(NSColor.blueColor()))
        ]
        
        do {
            try CoreModelTests.store.create(newTestEntity, initialValues: valuesObject)
        } catch {
            XCTFail("Failed to create a new test entity in the store. Error: \(error)")
            return
        }
     
        XCTAssert(true, "Created a new test entity in the store.")
 
        let entity = Resource(CoreModelTests.testEntityName, identifier)
        
        do {
            let yupNope = try CoreModelTests.store.exists(entity)

            XCTAssert(yupNope, "The entity with identifier \(identifier) should exist in the store")
        } catch {
            XCTFail("Resource \(identifier) added successfully above yet doesn't exist in the store any longer.")
        }
    }
    
    func testBadAttribute() {
        guard let _ = CoreModelTests.model[CoreModelTests.testEntityName] else {
            XCTFail("Unable to find an entity named \(CoreModelTests.testEntityName) in the model \(CoreModelTests.model)")
            return
        }

        let impossibleResource = Resource(CoreModelTests.testEntityName, "impossibleResource")
        let valuesObject: ValuesObject = ["missingAttribute": .Attribute(.Number(.Double(98.76543)))]
        
        do {
            try CoreModelTests.store.create(impossibleResource, initialValues: valuesObject)
        } catch StoreError.InvalidValues {
            XCTAssert(true, "Caught that missingAttribute isn't a valid Attribute name")
        } catch {
            XCTFail("Shouldn't have gotten an error like \(error) here")
            return
        }

        do {
            // Confirm that there was no impossible resource created
            
            let shouldBeFalse = try CoreModelTests.store.exists(impossibleResource)
            
            XCTAssertFalse(shouldBeFalse, "Shouldn't have created this TestEntity after the StoreError.InvalidValues error, right?")
        } catch {
            // Should there be an error, or just the expected ```false``` above?
        }
    }
}
