//
//  AppServices.h
//  ExampleScheduleRequest
//
//  Created by jcarlos on 22/3/16.
//  Copyright © 2016 jcarlosEstela. All rights reserved.
//

#import <Foundation/Foundation.h>

@class User;

@interface AppServices : NSObject

#pragma mark - User Services

+ (void)performUserRequest:(User *)user;

@end
