//
//  NFIScheduleRequest.h
//  LeasePlan
//
//  Created by José Carlos on 18/1/16.
//  Copyright © 2016 José Carlos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NFISimplePersist.h"

typedef NS_ENUM (NSInteger, NFIScheduleRequestRefreshPolicy) {
    NFIScheduleRequestPolicyWhenInternetConnectionTurnOn,
    NFIScheduleRequestPolicyWhenApplicationBecomeActive,
    NFIScheduleRequestPolicyEvery5seconds,
    NFIScheduleRequestPolicyEvery10seconds,
    NFIScheduleRequestPolicyEvery20seconds,
    NFIScheduleRequestPolicyEvery30seconds,
    NFIScheduleRequestPolicyEvery1minute,
    NFIScheduleRequestPolicyEvery2minutes,
    NFIScheduleRequestPolicyEvery5minutes,
    NFIScheduleRequestPolicyManually
};

extern NSString * const kPrefix;

@interface NFIScheduleRequest : NSObject

#pragma mark - Instance.

/** Unique shared instance for NFIScheduleRequest.
 */
+ (instancetype)sharedInstance;

#pragma mark - View life cicle

/**
 *  Init the Schedule Request with a policy of refresh. 
 *
 *  @param policy
 */
- (instancetype)initWithScheduleRequestRefreshPolicy:(NFIScheduleRequestRefreshPolicy)policy;

#pragma mark - Actions

/**
 * Register a repository class to upload data for a given object class.
 * Remember! The Repository class must implements a static method with name uploadClassName:(Class)object
 * i.e
 * + (void)uploadUser:(User *)user {
 *     Implements the upload here
 * }
 */
- (void)registerRepository:(id)repository forClass:(Class)classOfObject;

/**
 *  Schedule the request of save the object
 *
 *  @param object
 */
- (void)scheduleRequestOfObject:(id)object;

/**
 *  Call this method to try to upload the objects persisted manually.
 */
- (void)tryToUploadNow;

/**
 *  Return an array with all the elements in the qeuE
 */
- (NSArray *)queueRequests;

/**
 * Notifiy to ScheludeRequest Manager that the object was uploaded correctly
 */
- (void)objectUploaded:(id)object;

/**
 * Notifiy to ScheludeRequest Manager that the object was not uploaded correctly
 */
- (void)objectWasNotUploaded:(id)object;

@end
