//
//  CDAModel.m
//  CoreModel
//
//  Created by Alsey Coleman Miller on 3/27/15.
//  Copyright (c) 2015 ColemanCDA. All rights reserved.
//

#import "CDAModel.h"
#import "CDAEntityDescription.h"

// JSON Keys

OFString *const CDAModelEntitiesKey = @"CDAModelEntitiesKey";

@implementation CDAModel

#pragma mark - Initialization

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        
    }
    return self;
}

-(instancetype)initWithContentsOfFile:(OFString *)file
{
    self = [super init];
    if (self) {
        
        // get JSON
        
        OFString *stringData = [OFString stringWithContentsOfFile:file encoding:OF_STRING_ENCODING_UTF_8];
        
        if (stringData == nil) {
            
            return nil;
        }
        
        OFDictionary *jsonObject = [stringData JSONValue];
        
        if (![jsonObject isKindOfClass:[OFDictionary class]]) {
            
            return nil;
        }
        
        // parse entities
        OFArray *entitiesJSON = jsonObject[CDAModelEntitiesKey];
        
        if ([entitiesJSON isKindOfClass:[OFArray class]]) {
            
            
        }
        
    }
    return self;
}

@end

#pragma mark - JSON Initialization

@implementation CDAEntityDescription (JSON)

- (instancetype)initWithJSONObject:(OFDictionary *)JSONObject
{
    self = [super init];
    if (self) {
        
        
        
    }
    return self;
}

@end

