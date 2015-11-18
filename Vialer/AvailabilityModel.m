//
//  AvailabilityModel.m
//  Vialer
//
//  Created by Redmer Loen on 15-09-15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import "AvailabilityModel.h"

#import "VoIPGRIDRequestOperationManager.h"

NSString * const kAvailabilityDescription = @"availabilityDescription";
NSString * const kAvailabilityPhoneNumber = @"availabilityPhoneNumber";
NSString * const kAvailabilitySelected = @"availabilitySelected";
NSString * const KAvailabilityDestinationType = @"availabilityType";
NSString * const kAvailabilityId = @"availabilityId";

static NSString *const kFixedDestinations = @"fixeddestinations";
static NSString *const kPhoneaccounts = @"phoneaccounts";
static NSString *const kPhoneNumber = @"phonenumber";
static NSString *const kDescription = @"description";
static NSString *const kInternalNumber = @"internal_number";
static NSString *const kResourceUri = @"resource_uri";
static NSString *const kSelectedUserDestination = @"selecteduserdestination";
static NSString *const kSelectedUserDestinationPhoneaccount = @"phoneaccount";
static NSString *const kSelectedUserDestinationFixed = @"fixeddestination";
static NSString *const kSelectedUserDestinationId = @"id";

static NSString * const AvailabilityModelSUDKey = @"AvailabilityModelSUDKey";
static NSString * const AvailabilityModelLastFetchKey = @"AvailabilityModelLastFetchKey";
static NSString * const AvailabilityModelAvailabilityKey = @"AvailabilityModelAvailabilityKey";
static NSTimeInterval const AvailabilityModelFetchInterval = 3600; // number of seconds between fetching of availability

@interface AvailabilityModel()
@property (nonatomic, strong) NSArray *availabilityOptions;
@property (nonatomic, strong) NSString *availabilityResourceUri;
@end

@implementation AvailabilityModel

- (void)getUserDestinations:(void (^)(NSString *localizedErrorString))completion {
    [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] userDestinationWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSArray *objecArray = [[NSArray alloc] initWithArray:[responseObject objectForKey:@"objects"]];
        NSDictionary *objectDict = [objecArray objectAtIndex:0];
        [self userDestinationsToArray: objectDict];
        if (completion) {
            completion(nil);
        }

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSString *localizedStringError = NSLocalizedString(@"Error getting the availability options", nil);
        if (completion) {
            completion(localizedStringError);
        }
    }];
}

- (void)userDestinationsToArray:(NSDictionary *) userDestinations {
    NSMutableArray *destinations = [[NSMutableArray alloc] init];
    NSArray *phoneAccounts = [userDestinations objectForKey:kPhoneaccounts];
    NSArray *fixedDestinations = [userDestinations objectForKey:kFixedDestinations];
    NSDictionary *selectedDestination = [userDestinations objectForKey:kSelectedUserDestination];
    NSString *phoneAccountDestination = [selectedDestination objectForKey:kSelectedUserDestinationPhoneaccount];
    NSString *fixedDestination = [selectedDestination objectForKey:kSelectedUserDestinationFixed];

    NSNumber *availabilitySelected = @0;
    if ([phoneAccountDestination isEqual:[NSNull null]] && [fixedDestination isEqual: [NSNull null]]) {
        availabilitySelected = @1;
    }

    NSDictionary *defaultDict = @{
                                  kAvailabilityDescription: NSLocalizedString(@"Not available", nil),
                                  kAvailabilityPhoneNumber: @0,
                                  kAvailabilitySelected: availabilitySelected,
                                  };
    [destinations addObject: defaultDict];

    [destinations addObjectsFromArray:[self createDestinations:phoneAccounts withDestinationType:kSelectedUserDestinationPhoneaccount withSelectedDestination:selectedDestination]];
    [destinations addObjectsFromArray:[self createDestinations:fixedDestinations withDestinationType:kSelectedUserDestinationFixed withSelectedDestination:selectedDestination]];

    self.availabilityOptions = destinations;
    self.availabilityResourceUri = [selectedDestination objectForKey:kResourceUri];
}

