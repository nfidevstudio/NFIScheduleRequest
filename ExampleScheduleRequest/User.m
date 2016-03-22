//
//  User.m
//  ExampleSimplePersist
//
//  Created by jcarlos on 15/2/16.
//  Copyright © 2016 José Carlos. All rights reserved.
//

#import "User.h"
#import "NFIEncode.h"

@implementation User

#pragma mark - Init

- (instancetype)initWithIdentifier:(NSInteger)identifier
                              user:(NSString *)user
                           andPass:(NSString *)pass {
    self = [super init];
    if (self) {
        _user = user;
        _pass = pass;
        _identifier = identifier;
    }
    return self;
}

#pragma mark - Encode Methods

- (void)encodeWithCoder:(NSCoder *)encoder {
    [NFIEncode encodeWithCoder:encoder andClass:[self class]];
}

- (id)initWithCoder:(NSCoder *)decoder {
    return [NFIEncode initWithCoder:decoder andClass:[self class]];
}

#pragma mark - NFISimplePersistObjectProtocol

+ (NSString *)uniqueIdentifier {
    return @"identifier";
}

- (NSDictionary *)saveAsDictionary {
    return @{@"user" : _user,
            @"pass" : _pass,
            @"identifier" : [NSNumber numberWithInteger: _identifier]
            };
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        _user = dictionary[@"user"];
        _pass = dictionary[@"pass"];
        _identifier = [dictionary[@"identifier"] integerValue];
    }
    return self;
}

@end
