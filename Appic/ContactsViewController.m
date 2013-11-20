//
//  ContactsViewController.m
//  Appic
//
//  Created by Reinier Wieringa on 06/11/13.
//  Copyright (c) 2013 Voys. All rights reserved.
//

#import "ContactsViewController.h"
#import "VoysRequestOperationManager.h"

#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>

#import "SVProgressHUD.h"

#define DASHBOARD_ALERT_TAG 100

@interface ContactsViewController()
@property (nonatomic, strong) NSTimer *updateStatusTimer;
@property (nonatomic, strong) NSDictionary *callStatuses;
@property (nonatomic, strong) CTCallCenter *callCenter;
@property (nonatomic, strong) NSDictionary *userInfo;
@end

@implementation ContactsViewController

- (id)init {
    self = [super init];
    if (self) {
        self.delegate = self;
        self.peoplePickerDelegate = self;
        self.title = NSLocalizedString(@"Contacts", nil);
        self.tabBarItem.image = [UIImage imageNamed:@"contacts"];

        self.callStatuses = [NSDictionary dictionaryWithObjectsAndKeys:
                             NSLocalizedString(@"Your phone is being called...", nil), @"dialing_a",
                             NSLocalizedString(@"Press 1 to answer the call", nil), @"confirm",
                             NSLocalizedString(@"%@ is being called...", nil), @"dialing_b",
                             NSLocalizedString(@"Connected", nil), @"connected",
                             NSLocalizedString(@"Disconnected", nil), @"disconnected",
                             NSLocalizedString(@"Phone couldn't be reached", nil), @"failed_a",
                             NSLocalizedString(@"The number is on the blacklist", nil), @"blacklisted",
                             NSLocalizedString(@"%@ could not be reached", nil), @"failed_b",
                             nil];

        __weak typeof(self) weakSelf = self;
        self.callCenter = [[CTCallCenter alloc] init];
        [self.callCenter setCallEventHandler:^(CTCall *call) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf dismissStatus:nil];
            });
            NSLog(@"callEventHandler: %@", call.callState);
        }];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActiveNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self dismissStatus:nil];
}

- (void)dismissStatus:(NSString *)status {
    [self.updateStatusTimer invalidate];
    self.updateStatusTimer = nil;
    if (status) {
        [SVProgressHUD showErrorWithStatus:status];
    } else {
        [SVProgressHUD dismiss];
    }
}

- (BOOL)handlePerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
    if (property == kABPersonPhoneProperty) {
        ABMultiValueRef multiPhones = ABRecordCopyValue(person, kABPersonPhoneProperty);
    	for (CFIndex i = 0; i < ABMultiValueGetCount(multiPhones); i++) {
    		if (identifier == ABMultiValueGetIdentifierAtIndex(multiPhones, i)) {
    			CFStringRef phoneNumberRef = ABMultiValueCopyValueAtIndex(multiPhones, i);
    			CFRelease(multiPhones);
                
    			NSString *phoneNumber = (__bridge NSString *)phoneNumberRef;
    			CFRelease(phoneNumberRef);

                [self handlePhoneNumber:phoneNumber];
            }
        }
    }
    return NO;
}

