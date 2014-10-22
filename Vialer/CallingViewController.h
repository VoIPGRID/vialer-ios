//
//  CallingViewController.h
//  Vialer
//
//  Created by Reinier Wieringa on 05/12/13.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WelcomeViewController.h"

#import <AddressBookUI/AddressBookUI.h>

@interface CallingViewController : UIViewController<UITextFieldDelegate, WelcomeViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *contactLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

- (BOOL)handlePerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier;
- (void)handlePhoneNumber:(NSString *)phoneNumber forContact:(NSString *)contact;

@end
