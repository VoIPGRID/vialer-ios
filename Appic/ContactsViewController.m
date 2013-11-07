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

@interface ContactsViewController()
@property (nonatomic, strong) NSTimer *updateStatusTimer;
@property (nonatomic, strong) NSDictionary *callStatuses;
@property (nonatomic, strong) CTCallCenter *callCenter;
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
            [weakSelf dismissStatus];
            NSLog(@"callEventHandler: %@", call.callState);
        }];
    }
    return self;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)dismissStatus {
    [self.updateStatusTimer invalidate];
    self.updateStatusTimer = nil;
    [SVProgressHUD dismiss];
}

#pragma mark - Navigation controller delegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if ([navigationController.viewControllers indexOfObject:viewController] == 0) {
        viewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]]];

        if ([viewController isKindOfClass:[UITableViewController class]]) {
            UITableViewController *tableViewController = (UITableViewController *)viewController;
            tableViewController.tableView.sectionIndexColor = [UIColor colorWithRed:0x9b / 255.f green:0xc3 / 255.f blue:0x2f / 255.f alpha:1.f];
        }
    }
    viewController.navigationItem.rightBarButtonItem = nil;
}

#pragma mark - People picker delegaate

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker {
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person {
    return YES;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
    if (property == kABPersonPhoneProperty) {
        ABMultiValueRef multiPhones = ABRecordCopyValue(person, kABPersonPhoneProperty);
    	for (CFIndex i = 0; i < ABMultiValueGetCount(multiPhones); i++) {
    		if (identifier == ABMultiValueGetIdentifierAtIndex(multiPhones, i)) {
    			CFStringRef phoneNumberRef = ABMultiValueCopyValueAtIndex(multiPhones, i);
    			CFRelease(multiPhones);

    			__block NSString *phoneNumber = (__bridge NSString *)phoneNumberRef;
    			CFRelease(phoneNumberRef);

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
                            self.updateStatusTimer = [NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(updateStatusInterval:) userInfo:info repeats:YES];

                            return;
                        }
                    }
                    [SVProgressHUD dismiss];
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    [SVProgressHUD dismiss];

                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Call failed", nil) message:NSLocalizedString(@"Failed to set up a call.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil];
                    [alert show];
                }];
            }
        }
    }
    return NO;
}

#pragma mark - Timer

- (void)updateStatusForResponse:(id)responseObject withInfo:(NSDictionary *)info {
    if ([responseObject isKindOfClass:[NSDictionary class]]) {
        NSDictionary *json = (NSDictionary *)responseObject;
        if ([[json objectForKey:@"status"] isKindOfClass:[NSString class]]) {
            NSString *status = [json objectForKey:@"status"];
            if ([status isEqualToString:@"disconnected"]) {
                [self dismissStatus];
            } else {
                NSString *statusDescription = [self.callStatuses objectForKey:status];
                if (statusDescription) {
                    NSString *callStatus = [NSString stringWithFormat:statusDescription, [info objectForKey:@"dialedNumber"]];
                    [SVProgressHUD showWithStatus:callStatus];
                }
            }
        }
    }
}

- (void)updateStatusInterval:(NSTimer *)timer {
    NSString *callId = [timer.userInfo objectForKey:@"callId"];
    [[VoysRequestOperationManager sharedRequestOperationManager] clickToDialStatusForCallId:callId success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self updateStatusForResponse:responseObject withInfo:timer.userInfo];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    }];
}

@end
