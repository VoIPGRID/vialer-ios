//
//  ContactUtils.m
//  Vialer
//
//  Created by Redmer Loen on 27-10-15.
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "ContactUtils.h"

@implementation ContactUtils
+ (NSMutableAttributedString *)getFormattedStyledContact:(CNContact *)contact {
    NSString *fullName = [CNContactFormatter stringFromContact:contact style:CNContactFormatterStyleFullName];
    NSString *givenName = [contact givenName];

    if (!fullName) {
        return [[NSMutableAttributedString alloc] initWithString:@""];
    }

    NSMutableAttributedString *fullNameAttrString = [[NSMutableAttributedString alloc] initWithString: fullName];
    NSUInteger boldedLength = givenName.length;
    if (boldedLength > fullName.length) {
        boldedLength = fullName.length;
    }
    NSRange boldedRange = NSMakeRange(0, boldedLength);
    [fullNameAttrString addAttribute:NSFontAttributeName
                               value:[UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0]
                               range:boldedRange];
    return fullNameAttrString;
}

@end
