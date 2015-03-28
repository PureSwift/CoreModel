//
//  CDAModel.h
//  CoreModel
//
//  Created by Alsey Coleman Miller on 3/27/15.
//  Copyright (c) 2015 ColemanCDA. All rights reserved.
//

#import <ObjFW/ObjFW.h>
#import <CDAFoundation/CDAFoundation.h>
@class CDAModelSupportDescriptor;

/** Describes the interface for a model description. */
@interface CDAModel : OFObject <OFCopying>

#pragma mark - Initialization

/** Tries to initialize a model from the description of a URL. Some entity information will be lacking without a supporting descriptor.*/
-(instancetype)initWithContentsOfFile:(OFString *)file;

/** Tries to initialize a model from the description of a URL that contains the model, and a supporting descriptor. */
-(instancetype)initWithContentsOfFile:(OFString *)file withModelSupportDescriptor:(CDAModelSupportDescriptor *)modelSupportDescriptor;

#pragma mark - Properties

/** The entities this model describes. */
@property (copy) OFArray *entities;

#pragma mark Convenience Properties

@property (copy, readonly) OFDictionary *entitiesByName;

@end
