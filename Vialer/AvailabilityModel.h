//
//  AvailabilityModel.h
//  Vialer
//
//  Created by Redmer Loen on 15-09-15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const kAvailabilityDescription;
extern NSString *const kAvailabilityPhoneNumber;
extern NSString *const kAvailabilitySelected;
extern NSString *const KAvailabilityDestinationType;

@interface AvailabilityModel : NSObject

- (void)getUserDestinations:(void (^)(NSString *localizedErrorString))completion;
- (void)saveUserDestination:(NSUInteger) index withCompletion:(void (^)(NSString *localizedErrorString))completion;
- (NSInteger)countAvailabilityOptions;
- (NSString *)getFormattedAvailability;
- (NSDictionary *)getAvailabilityAtIndex:(NSUInteger)index;
@end
