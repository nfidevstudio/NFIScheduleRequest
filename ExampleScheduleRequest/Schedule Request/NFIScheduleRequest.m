//
//  NFIScheduleRequest.m
//  LeasePlan
//
//  Created by José Carlos on 18/1/16.
//  Copyright © 2016 José Carlos. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NFIScheduleRequest.h"
#import "Reachability.h"
#import "NFISimplePersistObject.h" 

typedef NS_ENUM (NSInteger, NFIScheduleRequestStatus) {
    NFIScheduleRequestStatusUnknown,
    NFIScheduleRequestStatusPaused,
    NFIScheduleRequestStatusRunning,
};

@interface NFIScheduleRequest ()

@property (nonatomic, assign) NFIScheduleRequestRefreshPolicy policy;
@property (nonatomic, strong) Reachability *reachability;
@property (nonatomic, assign) NFIScheduleRequestStatus status;
@property (nonatomic, strong) NSMutableDictionary *repositoryManager;
@property (nonatomic, strong) NFISimplePersist *persist;

@end

@implementation NFIScheduleRequest

#pragma mark - Instance.

/** Unique shared instance for NFIScheduleRequest.
 */
+ (instancetype)sharedInstance {
    static NFIScheduleRequest *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[NFIScheduleRequest alloc] init];
        _sharedInstance.reachability = [Reachability reachabilityWithHostname:@"www.google.com"];
        _sharedInstance.status = NFIScheduleRequestPolicyManually;
        _sharedInstance.repositoryManager = [[NSMutableDictionary alloc] init];
        _sharedInstance.persist = [NFISimplePersist standarSimplePersist];
    });
    return _sharedInstance;
}

#pragma mark - Init methods

/**
 *  Init the Schedule Request with a policy of refresh
 *
 *  @param policy
 */
- (instancetype)initWithScheduleRequestRefreshPolicy:(NFIScheduleRequestRefreshPolicy)policy {
    self = [super init];
    if (self) {
        _policy = policy;
        if (_policy == NFIScheduleRequestPolicyWhenInternetConnectionTurnOn) {
            [_reachability startNotifier];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(reachabilityStatusChanged:)
                                                         name:kReachabilityChangedNotification
                                                       object:nil];
        } else if (_policy == NFIScheduleRequestPolicyWhenApplicationBecomeActive) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(didBecomeActive:)
                                                         name:UIApplicationDidBecomeActiveNotification
                                                       object:nil];
        }
        if (_policy != NFIScheduleRequestPolicyManually) {
            [self beginEngine];
        }
    }
    return self;
}

#pragma mark - Notifications 

/**
 *  Notificated when application beacome active
 */
- (void)didBecomeActive:(NSNotification *)notification {
    [self beginEngine];
}

/**
 *  Notificated when reachability status changed
 */
- (void)reachabilityStatusChanged:(NSNotification *)notification {
    Reachability *reachability = (Reachability *)[notification object];
    if ([reachability isReachable]) {
        [self beginEngine];
    } else {
        [self pauseEngine];
    }
}

#pragma mark - Schedule Request Engine

- (void)beginEngine {
    @synchronized(self) {
        if (_status != NFIScheduleRequestStatusRunning) {
            _status = NFIScheduleRequestStatusRunning;
            NSLog(@"Begin engine to schedule requests");
            if ([self isReachable]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    id object  = [self loadFirstObject];
                    if (object) {
                        [self performSaveActionOfObject:object];
                    } else {
                        NSLog(@"No objects in queue");
                        [self pauseEngine];
                    }
                });
            }else {
                NSInteger timerSecs = -1;
                switch (_policy) {
                    case NFIScheduleRequestPolicyEvery5seconds:
                        timerSecs = 5;
                        break;
                    case NFIScheduleRequestPolicyEvery10seconds:
                        timerSecs = 10;
                        break;
                    case NFIScheduleRequestPolicyEvery20seconds:
                        timerSecs = 20;
                        break;
                    case NFIScheduleRequestPolicyEvery30seconds:
                        timerSecs = 30;
                        break;
                    case NFIScheduleRequestPolicyEvery1minute:
                        timerSecs = 60;
                        break;
                    case NFIScheduleRequestPolicyEvery2minutes:
                        timerSecs = 120;
                        break;
                    case NFIScheduleRequestPolicyEvery5minutes:
                        timerSecs = 300;
                        break;
                    default:
                        NSLog(@"Internet appears offline, waiting for event to wake up engine");
                        [self pauseEngine];
                        break;
                }
                if (timerSecs > 0) {
                    NSLog(@"Internet appears offline, delaying %ld seconds...",timerSecs);
                    NSTimer * timer = [[NSTimer alloc]initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:timerSecs]
                                                              interval:1.0f target:self selector:@selector(resumeEngine)
                                                              userInfo:nil repeats:NO];
                    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
                }
            }
        }
    }
}

