//
//  CallingViewController.m
//  Vialer
//
//  Created by Reinier Wieringa on 05/12/13.
//  Copyright (c) 2013 Voys. All rights reserved.
//

#import "CallingViewController.h"
#import "VoysRequestOperationManager.h"

#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>

#define PHONE_NUMBER_ALERT_TAG 100
#define FAILED_ALERT_TAG       101

@interface CallingViewController ()
@property (nonatomic, strong) NSTimer *updateStatusTimer;
@property (nonatomic, strong) NSDictionary *callStatuses;
@property (nonatomic, strong) CTCallCenter *callCenter;
@property (nonatomic, strong) NSDictionary *clickToDialStatus;
@property (nonatomic, strong) NSString *toNumber;
@property (nonatomic, strong) NSString *toContact;
@end

@implementation CallingViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.callStatuses = [NSDictionary dictionaryWithObjectsAndKeys:
                             NSLocalizedString(@"Your phone is being called...", nil), @"dialing_a",
                             NSLocalizedString(@"Press 1 to answer the call", nil), @"confirm",
                             NSLocalizedString(@"%@ is being called...", nil), @"dialing_b",
                             NSLocalizedString(@"Calling...", nil), @"connected",
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

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self dismissStatus:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0f ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
}

#pragma mark - Alert view delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == PHONE_NUMBER_ALERT_TAG) {
        if (buttonIndex == 1) {
            UITextField *mobileNumberTextField = [alertView textFieldAtIndex:0];
            if ([mobileNumberTextField.text length]) {
                [[NSUserDefaults standardUserDefaults] setObject:mobileNumberTextField.text forKey:@"MobileNumber"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                [self clickToDial];
            }
        }
    } else if (alertView.tag == FAILED_ALERT_TAG) {
        [self dismiss];
    }
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dismissStatus:(NSString *)status {
    [self.updateStatusTimer invalidate];
    self.updateStatusTimer = nil;
    if (status) {
        [self showErrorWithStatus:status];
    } else {
        [self dismiss];
    }
    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
}

- (void)showWithStatus:(NSString *)status {
    self.statusLabel.text = status;
}

- (void)showErrorWithStatus:(NSString *)status {
    self.statusLabel.text = status;
    [self performSelector:@selector(dismiss) withObject:nil afterDelay:1.5f];
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

                NSString *fullName = (__bridge NSString *)ABRecordCopyCompositeName(person);
                if (!fullName) {
                    NSString *firstName = (__bridge NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
                    NSString *middleName = (__bridge NSString *)ABRecordCopyValue(person, kABPersonMiddleNameProperty);
                    NSString *lastName = (__bridge NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
                    if (firstName) {
                        fullName = [NSString stringWithFormat:@"%@ %@%@", firstName, [middleName length] ? [NSString stringWithFormat:@"%@ ", middleName] : @"", lastName];
                    }
                }

                [self handlePhoneNumber:phoneNumber forContact:fullName];
            }
        }
    }
    return NO;
}

- (void)handlePhoneNumber:(NSString *)phoneNumber forContact:(NSString *)contact {
    self.toNumber = phoneNumber;
    self.toContact = contact ? contact : phoneNumber;

    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"MobileNumber"]) {
        [self clickToDial];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Mobile number", nil) message:NSLocalizedString(@"Please provide your mobile number for calling you back.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Ok", nil), nil];
        alert.tag = PHONE_NUMBER_ALERT_TAG;
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alert textFieldAtIndex:0].keyboardType = UIKeyboardTypePhonePad;
        [alert show];
    }
}

- (void)clickToDial {
    if (!self.presentingViewController) {
        [[[[UIApplication sharedApplication] delegate] window].rootViewController presentViewController:self animated:YES completion:nil];
    }
    
    [self showWithStatus:NSLocalizedString(@"Dialing...", nil)];
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    
    self.toNumber = [[self.toNumber componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsJoinedByString:@""];
    self.toNumber = [[self.toNumber componentsSeparatedByCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"+0123456789"] invertedSet]] componentsJoinedByString:@""];
    
    NSLog(@"Calling %@...", self.toNumber);
    
    self.contactLabel.text = self.toContact;

    [[VoysRequestOperationManager sharedRequestOperationManager] clickToDialToNumber:self.toNumber fromNumber:[[NSUserDefaults standardUserDefaults] objectForKey:@"MobileNumber"] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *json = (NSDictionary *)responseObject;
            if ([[json objectForKey:@"callid"] isKindOfClass:[NSString class]]) {
                if (self.updateStatusTimer) {
                    [self.updateStatusTimer invalidate];
                }
                
                [self updateStatusForResponse:responseObject];
                self.updateStatusTimer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(updateStatusInterval:) userInfo:nil repeats:YES];
                [[NSRunLoop currentRunLoop] addTimer:self.updateStatusTimer forMode:NSDefaultRunLoopMode];
                return;
            }
        }
        [self dismiss];
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        
        NSString *errorMessage = NSLocalizedString(@"Failed to set up a call.", nil);
        if ([operation.responseString isEqualToString:@"Extensions or phonenumbers not valid"]) {
            errorMessage = [[errorMessage stringByAppendingString:@"\n"] stringByAppendingString:NSLocalizedString(@"Extensions or phonenumbers not valid.", nil)];
        } else if ([operation.responseString isEqualToString:@"User has no permission to provide a_number for ClickToDial"]) {
            errorMessage = [[errorMessage stringByAppendingString:@"\n"] stringByAppendingString:NSLocalizedString(@"You don't have permission to provide a mobile number in Click to dial.", nil)];
        }

        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Call failed", nil) message:errorMessage delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil];
        alert.tag = FAILED_ALERT_TAG;
        [alert show];
    }];
}

#pragma mark - Timer

- (void)updateStatusForResponse:(id)responseObject {
    if ([responseObject isKindOfClass:[NSDictionary class]]) {
        self.clickToDialStatus = responseObject;

        if ([[self.clickToDialStatus objectForKey:@"status"] isKindOfClass:[NSString class]]) {
            NSString *status = [self.clickToDialStatus objectForKey:@"status"];
            if (status) {
                NSString *statusDescription = [self.callStatuses objectForKey:status];
                NSString *callStatus = nil;
                if (statusDescription) {
                    callStatus = [NSString stringWithFormat:statusDescription, [self.clickToDialStatus objectForKey:@"b_number"]];
                }
                
                if ([@[@"disconnected", @"failed_a", @"blacklisted", @"failed_b"] containsObject:status]) {
                    [self dismissStatus:callStatus];
                } else if (callStatus) {
                    [self showWithStatus:callStatus];
                }
            }
        }
    }
}

- (void)updateStatusInterval:(NSTimer *)timer {
    NSLog(@"Update status");
    NSString *callId = [self.clickToDialStatus objectForKey:@"callid"];
    if ([callId length]) {
        [[VoysRequestOperationManager sharedRequestOperationManager] clickToDialStatusForCallId:callId success:^(AFHTTPRequestOperation *operation, id responseObject) {
            [self updateStatusForResponse:responseObject];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error %@", [error localizedDescription]);
        }];
    }
}

#pragma mark - Notifications

- (void)didBecomeActiveNotification:(NSNotification *)notification {
    [self dismissStatus:nil];
}

@end
