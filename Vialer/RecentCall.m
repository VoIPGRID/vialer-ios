//
//  RecentCall.m
//  Vialer
//
//  Created by Reinier Wieringa on 13/11/13.
//  Copyright (c) 2013 Voys. All rights reserved.
//

#import "RecentCall.h"
#import "NSDate+RelativeDate.h"

#import <AddressBook/ABAddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

@interface RecentCall ()
@end

@implementation RecentCall

- (id)initWithDictionary:(NSDictionary *)dict {
    if (self = [super init]) {
        self.callerRecordId = -1;
        self.callerName = [dict objectForKey:@"src_number"];
        self.callerPhoneType = NSLocalizedString(@"phone", nil);

        self.callerPhoneNumber = [dict objectForKey:@"src_number"];
        self.callDirection = [[dict objectForKey:@"direction"] isEqualToString:@"outbound"] ? CallDirectionOutbound : CallDirectionInbound;
        self.callDate = [dict objectForKey:@"call_date"] ? [NSDate dateFromUtcString:[dict objectForKey:@"call_date"]] : [NSDate date];
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
    
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    if (ABAddressBookGetAuthorizationStatus != NULL) {
        if (ABAddressBookGetAuthorizationStatus() != kABAuthorizationStatusAuthorized) {
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
                dispatch_semaphore_signal(semaphore);
            });
            
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        }
    }
    
    if (ABAddressBookGetAuthorizationStatus() != kABAuthorizationStatusAuthorized) {
        return recents;
    }
#endif
    
    // Scan address book people for corresponding phone numbers
    NSArray *people = (__bridge NSArray *)ABAddressBookCopyArrayOfAllPeople(addressBook);
    if (people) {
        for (int i = 0; i < [people count]; i++) {
            ABRecordRef person = (__bridge ABRecordRef)([people objectAtIndex:i]);
            
            ABMutableMultiValueRef phoneNumbers = ABRecordCopyValue(person, kABPersonPhoneProperty);
            
            for (int k = 0; k < ABMultiValueGetCount(phoneNumbers); k++) {
                NSString *value = (__bridge NSString *)ABMultiValueCopyValueAtIndex(phoneNumbers, k);
                NSString *phoneNumber = [[value componentsSeparatedByCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet]] componentsJoinedByString:@""];
                phoneNumber = [@"+" stringByAppendingString:phoneNumber];
                
                NSArray *filtered = [recents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF._callerPhoneNumber == %@", phoneNumber]];
                if (filtered.count) {
                    for (RecentCall *recent in filtered) {
                        // Save record id for contact
                        recent.callerRecordId = ABRecordGetRecordID(person);
                        
                        // Save phone type
                        CFStringRef label = ABMultiValueCopyLabelAtIndex(phoneNumbers, k);
                        recent.callerPhoneType = (__bridge NSString *)(ABAddressBookCopyLocalizedLabel(label));
                        CFRelease(label);
                        
                        // Save name
                        NSString *fullName = (__bridge NSString *)ABRecordCopyCompositeName(person);
                        if (!fullName) {
                            NSString *firstName = (__bridge NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
                            NSString *middleName = (__bridge NSString *)ABRecordCopyValue(person, kABPersonMiddleNameProperty);
                            NSString *lastName = (__bridge NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
                            if (firstName) {
                                fullName = [NSString stringWithFormat:@"%@ %@%@", firstName, [middleName length] ? [NSString stringWithFormat:@"%@ ", middleName] : @"", lastName];
                            }
                        }
                        if (fullName) {
                            recent.callerName = fullName;
                        }
                    }
                }
            }
        }
    }
    
    CFRelease(addressBook);
    
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

@end
