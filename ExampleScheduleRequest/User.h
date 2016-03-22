//
//  User.h
//  ExampleSimplePersist
//
//  Created by jcarlos on 15/2/16.
//  Copyright © 2016 José Carlos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NFISimplePersistObject.h"

@interface User : NSObject <NFISimplePersistObjectProtocol>

@property (nonatomic, assign) NSInteger identifier;
@property (nonatomic, copy) NSString *user;
@property (nonatomic, copy) NSString *pass;

#pragma mark - Encode

- (void)encodeWithCoder:(NSCoder *)encoder;

#pragma mark - Init

- (instancetype)initWithIdentifier:(NSInteger)identifier
                              user:(NSString *)user
                           andPass:(NSString *)pass;

@end
