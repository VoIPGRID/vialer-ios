//
//  RecentCall.m
//  Vialer
//
//  Created by Reinier Wieringa on 13/11/13.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import "RecentCall.h"

#import "ContactModel.h"

#import "ContactsUI/ContactsUI.h"

#import "NSDate+RelativeDate.h"
#import "NSString+Mobile.h"

static NSString * const RecentCallDestinationNumber = @"dst_number";
static NSString * const RecentCallSourceNumber = @"src_number";
static NSString * const RecentCallATime = @"atime";
static NSString * const RecentCallDirection = @"direction";
static NSString * const RecentCallOutbound = @"outbound";
static NSString * const RecentCallDate = @"call_date";
static NSString * const RecentCallCallerId = @"callerid";

@implementation RecentCall

- (id)initWithDictionary:(NSDictionary *)dict {
    if (self = [super init]) {
        self.callerRecordId = -1;
        self.contactIdentifier = @"";
        self.callerPhoneType = NSLocalizedString(@"phone", nil);
        self.atime = [[dict objectForKey:RecentCallATime] integerValue];
        self.callDirection = [[dict objectForKey:RecentCallDirection] isEqualToString:RecentCallOutbound] ? CallDirectionOutbound : CallDirectionInbound;
        self.callDate = [dict objectForKey:RecentCallDate];

        if (self.callDirection == CallDirectionInbound) {
            self.callerId = [[[dict objectForKey:RecentCallCallerId] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\""]] componentsJoinedByString:@""];
            self.callerName = [dict objectForKey:RecentCallSourceNumber];
            self.callerPhoneNumber = [dict objectForKey:RecentCallSourceNumber];
        } else {
            self.callerName = [dict objectForKey:RecentCallDestinationNumber];
            self.callerPhoneNumber = [dict objectForKey:RecentCallDestinationNumber];
        }
    }
    return self;
}

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    }
    if (!other || ![other isKindOfClass:[self class]]) {
        return NO;
    }
    return [self isEqualToRecentCall:other];
}

- (BOOL)isEqualToRecentCall:(RecentCall *)other {
    if (self == other) {
        return YES;
    }
    if (self.callerRecordId >= 0 && self.callerRecordId == other.callerRecordId) {
        return YES;
    }
    if (!(!self.callerName && !other.callerName) && ![self.callerName isEqualToString:other.callerName]) {
        return NO;
    }
    return YES;
}

+ (NSArray *)syncRecentsFromObjects:(NSArray *)objects {
    if (!objects) {
        return @[];
    }

    NSMutableArray *recents = [NSMutableArray array];
    for (NSDictionary *dict in objects) {
        [recents addObject:[[RecentCall alloc] initWithDictionary:dict]];
    }

    if (!recents.count) {
        return @[];
    }

    // Calculate calling code prefixes (NOTE: Only works in some countries, like The Netherlands)
    NSArray *prefixes = nil;
    NSString *mobileCC = [NSString systemCallingCode];
    if ([mobileCC length]) {
        prefixes = @[mobileCC, [@"00" stringByAppendingString:[mobileCC stringByReplacingOccurrencesOfString:@"+" withString:@""]], @"0"];
    }

    for (CNContact *contact in [ContactModel defaultContactModel].allContacts) {
        NSArray *phoneNumbers = contact.phoneNumbers;
        for (CNLabeledValue *phoneNumber in phoneNumbers) {
            CNPhoneNumber *cnPhoneNumber = phoneNumber.value;
            NSString *phoneNumberDigits = cnPhoneNumber.stringValue;
            NSString *digits = [[phoneNumberDigits componentsSeparatedByCharactersInSet:[[self class] digitsCharacterSet]] componentsJoinedByString:@""];
            NSString *phoneNumberLabel = [CNLabeledValue localizedStringForLabel:phoneNumber.label];

            if (prefixes) {
                for (NSString *prefix in prefixes) {
                    if ([digits hasPrefix:prefix]) {
                        // Remove prefix
                        digits = [digits substringFromIndex:[prefix length]];
                        break;
                    }
                }
            }

            NSArray *filtered = [recents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF._callerPhoneNumber ENDSWITH[cd] %@", digits]];
            if ([filtered count]) {
                for (RecentCall *recent in filtered) {
                    recent.contactIdentifier = contact.identifier;
                    recent.callerName = [CNContactFormatter stringFromContact:contact style:CNContactFormatterStyleFullName];
                    recent.callerPhoneType = phoneNumberLabel;
                }
            }
        }
    }
    return recents;
}

+ (void)clearCachedRecentCalls {
    @synchronized([self class]) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"RecentsCache"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

+ (NSArray *)cachedRecentCalls {
    @synchronized([self class]) {
        NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:@"RecentsCache"];
        if (!data) {
            return @[];
        }

        NSError *error = nil;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        NSArray *objects = [dict objectForKey:@"objects"];
        if (!objects) {
            return @[];
        }

        return [self syncRecentsFromObjects:objects];
    }
}

+ (NSArray *)recentCallsFromDictionary:(NSDictionary *)dict {
    @synchronized([self class]) {
        NSError *error = nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
        if (data) {
            [[NSUserDefaults standardUserDefaults] setObject:data forKey:@"RecentsCache"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }

    return [self syncRecentsFromObjects:[dict objectForKey:@"objects"]];
}

+ (NSCharacterSet *)digitsCharacterSet {
    static NSCharacterSet *_digitsCharacterSet;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _digitsCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789+"] invertedSet];
    });
    return _digitsCharacterSet;
}

@end
