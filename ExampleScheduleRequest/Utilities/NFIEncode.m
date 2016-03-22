//
//  NFIEncode.m
//  ExampleSimplePersist
//
//  Created by jcarlos on 16/2/16.
//  Copyright © 2016 José Carlos. All rights reserved.
//

#import "NFIEncode.h"
#import <objc/runtime.h>

@import UIKit;

@implementation NFIEncode

+ (void)encodeWithCoder:(NSCoder *)encoder andClass:(Class)objectClass {
    unsigned int numProps = 0;
    unsigned int i = 0;
    objc_property_t *props = class_copyPropertyList(objectClass, &numProps);
    for (i = 0; i < numProps; i++) {
        objc_property_t property = props[i];
        NSString *prop = [NSString stringWithUTF8String:property_getName(property)];
        const char * type = property_getAttributes(property);
        NSString * typeString = [NSString stringWithUTF8String:type];
        NSArray * attributes = [typeString componentsSeparatedByString:@","];
        NSString * typeAttribute = [attributes objectAtIndex:0];
        NSString * propertyType = [typeAttribute substringFromIndex:1];
        const char * rawPropertyType = [propertyType UTF8String];
        
        if (strcmp(rawPropertyType, @encode(CGFloat)) == 0) {
            [encoder encodeFloat:[[self valueForKey:prop]floatValue] forKey:prop];
        } else if (strcmp(rawPropertyType, @encode(NSInteger)) == 0) {
            [encoder encodeInteger:[[self valueForKey:prop]integerValue] forKey:prop];
        } else if (strcmp(rawPropertyType, @encode(BOOL)) == 0) {
            [encoder encodeBool:[[self valueForKey:prop]boolValue] forKey:prop];
        } else {
            [encoder encodeObject:[self valueForKey:prop] forKey:prop];
        }
    }
}

+ (id)initWithCoder:(NSCoder *)decoder andClass:(Class)objectClass {
    id object = [[objectClass alloc]init];
    unsigned int numProps = 0;
    unsigned int i = 0;
    objc_property_t *props = class_copyPropertyList([object class], &numProps);
    for (i = 0; i < numProps; i++) {
        objc_property_t property = props[i];
        NSString *prop = [NSString stringWithUTF8String:property_getName(property)];
        const char * type = property_getAttributes(property);
        NSString * typeString = [NSString stringWithUTF8String:type];
        NSArray * attributes = [typeString componentsSeparatedByString:@","];
        NSString * typeAttribute = [attributes objectAtIndex:0];
        NSString * propertyType = [typeAttribute substringFromIndex:1];
        const char * rawPropertyType = [propertyType UTF8String];
        
        if (strcmp(rawPropertyType, @encode(CGFloat)) == 0) {
            [object setValue:[NSNumber numberWithFloat:[decoder decodeFloatForKey:prop]] forKey:prop];
        } else if (strcmp(rawPropertyType, @encode(NSInteger)) == 0) {
            [object setValue:[NSNumber numberWithInteger:[decoder decodeIntegerForKey:prop]] forKey:prop];
        } else if (strcmp(rawPropertyType, @encode(BOOL)) == 0) {
            [object setValue:[NSNumber numberWithBool:[decoder decodeBoolForKey:prop]] forKey:prop];
        } else {
            NSString *classString = [[[[NSString stringWithUTF8String:rawPropertyType]stringByReplacingOccurrencesOfString:@"@" withString:@""]stringByReplacingOccurrencesOfString:@"\\\"" withString:@""]stringByReplacingOccurrencesOfString:@"\"" withString:@""];
            Class cls = NSClassFromString(classString);
            id o = [[cls alloc]init];
            o = [decoder decodeObjectForKey:prop];
            [object setValue:(o== nil ? [NSNull null] : o) forKey:prop];
        }
    }
    return object;
}

@end
