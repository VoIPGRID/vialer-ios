//
//  PhoneNumberModel.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import "PhoneNumberModel.h"

#import <ContactsUI/ContactsUI.h>
#import "ContactModel.h"
#import "ContactUtils.h"
#import "PhoneNumberUtils.h"

@interface PhoneNumberModel()
@property (readwrite, nonatomic) NSString *displayName;
@property (readwrite, nonatomic) NSString *phoneNumberLabel;
@property (readwrite, nonatomic) NSString *contactIdentifier;
@property (readwrite, nonatomic) NSString *foundContactPhoneNumber;
@property (readwrite, nonatomic) NSString *callerInfo;
@end

@implementation PhoneNumberModel

- (BOOL)getContactWithPhoneNumber:(NSString *)phoneNumber {

    // Loop trough every contact and check if one of the contacts has a matching number to the incomming number.
    for (CNContact *contact in [ContactModel defaultContactModel].allContacts) {
        BOOL success = [self getContactInformationFromContact:contact withPhoneNumberToMatch:phoneNumber];
        if (success)  {
            return YES;
        }
    }
    return NO;
}

- (BOOL)getContactInformationFromContact:(CNContact *)contact withPhoneNumberToMatch:(NSString *)phoneNumber {
    NSString *phoneNumberDigits = [PhoneNumberUtils removePrefixFromPhoneNumber:phoneNumber];
    NSArray *contactPhoneNumbers = contact.phoneNumbers;
    for (CNLabeledValue *contactPhoneNumber in contactPhoneNumbers) {
        CNPhoneNumber *cnPhoneNumber = contactPhoneNumber.value;
        NSString *contactPhoneNumberDigits = [PhoneNumberUtils removePrefixFromPhoneNumber:cnPhoneNumber.stringValue];
        NSString *contactPhoneNumberLabel = [CNLabeledValue localizedStringForLabel:contactPhoneNumber.label];

        contactPhoneNumberDigits = [PhoneNumberUtils removePrefixFromPhoneNumber:contactPhoneNumberDigits];
        if ([contactPhoneNumberDigits isEqualToString:phoneNumberDigits]) {
            self.displayName = [ContactUtils getDisplayNameForContact:contact];
            self.phoneNumberLabel = contactPhoneNumberLabel;
            self.foundContactPhoneNumber = cnPhoneNumber.stringValue;
            self.contactIdentifier = contact.identifier;
            return YES;
        }
    }
    return NO;
}

+ (void)getCallNameFromContact:(CNContact *)contact andPhoneNumber:(NSString *)phoneNumber withCompletion:(void (^)(PhoneNumberModel * _Nonnull))completion {
    PhoneNumberModel *model = [[[self class] alloc] init];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        BOOL success = [model getContactInformationFromContact:contact withPhoneNumberToMatch:phoneNumber];

        if (success) {
            model.callerInfo = model.displayName;
            if (model.phoneNumberLabel) {
                model.callerInfo = [model.callerInfo stringByAppendingString:[NSString stringWithFormat:@"\n%@", model.phoneNumberLabel]];
            }
        }

        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(model);
            });
        }
    });
}

+ (void)getCallName:(VSLCall *)call withCompletion:(void (^ _Nullable)(PhoneNumberModel * _Nonnull))completion {
    PhoneNumberModel *model = [[[self class] alloc] init];
    BOOL success = [model getContactWithPhoneNumber:call.callerNumber];

    if (success) {
        model.callerInfo = model.displayName;
        if (model.phoneNumberLabel) {
            model.callerInfo = [model.callerInfo stringByAppendingString:[NSString stringWithFormat:@"\n%@", model.phoneNumberLabel]];
        }
    } else if (call.callerName && call.callerNumber) {
        model.callerInfo = [NSString stringWithFormat:@"%@\n%@", call.callerName, call.callerNumber];
    } else if (call.callerName && !call.callerNumber) {
        model.callerInfo = [NSString stringWithFormat:@"%@", call.callerName];
    } else if (!call.callerName && call.callerNumber) {
        model.callerInfo = [NSString stringWithFormat:@"%@", call.callerNumber];
    } else {
        model.callerInfo = [NSString stringWithFormat:@"%@", call.remoteURI];
    }

    if (completion) {
        completion(model);
    }
}

@end
