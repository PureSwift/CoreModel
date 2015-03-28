//
//  CDAModelSupportDescriptor.h
//  CoreModel
//
//  Created by Alsey Coleman Miller on 3/27/15.
//  Copyright (c) 2015 ColemanCDA. All rights reserved.
//

#import <ObjFW/ObjFW.h>

/** Describes how to use the model on a specific platform, in this case ObjFW / Objective-C. */
@interface CDAModelSupportDescriptor : OFObject

#pragma mark - Initialization

-(instancetype)initWithContentsOfFile:(OFString *)file;

#pragma mark - Properties

/** Dictionary of class names mapped to their entity names. */
@property OFDictionary *entityClassNames;

/** Dictionary of class names mapped to their transformer names. */
@property OFDictionary *transformerClassNames;

@end
