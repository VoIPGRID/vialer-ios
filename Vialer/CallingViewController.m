//
//  CallingViewController.m
//  Vialer
//
//  Created by Reinier Wieringa on 05/12/13.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import "CallingViewController.h"
#import "VoIPGRIDRequestOperationManager.h"
#import "SelectRecentsFilterViewController.h"
#import "ConnectionHandler.h"
#import "NSString+Mobile.h"

#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>

#define PHONE_NUMBER_ALERT_TAG 100
#define FAILED_ALERT_TAG       102

// API responses
#define dialingAKey     @"@dialing_a"
#define confirmKey      @"confirm"
#define dailingBKey     @"dailing_b"
#define connectedKey    @"connected"
#define disconnectedKey @"disconnected"
#define failedAKey      @"failed_a"
#define failedBKey      @"failed_b"

@interface CallingViewController ()
@property (nonatomic, strong) NSTimer *updateStatusTimer;
@property (nonatomic, strong) NSDictionary *callStatuses;
@property (nonatomic, strong) CTCallCenter *callCenter;
@property (nonatomic, strong) NSDictionary *clickToDialStatus;
@property (nonatomic, strong) NSString *toNumber;
@property (nonatomic, strong) NSString *toContact;
@property (nonatomic, strong) NSString *mobileCC;
@end

@implementation CallingViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self setupCellularCallEventsListener];
    }
    return self;
}

- (void)setupCellularCallEventsListener {
    __weak typeof(self) weakSelf = self;
    [self.callCenter setCallEventHandler:^(CTCall *call) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf dismissStatus:nil];
        });
        NSLog(@"callEventHandler: %@", call.callState);
    }];
}

- (CTCallCenter *)callCenter {
    if (!_callCenter) {
        self.callCenter = [[CTCallCenter alloc] init];
    }
    return _callCenter;
}

- (NSDictionary *)callStatuses {
    if (!_callStatuses) {
        _callStatuses = @{
                          dialingAKey: NSLocalizedString(@"Your phone is being called...", nil),
                          confirmKey: NSLocalizedString(@"Press 1 to answer the call", nil),
                          dailingBKey: NSLocalizedString(@"%@ is being called...", nil),
                          connectedKey: NSLocalizedString(@"Calling...", nil),
                          disconnectedKey: NSLocalizedString(@"Disconnected", nil),
                          failedAKey: NSLocalizedString(@"Phone couldn't be reached", nil),
                          failedBKey: NSLocalizedString(@"%@ could not be reached", nil),
                          };
    }
    return _callStatuses;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupLayout];
}

- (void)setupLayout {
    self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);

    CGFloat buttonXSpace = self.view.frame.size.width / 3.4f;
    CGFloat leftOffset = (self.view.frame.size.width - (3.f * buttonXSpace)) / 2.f;
    self.contactLabel.frame = CGRectMake(leftOffset, self.contactLabel.frame.origin.y, self.view.frame.size.width - (leftOffset * 2.f), self.contactLabel.frame.size.height);
    self.infoLabel.frame = CGRectMake(leftOffset, self.infoLabel.frame.origin.y, self.infoLabel.frame.size.width, self.infoLabel.frame.size.height);

    self.contactLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:32.f];

    self.statusLabel.text = NSLocalizedString(@"A classic connection is being established. The default dialer will now be opened.", nil);
    self.statusLabel.frame = CGRectMake(leftOffset, self.statusLabel.frame.origin.y, self.view.frame.size.width - (leftOffset * 2), self.statusLabel.frame.size.height);
    [self.statusLabel sizeToFit];

    self.infoImageView.frame = CGRectMake(self.infoImageView.frame.origin.x, self.statusLabel.frame.origin.y + self.statusLabel.frame.size.height + 20.f, self.infoImageView.frame.size.width, self.infoImageView.frame.size.height);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActiveNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self dismissStatus:nil];
}

#pragma mark - Alert view delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == PHONE_NUMBER_ALERT_TAG) {
        if (buttonIndex == 1) {
            UITextField *mobileNumberTextField = [alertView textFieldAtIndex:0];
            NSString *mobileNumber = [mobileNumberTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if ([mobileNumber length] && ![mobileNumber isEqualToString:self.mobileCC]) {
                [[NSUserDefaults standardUserDefaults] setObject:mobileNumberTextField.text forKey:@"MobileNumber"];
                [[NSUserDefaults standardUserDefaults] synchronize];

                [[NSNotificationCenter defaultCenter] postNotificationName:RECENTS_FILTER_UPDATED_NOTIFICATION object:nil];
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

- (void)showInfo:(NSString *)info {
    self.infoLabel.hidden = NO;
    self.infoLabel.text = info;
    [self.infoLabel sizeToFit];
    // Center align the label with the new text
    self.infoLabel.center = CGPointMake(CGRectGetMidX(self.view.bounds), self.infoLabel.center.y);
    // Align the pixels if needed
    self.infoLabel.frame = CGRectIntegral(self.infoLabel.frame);
}

- (void)handlePhoneNumber:(NSString *)phoneNumber forContact:(NSString *)contact {
    self.toNumber = phoneNumber;
    self.toContact = contact ? contact : phoneNumber;
    [self clickToDial];
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
    
    NSString *fromNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"MobileNumber"];
    fromNumber = [[fromNumber componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsJoinedByString:@""];
    fromNumber = [[fromNumber componentsSeparatedByCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"+0123456789"] invertedSet]] componentsJoinedByString:@""];

    self.contactLabel.text = self.toContact;
    if ([ConnectionHandler sharedConnectionHandler].accountStatus == GSAccountStatusInvalid) {
        [self showInfo:NSLocalizedString(@"NO WIFI OR 4G", nil)];
    } else {
        self.infoLabel.hidden = YES;
    }
    [self showWithStatus:NSLocalizedString(@"A classic connection is being established. The default dialer will now be opened.", nil)];

    [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] clickToDialToNumber:self.toNumber fromNumber:fromNumber success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
        } else if ([operation.responseString isEqualToString:@"Click to Dial object not found"]) {
            errorMessage = [[errorMessage stringByAppendingString:@"\n"] stringByAppendingString:NSLocalizedString(@"Click to Dial not supported for this account.", nil)];
        }

        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Call failed", nil) message:errorMessage delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil];
        alert.tag = FAILED_ALERT_TAG;
        [alert show];
    }];
}

#pragma mark - Textfield delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if (newString.length != [[newString componentsSeparatedByCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"+0123456789 ()"] invertedSet]] componentsJoinedByString:@""].length) {
        return NO;
    }
    return YES;
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
        [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] clickToDialStatusForCallId:callId success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