- (void)handlePhoneNumber:(NSString *)phoneNumber {
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Dialing...", nil)];
    
    phoneNumber = [[phoneNumber componentsSeparatedByCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet]] componentsJoinedByString:@""];
    phoneNumber = [@"+" stringByAppendingString:phoneNumber];
    
    NSLog(@"Calling %@...", phoneNumber);
    
    [[VoysRequestOperationManager sharedRequestOperationManager] clickToDialNumber:phoneNumber success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *json = (NSDictionary *)responseObject;
            if ([[json objectForKey:@"callid"] isKindOfClass:[NSString class]]) {
                NSString *callId = [json objectForKey:@"callid"];
                if (self.updateStatusTimer) {
                    [self.updateStatusTimer invalidate];
                }
                
                NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:callId, @"callId", phoneNumber, @"dialedNumber", nil];
                [self updateStatusForResponse:responseObject withInfo:info];
                self.userInfo = info;
                self.updateStatusTimer = [NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(updateStatusInterval:) userInfo:nil repeats:YES];
                [[NSRunLoop currentRunLoop] addTimer:self.updateStatusTimer forMode:NSDefaultRunLoopMode];
                return;
            }
        }
        [SVProgressHUD dismiss];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [SVProgressHUD dismiss];
        
        NSString *errorMessage = NSLocalizedString(@"Failed to set up a call.", nil);
        if ([operation.responseString isEqualToString:@"Extensions or phonenumbers not valid"]) {
            errorMessage = [[errorMessage stringByAppendingString:@"\n"] stringByAppendingString:NSLocalizedString(@"Extensions or phonenumbers not valid.", nil)];
        }

        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Call failed", nil) message:errorMessage delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil];
        [alert show];
    }];
}

- (void)dashboard {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Log out", nil) message:NSLocalizedString(@"Are you sure you want to log out?", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"No", nil) otherButtonTitles:NSLocalizedString(@"Yes", nil), nil];
    [alert show];
    alert.tag = DASHBOARD_ALERT_TAG;
}

#pragma mark - Alert view delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == DASHBOARD_ALERT_TAG) {
        if (buttonIndex == 1) {
            [[VoysRequestOperationManager sharedRequestOperationManager] logout];
        }
    }
}

#pragma mark - Navigation controller delegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if ([navigationController.viewControllers indexOfObject:viewController] == 0) {
        viewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]]];
        viewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"logout"] style:UIBarButtonItemStyleBordered target:self action:@selector(dashboard)];

        if ([viewController isKindOfClass:[UITableViewController class]]) {
            UITableViewController *tableViewController = (UITableViewController *)viewController;
            tableViewController.tableView.sectionIndexColor = [UIColor colorWithRed:0x3c / 255.f green:0x3c / 255.f blue:0x50 / 255.f alpha:1.f];
//            tableViewController.tableView.sectionIndexColor = [UIColor colorWithRed:0x9b / 255.f green:0xc3 / 255.f blue:0x2f / 255.f alpha:1.f];
        }
    } else {
        viewController.navigationItem.rightBarButtonItem = nil;
    }
}

#pragma mark - People picker delegaate

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker {
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person {
    return YES;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
    return [self handlePerson:person property:property identifier:identifier];
}

#pragma mark - Timer

- (void)updateStatusForResponse:(id)responseObject withInfo:(NSDictionary *)info {
    if ([responseObject isKindOfClass:[NSDictionary class]]) {
        NSDictionary *json = (NSDictionary *)responseObject;
        if ([[json objectForKey:@"status"] isKindOfClass:[NSString class]]) {
            NSString *status = [json objectForKey:@"status"];
            NSString *statusDescription = [self.callStatuses objectForKey:status];
            NSString *callStatus = nil;
            if (statusDescription) {
                callStatus = [NSString stringWithFormat:statusDescription, [info objectForKey:@"dialedNumber"]];
            }

            if ([@[@"disconnected", @"failed_a", @"blacklisted", @"failed_b"] containsObject:status]) {
                [self dismissStatus:callStatus];
            } else {
                if (callStatus) {
                    [SVProgressHUD showWithStatus:callStatus];
                }
            }
        }
    }
}

- (void)updateStatusInterval:(NSTimer *)timer {
    NSLog(@"Update status");
    __block NSDictionary *userInfo = self.userInfo;
    NSString *callId = [userInfo objectForKey:@"callId"];
    [[VoysRequestOperationManager sharedRequestOperationManager] clickToDialStatusForCallId:callId success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self updateStatusForResponse:responseObject withInfo:userInfo];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    }];
}

#pragma mark - Notifications

- (void)didBecomeActiveNotification:(NSNotification *)notification {
    [self dismissStatus:nil];
}

@end