- (NSArray *)createDestinations:(NSArray*) userDestinations withDestinationType:(NSString*)destinationType withSelectedDestination:(NSDictionary*)selectedDestination {
    NSNumber *phoneNumber;

    NSMutableArray *destinations = [[NSMutableArray alloc] init];
    if ([userDestinations count]) {
        for (NSDictionary *userDestination in userDestinations){
            NSNumber *availabilitySelected = @0;

            if (destinationType == kSelectedUserDestinationFixed) {
                NSNumberFormatter *nsNumberFormatter = [[NSNumberFormatter alloc] init];
                phoneNumber = [nsNumberFormatter numberFromString:[userDestination objectForKey:kPhoneNumber]];
            }else{
                phoneNumber =  [userDestination objectForKey:kInternalNumber];
            }

            if (![[selectedDestination objectForKey:destinationType] isEqual:[NSNull null]]) {
                if ([[userDestination objectForKey:kSelectedUserDestinationId] isEqualToString:[[selectedDestination objectForKey:destinationType] stringValue]]){
                    availabilitySelected = @1;
                    [self storeNewAvialibityInSUD:@{kAvailabilityPhoneNumber: phoneNumber, kAvailabilityDescription:[userDestination objectForKey:kDescription]}];
                }
            }
            NSDictionary *destination = @{
                                          kAvailabilityId: [userDestination objectForKey:kSelectedUserDestinationId],
                                          kAvailabilityDescription: [userDestination objectForKey:kDescription],
                                          kAvailabilityPhoneNumber: phoneNumber,
                                          kAvailabilitySelected: availabilitySelected,
                                          KAvailabilityDestinationType: destinationType,
                                          };
            [destinations addObject: destination];

        }
    }
    return destinations;
}

- (void)saveUserDestination:(NSUInteger)index withCompletion:(void (^)(NSString *localizedErrorString))completion {
    NSDictionary *selectedDict = [self.availabilityOptions objectAtIndex: index];
    NSString *phoneaccount = @"";
    NSString *fixedDestination = @"";

    if ([[selectedDict objectForKey:KAvailabilityDestinationType] isEqualToString:kSelectedUserDestinationPhoneaccount]) {
        phoneaccount = [selectedDict objectForKey:kAvailabilityId];
    } else if ([[selectedDict objectForKey:KAvailabilityDestinationType] isEqualToString:kSelectedUserDestinationFixed]) {
        fixedDestination = [selectedDict objectForKey:kAvailabilityId];
    }

    NSDictionary *saveDict = @{
                               kSelectedUserDestinationPhoneaccount: phoneaccount,
                               kSelectedUserDestinationFixed: fixedDestination,
                               };

    [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] pushSelectedUserDestination:self.availabilityResourceUri destinationDict:saveDict success:^{
        [self storeNewAvialibityInSUD:selectedDict];
        if (completion) {
            completion(nil);
        }

    } failure:^(NSString *localizedErrorString) {
        NSString *error = NSLocalizedString(@"Saving availability has failed", nil);
        if (completion) {
            completion(error);
        }
    }];
}

- (void)getCurrentAvailabilityWithBlock:(void (^)(NSString *currentAvailability, NSString *localizedError))completionBlock {
    NSDictionary *currentAvailability = [[NSUserDefaults standardUserDefaults] objectForKey:AvailabilityModelSUDKey];

    // Check no avialability.
    if (!currentAvailability[AvailabilityModelLastFetchKey] ||
        // Or outdated.
        fabs([(NSDate *)currentAvailability[AvailabilityModelLastFetchKey] timeIntervalSinceNow]) > AvailabilityModelFetchInterval) {
        // Fetch new info.
        [self getUserDestinations:^(NSString *localizedErrorString) {
            // Error.
            if (localizedErrorString) {
                completionBlock(nil, localizedErrorString);
            }

            for (NSDictionary *option in self.availabilityOptions) {
                // Find current selected.
                if ([option[kAvailabilitySelected] isEqualToNumber:@1]) {
                    //Create string and update SUD.
                    NSString *newAvialabilityString = [self storeNewAvialibityInSUD:option];
                    // Return new string.
                    completionBlock(newAvialabilityString, nil);
                    break;
                }
            }
        }];
    } else {
        // Return existing key.
        completionBlock(currentAvailability[AvailabilityModelAvailabilityKey], nil);
    }
}

- (NSString *)storeNewAvialibityInSUD:(NSDictionary *)option {
    NSString *newAvialabilityString;

    if (![option[kAvailabilityPhoneNumber] isEqualToNumber:@0]) {
        newAvialabilityString = [NSString stringWithFormat:@"%@ / %@", option[kAvailabilityPhoneNumber], option[kAvailabilityDescription]];
    } else {
        newAvialabilityString = NSLocalizedString(@"Not available", nil);
    }

    NSDictionary *currentAvailability = @{
                            AvailabilityModelLastFetchKey:[NSDate date],
                            AvailabilityModelAvailabilityKey:newAvialabilityString,
                            };
    [[NSUserDefaults standardUserDefaults] setObject:currentAvailability forKey:AvailabilityModelSUDKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return newAvialabilityString;
}

@end
