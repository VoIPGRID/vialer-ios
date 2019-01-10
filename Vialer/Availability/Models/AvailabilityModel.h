//
//  AvailabilityModel.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const AvailabilityModelSelected;

@interface AvailabilityModel : NSObject

@property(readonly, nonatomic) NSArray *availabilityOptions;

- (void)getUserDestinations:(void (^)(NSString *localizedErrorString))completion;

- (void)saveUserDestination:(NSUInteger)index withCompletion:(void (^)(NSString *localizedErrorString))completion;

/**
 Fetch the current Availabilty if unknown and store it. Makes sure it isn't fetched all the time.
 @param completionBlock the block that will be called with the availability or error if couldn't be fetched.
 */
- (void)getCurrentAvailabilityWithBlock:(void (^)(NSString *currentAvailability, NSString *localizedError))completionBlock;
@end