- (void)resumeEngine {
    [self pauseEngine];
    [self beginEngine];
}

- (void)pauseEngine {
    _status = NFIScheduleRequestStatusPaused;
    NSLog(@"Pause engine");
}

#pragma mark - Actions

- (void)registerRepository:(id)repository forClass:(Class)classOfObject {
    [_repositoryManager setObject:NSStringFromClass([repository class]) forKey:NSStringFromClass(classOfObject)];
}

- (NSArray *)queueRequests {
    return [_persist loadAllObjects];
}

/**
 *  Schedule the request of save the object
 *
 *  @param object
 */
- (void)scheduleRequestOfObject:(id)object {
    if ([object conformsToProtocol:@protocol(NFISimplePersistObjectProtocol)]) {
        [self persistObject:object];
    } else {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:[NSString stringWithFormat:@"To schedule request of this object, it must be implements NFISimplePersistObjectProtocol protocol"]
                                     userInfo:nil];
    }
}

/**
 *  Call this method to try to upload the objects persisted manually.
 */
- (void)tryToPerformRequestNow {
    [self beginEngine];
}


/**
 * Notifiy to ScheludeRequest Manager that the request was performed successfully
 */
- (void)requestOfObject:(id)object performedSuccess:(BOOL)success {
    if (success) {
        [self removeObject:object];
        [self pauseEngine];
        if ([self queueRequests].count > 0) {
            [self beginEngine];
        }
    } else {
        [self pauseEngine];
        if ([self queueRequests].count > 0) {
            [self beginEngine];
        }
    }
}
#pragma mark - Private methods

- (BOOL)isReachable {
    if ([_reachability isReachable]) {
        return YES;
    } else {
        return NO;
    }
}

- (void)persistObject:(id)object {
    //Persist in the Realm data base
    [_persist saveObject:object];
    if (_policy != NFIScheduleRequestPolicyManually) {
        [self beginEngine];
    }
}

- (id)loadFirstObject {
    if ([self queueRequests].count > 0) {
        return [[self queueRequests] objectAtIndex:0];
    } else {
        return nil;
    }
}

- (void)removeObject:(id)object {
    [_persist removeObject:object];
}

- (void)performSaveActionOfObject:(id)object {
    if (_repositoryManager.allKeys.count == 0) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:[NSString stringWithFormat:@"You must register the repository class to upload the object"]
                                     userInfo:nil];
    }
    for (NSString *objectClass in _repositoryManager) {
        NSString *oClass = NSStringFromClass([object class]);
        if ([objectClass isEqualToString:oClass]) {
            Class class = NSClassFromString([_repositoryManager objectForKey:objectClass]);
            SEL selector = sel_registerName([[NSString stringWithFormat:@"perform%@Request:",objectClass] UTF8String]);
            @try {
                [class performSelector:selector
                            withObject:object
                            afterDelay:1.0];
            } @catch (NSException *exception) {
                @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                               reason:[NSString stringWithFormat:@"To schedule request of this object, you must define a method with format + (void)performClassRequest:(Class)object"]
                                             userInfo:nil];
            }
        }
    }
}

@end
