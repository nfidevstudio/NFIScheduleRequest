//
//  NFIEncode.h
//  ExampleSimplePersist
//
//  Created by jcarlos on 16/2/16.
//  Copyright © 2016 José Carlos. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NFIEncode : NSObject

/**
 * Encode the object with the given class
 **/
+ (void)encodeWithCoder:(NSCoder *)encoder andClass:(Class)objectClass;

/**
 * Decode to object with the given class
 **/
+ (id)initWithCoder:(NSCoder *)decoder andClass:(Class)objectClass;

@end
