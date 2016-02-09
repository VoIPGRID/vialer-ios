//
//  RecentCall.h
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface RecentCall : NSManagedObject

/**
 *  Will return a user friendly name to display.
 *
 *  This could be in this order:
 *  1. The callerName.
 *  2. The name that is parsed from the callerID.
 *  3. If the call is inbound the sourceNumber.
 *  4. If the call is outbound the destinationNumber.
 */
@property (readonly, nonatomic) NSString *displayName;

/**
 *  This method will fetch the latest call stored in the given managedObjectContext.
 *
 *  The calls will be sorted by date and the newest will be returned.
 *
 *  @param managedObjectContext Context that needs to be searched.
 *
 *  @return RecentCall instance or none if no call could have been found.
 */
+ (RecentCall *)latestCallInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end

NS_ASSUME_NONNULL_END

#import "RecentCall+CoreDataProperties.h"
