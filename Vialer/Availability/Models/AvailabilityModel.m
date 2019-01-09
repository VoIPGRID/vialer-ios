//
//  AvailabilityModel.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "AvailabilityModel.h"
#import "SystemUser.h"

#import "VoIPGRIDRequestOperationManager.h"

NSString * const AvailabilityModelSelected = @"availabilitySelected";
NSString * const AvailabilityModelDestinationType = @"availabilityType";
NSString * const AvailabilityModelId = @"availabilityId";

static NSString *const AvailabilityModelFixedDestinationsKey = @"fixeddestinations";
static NSString *const AvailabilityModelPhoneaccountsKey = @"phoneaccounts";
static NSString *const AvailabilityModelDescriptionKey = @"description";
static NSString *const AvailabilityModelInternalNumbersKey = @"internal_number";
static NSString *const AvailabilityModelResourceUriKey = @"resource_uri";
static NSString *const AvailabilityModelSelectedUserDestinationKey = @"selecteduserdestination";
static NSString *const AvailabilityModelSelectedUserDestinationPhoneaccountKey = @"phoneaccount";
static NSString *const AvailabilityModelSelectedUserDestinationFixedKey = @"fixeddestination";
static NSString *const AvailabilityModelSelectedUserDestinationIdKey = @"id";

static NSTimeInterval const AvailabilityModelFetchInterval = 3600; // number of seconds between fetching of availability

@interface AvailabilityModel()
@property (nonatomic, strong) NSArray *availabilityOptions;
@property (nonatomic, strong) NSString *availabilityResourceUri;
@property (strong, nonatomic) VoIPGRIDRequestOperationManager *voipgridRequestOperationManager;
@end

@implementation AvailabilityModel

- (VoIPGRIDRequestOperationManager *)voipgridRequestOperationManager {
	if (!_voipgridRequestOperationManager) {
		_voipgridRequestOperationManager = [[VoIPGRIDRequestOperationManager alloc] initWithDefaultBaseURL];
	}
	return _voipgridRequestOperationManager;
}

- (void)getUserDestinations:(void (^)(NSString *localizedErrorString))completion {
    [self.voipgridRequestOperationManager userDestinationsWithCompletion:^(NSURLResponse *operation, NSDictionary *responseData, NSError *error) {
        // Check if error happend.
        if (error) {
            NSString *localizedStringError = NSLocalizedString(@"Error getting the availability options", nil);
            if (completion) {
                completion(localizedStringError);
            }
        } else {
            // Successful fetch of user destinations.
            [self userDestinationsToArray: responseData[@"objects"][0]];
            if (completion) {
                completion(nil);
            }
        }
    }];
}

- (void)userDestinationsToArray:(NSDictionary *) userDestinations {
    NSMutableArray *destinations = [[NSMutableArray alloc] init];
    NSArray *phoneAccounts = [userDestinations objectForKey:AvailabilityModelPhoneaccountsKey];
    NSArray *fixedDestinations = [userDestinations objectForKey:AvailabilityModelFixedDestinationsKey];
    NSDictionary *selectedDestination = [userDestinations objectForKey:AvailabilityModelSelectedUserDestinationKey];
    NSString *phoneAccountDestination = [selectedDestination objectForKey:AvailabilityModelSelectedUserDestinationPhoneaccountKey];
    NSString *fixedDestination = [selectedDestination objectForKey:AvailabilityModelSelectedUserDestinationFixedKey];

    NSNumber *availabilitySelected = @0;
    if ([phoneAccountDestination isEqual:[NSNull null]] && [fixedDestination isEqual: [NSNull null]]) {
        availabilitySelected = @1;
    }

    NSDictionary *defaultDict = @{
                                  SystemUserAvailabilityDescriptionKey: NSLocalizedString(@"Not available", nil),
                                  SystemUserAvailabilityPhoneNumberKey: @0,
                                  AvailabilityModelSelected: availabilitySelected,
                                  };
    [destinations addObject: defaultDict];

    [destinations addObjectsFromArray:[self createDestinations:phoneAccounts withDestinationType:AvailabilityModelSelectedUserDestinationPhoneaccountKey withSelectedDestination:selectedDestination]];
    [destinations addObjectsFromArray:[self createDestinations:fixedDestinations withDestinationType:AvailabilityModelSelectedUserDestinationFixedKey withSelectedDestination:selectedDestination]];

    self.availabilityOptions = destinations;
    self.availabilityResourceUri = [selectedDestination objectForKey:AvailabilityModelResourceUriKey];
}

