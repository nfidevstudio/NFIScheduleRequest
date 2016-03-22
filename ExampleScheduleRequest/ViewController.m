//
//  ViewController.m
//  ExampleScheduleRequest
//
//  Created by jcarlos on 22/3/16.
//  Copyright © 2016 jcarlosEstela. All rights reserved.
//

#import "ViewController.h"
#import "User.h"
#import "NFIScheduleRequest.h"

@interface ViewController ()

@property (nonatomic, strong) User *user;
@property (nonatomic, weak) IBOutlet UITextField *userField;
@property (nonatomic, weak) IBOutlet UITextField *passField;
@property (nonatomic, strong) NFIScheduleRequest *scheduleRequest;

@end

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
