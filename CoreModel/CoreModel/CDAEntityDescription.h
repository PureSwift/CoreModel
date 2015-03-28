//
//  CDAEntityDescription.h
//  CoreModel
//
//  Created by Alsey Coleman Miller on 3/27/15.
//  Copyright (c) 2015 ColemanCDA. All rights reserved.
//

#import <ObjFW/ObjFW.h>
@class CDAModel;

/** Describes an entity. */
@interface CDAEntityDescription : OFObject <OFCopying>

#pragma mark - Properties

/** Name of the entity. */
@property (copy) NSString *name;

@property (readonly, assign) CDAModel *model;

@property (copy) OFString *className;

@property (getter=isAbstract) BOOL abstract;

@property NSArray *subentities;

@property (readonly, assign) CDAEntityDescription *superentity;

#pragma mark - TODO: Implement non-essential functionality

/*

#pragma mark Convenience Properties

@property (readonly, copy) NSDictionary *subentitiesByName;

@property (readonly, copy) NSDictionary *propertiesByName;

@property (readonly, copy) NSDictionary *attributesByName;

#pragma mark - Methods

- (NSArray *)relationshipsWithDestinationEntity:(CDAEntityDescription *)entity;
 
 */

@end
