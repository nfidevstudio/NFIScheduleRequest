# NFIScheduleRequest - v 0.1.0

### The best way to schedule requests when no internet connection

# Entity Configuration

NFIScheduleRequest is based on NFISimplePersist. So, its mandatory that your entity implements the NFISimplePersistObjectProtocol, like:

```objective-c
#import "User.h"

@interface User () <NFISimplePersistObjectProtocol> 

@end

@implementation User

#pragma mark - Init

- (instancetype)initWithId:(NSString *)id user:(NSString *)user andPass:(NSString *)pass {
    self = [super init];
    if (self) {
        _user = user;
        _pass = pass;
        _id = id;
    }
    return self;
}

#pragma mark - NFISimplePersistObjectProtocol

+ (NSString *)uniqueIdentifier {
    return @"id";
}

- (NSDictionary *)saveAsDictionary {
    return @{@"user" : _user,
            @"pass" : _pass,
            @"id" : _id
            };
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        _user = dictionary[@"user"];
        _pass = dictionary[@"pass"];
        _id = dictionary[@"id"];
    }
    return self;
}

@end
```

# NFIScheduleRequest Usage

First, add to your project the <strong>libsqlite3.0.tdb</strong> framework. 

You must configure the schedule request refresh policy, add this to AppDelegate:

```Objective-c
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self configureScheduleRequest];
    return YES;
}

#pragma mark - Configure Schedule Request

- (void)configureScheduleRequest {
    NFIScheduleRequest *scheduleRequest = [[NFIScheduleRequest sharedInstance] initWithScheduleRequestRefreshPolicy:NFIScheduleRequestPolicyWhenInternetConnectionTurnOn];
}
```

There are a some kind of refresh policy:

```Objective-c
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
```

Now, add the classes that implements the upload of every model that you wants:

```Objective-c
[scheduleRequest registerRepository:[AppServices class] forClass:[User class]];
```

<strong>NOTE: It's important that your repository class implements a static method with format : + (void)uploadModelClass:(ModelClass *)object.</strong> 

For example:

```Objective-c
#import <Foundation/Foundation.h>

@class User;

@interface AppServices : NSObject

#pragma mark - User Services

+ (void)uploadUser:(User *)user;

@end
```

Then, in the implementation of this method:

```objective-c
@implementation AppServices

#pragma mark - User Services

+ (void)uploadUser:(User *)user {
    //Implements here the user upload to server
    NSLog(@"Uploading user... %ld",user.identifier);
    //Notify NFIScheduleRequest that the object was uploaded correctly
    [[NFIScheduleRequest sharedInstance] objectUploaded:user];
}

@end
```

When you want to add a model to schedule, you must call scheduleRequestOfObject where you want:

```Objective-c
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _scheduleRequest = [NFIScheduleRequest sharedInstance];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

- (IBAction)login:(id)sender {
    if (![_userField.text isEqualToString:@""] && ![_passField.text isEqualToString:@""]) {
        _user = [[User alloc] initWithIdentifier:0 user:_userField.text andPass:_userField.text];
        [_scheduleRequest scheduleRequestOfObject:_user];
    }
}

@end
```

To manually upload:

```Objective-c
[_scheduleRequest tryToUploadNow];
```

To know how many entities are scheduled:

```Objective-c
[_scheduleRequest queueRequests];
```

### Now, enjoy it!!