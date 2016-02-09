//
//  RecentCall+VoIPGRID.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import "RecentCall+VoIPGRID.h"

#import "NSString+Mobile.h"
#import "ContactModel.h"
#import "ContactsUI/ContactsUI.h"

static NSString * const RecentCallVoIPGRIDObjectArray           = @"objects";
static NSString * const RecentCallVoIPGRIDID                    = @"id";
static NSString * const RecentCallVoIPGRIDDuration              = @"atime";
static NSString * const RecentCallVoIPGRIDDirection             = @"direction";
static NSString * const RecentCallVoIPGRIDInbound               = @"inbound";
static NSString * const RecentCallVoIPGRIDDate                  = @"call_date";
static NSString * const RecentCallVoIPGRIDCallerID              = @"callerid";
static NSString * const RecentCallVoIPGRIDSourceNumber          = @"src_number";
static NSString * const RecentCallVoIPGRIDDestinationNumber     = @"dst_number";

@implementation RecentCall (VoIPGRID)

+ (NSArray *)createRecentCallsFromVoIGPRIDResponseData:(NSDictionary *)responseData inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    // Create or find the RecentCalls that are given in the responseData.
    NSArray *objects = responseData[RecentCallVoIPGRIDObjectArray];
    NSMutableArray *recents = [[NSMutableArray alloc] init];
    for (NSDictionary *dict in objects) {
        RecentCall *newRecentCall = [RecentCall createRecentCallFromVoIPGRIDDictionary:dict inManagedObjectContext:managedObjectContext];
        if (newRecentCall) {
            [recents addObject:newRecentCall];
        }
    }

    if (recents.count == 0) {
        return nil;
    }

    NSArray *prefixes = [[self class] prefixes];

    // Loop trough every contact and check if one of the calls has a matching phonenumber.
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
                        // Remove prefix.
                        digits = [digits substringFromIndex:[prefix length]];
                        break;
                    }
                }
            }

            NSArray *filtered = [recents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.sourceNumber ENDSWITH[cd] %@ OR SELF.destinationNumber ENDSWITH[cd] %@", digits, digits]];
            if ([filtered count]) {
                for (RecentCall *recent in filtered) {
                    recent.callerRecordID = contact.identifier;
                    recent.callerName = [CNContactFormatter stringFromContact:contact style:CNContactFormatterStyleFullName];
                    recent.phoneType = phoneNumberLabel;
                }
            }
        }
    }

    // Save the calls to the ManagedObjectContext.
    NSError *error;
    if (![managedObjectContext save:&error]) {
        NSLog(@"Error saving Recent call: %@", error);
    }

    return recents;
}

+ (RecentCall *)createRecentCallFromVoIPGRIDDictionary:(NSDictionary *)dictionary inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {

    RecentCall *recentCall = [RecentCall findRecentCallByID:dictionary[RecentCallVoIPGRIDID] inManagedObjectContext:managedObjectContext];
    if (recentCall) {
        return recentCall;
    }

    RecentCall *newRecentCall = [NSEntityDescription insertNewObjectForEntityForName:@"RecentCall" inManagedObjectContext:managedObjectContext];
    if (!newRecentCall) {
        return nil;
    }

    newRecentCall.callID = dictionary[RecentCallVoIPGRIDID];
    newRecentCall.phoneType = NSLocalizedString(@"phone", nil);
    newRecentCall.duration = dictionary[RecentCallVoIPGRIDDuration];
    newRecentCall.inbound = @([dictionary[RecentCallVoIPGRIDDirection] isEqualToString:RecentCallVoIPGRIDInbound]);

    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    format.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss";
    newRecentCall.callDate = [format dateFromString:dictionary[RecentCallVoIPGRIDDate]];

    if ([newRecentCall.inbound boolValue]) {
        newRecentCall.callerID = dictionary[RecentCallVoIPGRIDCallerID];
        newRecentCall.sourceNumber = dictionary[RecentCallVoIPGRIDSourceNumber];
    } else {
        newRecentCall.destinationNumber = dictionary[RecentCallVoIPGRIDDestinationNumber];
    }

    return newRecentCall;
}

+ (RecentCall *)findRecentCallByID:(NSNumber *)callID inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = [NSEntityDescription entityForName:@"RecentCall" inManagedObjectContext:managedObjectContext];
    request.predicate = [NSPredicate predicateWithFormat: @"callID == %@", callID];

    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"callDate" ascending:YES];
    request.sortDescriptors = @[sortDescriptor];

    NSError *error = nil;
    NSArray *result = [managedObjectContext executeFetchRequest:request error:&error];

    if (result && result.count && !error ) {
        return result[0];
    }
    return nil;
}

#pragma mark - Utils

/**
 *  This method will return a NSCharacterSet without Digits.
 *
 *  @return a NSCharacterSet without Digits
 */
+ (NSCharacterSet *)digitsCharacterSet {
    static NSCharacterSet *_digitsCharacterSet;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _digitsCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789+"] invertedSet];

    });
    return _digitsCharacterSet;
}

/**
 *  Calculate calling code prefixes (NOTE: Only works in some countries, like The Netherlands).
 *
 *  @return Array with possible prefixes.
 */
+ (NSArray *)prefixes {
    NSArray *prefixes = nil;
    NSString *mobileCC = [NSString systemCallingCode];
    if ([mobileCC length]) {
        prefixes = @[mobileCC, [@"00" stringByAppendingString:[mobileCC stringByReplacingOccurrencesOfString:@"+" withString:@""]], @"0"];
    }
    return prefixes;
}

@end
