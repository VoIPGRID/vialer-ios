//
//  PhoneNumberUtils.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import "PhoneNumberUtils.h"

#import "NSString+Mobile.h"

@implementation PhoneNumberUtils

+ (NSCharacterSet *)digitsCharacterSet {
    static NSCharacterSet *_digitsCharacterSet;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _digitsCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789+"] invertedSet];
    });
    return _digitsCharacterSet;
}

+ (NSArray *)prefixes {
    NSArray *prefixes = nil;
    NSString *mobileCC = [NSString systemCallingCode];
    if ([mobileCC length]) {
        prefixes = @[mobileCC, [@"00" stringByAppendingString:[mobileCC stringByReplacingOccurrencesOfString:@"+" withString:@""]], @"0"];
    }
    return prefixes;
}

+ (NSString *)removePrefixFromPhoneNumber:(NSString *)phoneNumber {
    NSArray *prefixes = [[self class] prefixes];
    NSString *digits = [[phoneNumber componentsSeparatedByCharactersInSet:[[self class] digitsCharacterSet]] componentsJoinedByString:@""];

    if (prefixes) {
        for (NSString *prefix in prefixes) {
            if ([digits hasPrefix:prefix]) {
                // Remove prefix.
                return [digits substringFromIndex:[prefix length]];
            }
        }
    }
    return digits;
}

+ (NSString *)cleanPhoneNumber:(NSString *)phoneNumber {
    phoneNumber = [[phoneNumber componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsJoinedByString:@""];
    phoneNumber = [[phoneNumber componentsSeparatedByCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"+0123456789*#"] invertedSet]] componentsJoinedByString:@""];
    return [phoneNumber isEqualToString:@""] ? nil : phoneNumber;
}

@end
