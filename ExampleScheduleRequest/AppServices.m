//
//  AppServices.m
//  ExampleScheduleRequest
//
//  Created by jcarlos on 22/3/16.
//  Copyright © 2016 jcarlosEstela. All rights reserved.
//

#import "AppServices.h"
#import "User.h"
#import "NFIScheduleRequest.h"

@implementation AppServices

#pragma mark - User Services

+ (void)performUserRequest:(User *)user {
    //Implements here the user upload to server
    NSLog(@"Uploading user... %ld",user.identifier);
    //Notify NFIScheduleRequest that the object was uploaded correctly
    [[NFIScheduleRequest sharedInstance] requestOfObject:user performedSuccess:YES];
}

@end
