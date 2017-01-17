//
//  RecentCall+VoIPGRID.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import "RecentCall+VoIPGRID.h"

#import "NSString+Mobile.h"
#import "ContactsUI/ContactsUI.h"
#import "PhoneNumberUtils.h"
#import "Vialer-Swift.h"

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
    VialerLogVerbose(@"Fetched %@ new recent(s)", [NSNumber numberWithFloat:objects.count].stringValue);

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

    // Loop trough every contact and check if one of the calls has a matching phonenumber.
    for (CNContact *contact in [ContactModel defaultModel].allContacts) {
        NSArray *phoneNumbers = contact.phoneNumbers;
        for (CNLabeledValue *phoneNumber in phoneNumbers) {
            CNPhoneNumber *cnPhoneNumber = phoneNumber.value;
            NSString *phoneNumberDigits = cnPhoneNumber.stringValue;
            NSString *digits = [PhoneNumberUtils removePrefixFromPhoneNumber:phoneNumberDigits];
            NSString *phoneNumberLabel = [CNLabeledValue localizedStringForLabel:phoneNumber.label];

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
        VialerLogError(@"Error saving Recent call: %@", error);
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

    RecentsTimeConverter *timeConverter = [[RecentsTimeConverter alloc] init];
    newRecentCall.callDate = [timeConverter dateFrom24hCETWithTimeString:dictionary[RecentCallVoIPGRIDDate]];

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

@end
