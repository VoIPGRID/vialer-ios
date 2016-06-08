//
//  ContactUtils.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "ContactUtils.h"

#import "ContactModel.h"
#import "PhoneNumberUtils.h"

@implementation ContactUtils

+ (NSMutableAttributedString *)getFormattedStyledContact:(CNContact *)contact {

    NSString *fullName = [CNContactFormatter stringFromContact:contact style:CNContactFormatterStyleFullName];

    if (!fullName) {
        NSString *otherContext = @"";
        NSArray *emailAdresses = contact.emailAddresses;

        if ([emailAdresses count]) {
            for (CNLabeledValue  *emailadress in emailAdresses) {
                otherContext = emailadress.value;
                break;
            }
        }
        return [[NSMutableAttributedString alloc] initWithString:otherContext];
    }

    NSMutableAttributedString *fullNameAttrString = [[NSMutableAttributedString alloc] initWithString: fullName];
    NSInteger boldedLength;
    NSString *familyName = [contact familyName];
    NSString *givenName = [contact givenName];

    if ([CNContactFormatter nameOrderForContact:contact] == CNContactDisplayNameOrderFamilyNameFirst) {
        boldedLength = familyName.length;

        if (boldedLength == 0) {
            boldedLength = givenName.length;
        }
    } else {
        boldedLength = givenName.length;
    }

    if (boldedLength > fullName.length) {
        boldedLength = fullName.length;
    }

    NSRange boldedRange = NSMakeRange(0, boldedLength);
    [fullNameAttrString addAttribute:NSFontAttributeName
                               value:[UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0]
                               range:boldedRange];
    return fullNameAttrString;
}

+ (NSString *)getDisplayNameForContact:(CNContact *)contact {
    NSString *fullName = [CNContactFormatter stringFromContact:contact style:CNContactFormatterStyleFullName];

    if (fullName) {
        return fullName;
    }

    for (CNLabeledValue  *emailadress in contact.emailAddresses) {
        return emailadress.value;
    }
    return nil;
}

@end
