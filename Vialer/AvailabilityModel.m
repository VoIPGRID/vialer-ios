//
//  AvailabilityModel.m
//  Vialer
//
//  Created by Redmer Loen on 15-09-15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import "AvailabilityModel.h"

#import "VoIPGRIDRequestOperationManager.h"

NSString *const kAvailabilityDescription = @"availabilityDescription";
NSString *const kAvailabilityPhoneNumber = @"availabilityPhoneNumber";
NSString *const kAvailabilitySelected = @"availabilitySelected";
NSString *const KAvailabilityDestinationType = @"availabilityType";
NSString *const kAvailabilityId = @"availabilityId";

NSString static *const kFixedDestinations = @"fixeddestinations";
NSString static *const kPhoneaccounts = @"phoneaccounts";
NSString static *const kPhoneNumber = @"phonenumber";
NSString static *const kDescription = @"description";
NSString static *const kInternalNumber = @"internal_number";
NSString static *const kResourceUri = @"resource_uri";
NSString static *const kSelectedUserDestination = @"selecteduserdestination";
NSString static *const kSelectedUserDestinationPhoneaccount = @"phoneaccount";
NSString static *const kSelectedUserDestinationFixed = @"fixeddestination";
NSString static *const kSelectedUserDestinationId = @"id";

@interface AvailabilityModel()
@property (nonatomic, strong) NSString *availabilityDescription;
@property (nonatomic, strong) NSArray *availabilityOptions;
@property (nonatomic, strong) NSNumber *availabilityPhoneNumber;
@property (nonatomic, strong) NSString *availabilityResourceUri;
@property (nonatomic, strong) NSNumber *availabilitySelected;
@property (nonatomic, strong) NSString *availabilityString;
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
        self.availabilityString = NSLocalizedString(@"Not available", nil);
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
    NSNumber *phoneNumber = @0;

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
                    self.availabilityString = [NSString stringWithFormat: @"%@ / %@", phoneNumber, [userDestination objectForKey:kDescription]];
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
        self.availabilityString = [NSString stringWithFormat: @"%@ / %@", [selectedDict objectForKey:kAvailabilityPhoneNumber], [selectedDict objectForKey:kAvailabilityDescription]];
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

- (NSInteger)countAvailabilityOptions {
    return [self.availabilityOptions count];
}

- (NSString *)getFormattedAvailability {
    return self.availabilityString;
}

- (NSDictionary *)getAvailabilityAtIndex:(NSUInteger)index {
    return [self.availabilityOptions objectAtIndex:index];
}

@end