- (NSArray *)createDestinations:(NSArray*)userDestinations withDestinationType:(NSString*)destinationType withSelectedDestination:(NSDictionary*)selectedDestination {
    NSNumber *phoneNumber;

    NSMutableArray *destinations = [[NSMutableArray alloc] init];
    if ([userDestinations count]) {
        for (NSDictionary *userDestination in userDestinations){
            NSNumber *availabilitySelected = [NSNumber numberWithBool:NO];

            if ([destinationType isEqualToString: AvailabilityModelSelectedUserDestinationFixedKey]) {
                NSNumberFormatter *nsNumberFormatter = [[NSNumberFormatter alloc] init];
                phoneNumber = [nsNumberFormatter numberFromString:[userDestination objectForKey:SystemUserAvailabilityPhoneNumberKey]];
            }else{
                phoneNumber =  [userDestination objectForKey:AvailabilityModelInternalNumbersKey];
            }

            if (![[selectedDestination objectForKey:destinationType] isEqual:[NSNull null]]) {
                // Cast both values to strings. Because of old API code that sent an id as a number and the other as a string.
                id availabilityDestinationId = [userDestination objectForKey: AvailabilityModelSelectedUserDestinationIdKey];
                id selectedDestinationType = [selectedDestination objectForKey:destinationType];

                if (![availabilityDestinationId isKindOfClass:[NSString class]]) {
                    availabilityDestinationId = [availabilityDestinationId stringValue];
                }

                if (![selectedDestinationType isKindOfClass:[NSString class]]) {
                    selectedDestinationType = [selectedDestinationType stringValue];
                }

                if ([availabilityDestinationId isEqualToString:selectedDestinationType]){

                    availabilitySelected = [NSNumber numberWithBool:YES];
                    [[SystemUser currentUser] storeNewAvailabilityInSUD:@{SystemUserAvailabilityPhoneNumberKey: phoneNumber, SystemUserAvailabilityDescriptionKey:[userDestination objectForKey:AvailabilityModelDescriptionKey]}];
                }
            }
            NSDictionary *destination = @{
                                          AvailabilityModelId: [userDestination objectForKey:AvailabilityModelSelectedUserDestinationIdKey],
                                          SystemUserAvailabilityDescriptionKey: [userDestination objectForKey:AvailabilityModelDescriptionKey],
                                          SystemUserAvailabilityPhoneNumberKey: phoneNumber,
                                          AvailabilityModelSelected: availabilitySelected,
                                          AvailabilityModelDestinationType: destinationType,
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

    if ([[selectedDict objectForKey:AvailabilityModelDestinationType] isEqualToString:AvailabilityModelSelectedUserDestinationPhoneaccountKey]) {
        phoneaccount = [selectedDict objectForKey:AvailabilityModelId];
    } else if ([[selectedDict objectForKey:AvailabilityModelDestinationType] isEqualToString:AvailabilityModelSelectedUserDestinationFixedKey]) {
        fixedDestination = [selectedDict objectForKey:AvailabilityModelId];
    }

    NSDictionary *saveDict = @{
                               AvailabilityModelSelectedUserDestinationPhoneaccountKey: phoneaccount,
                               AvailabilityModelSelectedUserDestinationFixedKey: fixedDestination,
                               };

    [self.voipgridRequestOperationManager pushSelectedUserDestination:self.availabilityResourceUri
                                                      destinationDict:saveDict
                                                       withCompletion:^(NSURLResponse *operation, NSDictionary *responseData, NSError *error) {
        // Check if there was an error.
        if (error) {
            NSString *error = NSLocalizedString(@"Saving availability has failed", nil);
            if (completion) {
                completion(error);
            }
            return;
        }
        [[SystemUser currentUser] storeNewAvailabilityInSUD:selectedDict];
        if (completion) {
            completion(nil);
        }
    }];
}

- (void)getCurrentAvailabilityWithBlock:(void (^)(NSString *currentAvailability, NSString *localizedError))completionBlock {
    NSDictionary *currentAvailability = [SystemUser currentUser].currentAvailability;

    // Check no availability.
    if (!currentAvailability[SystemUserAvailabilityLastFetchKey] ||
        // Or outdated.
        fabs([(NSDate *)currentAvailability[SystemUserAvailabilityLastFetchKey] timeIntervalSinceNow]) > AvailabilityModelFetchInterval) {
        // Fetch new info.
        [self getUserDestinations:^(NSString *localizedErrorString) {
            // Error.
            if (localizedErrorString) {
                completionBlock(nil, localizedErrorString);
            }

            for (NSDictionary *option in self.availabilityOptions) {
                // Find current selected.
                if ([option[AvailabilityModelSelected] isEqualToNumber:@1]) {
                    //Create string and update SUD.
                    NSString *newAvailabilityString = [[SystemUser currentUser] storeNewAvailabilityInSUD:option];
                    // Return new string.
                    completionBlock(newAvailabilityString, nil);
                    break;
                }
            }
        }];
    } else {
        // Return existing key.
        completionBlock(currentAvailability[SystemUserAvailabilityAvailabilityKey], nil);
    }
}

@end
