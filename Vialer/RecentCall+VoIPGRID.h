//
//  RecentCall+VoIPGRID.h
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import "RecentCall.h"

@interface RecentCall (VoIPGRID)

/**
 *  This method will parse the dictionary received from the VoIPGRID platform and will create RecentCalls from it.
 *
 *  If an existing RecentCall can be found with the given information, there will be no new RecentCall created.
 *
 *  @param responseData         Dictionary with the recent calls.
 *  @param managedObjectContext The managedObjectContext where to create the RecentCalls.
 *
 *  @return Array with created or found RecentCalls.
 */
+ (NSArray *)createRecentCallsFromVoIGPRIDResponseData:(NSDictionary *)responseData inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

/**
 *  This method will parse the directionary received from the VoIPGRID platform and will create a RecentCall from it.
 *
 *  If an existing RecentCall can be found with the given information, there will be no new RecentCall created.
 *
 *  @param dictionary           Dictionary with the recent call info.
 *  @param managedObjectContext The managedObjectContext where to create the RecentCall.
 *
 *  @return Created or found RecentCall.
 */
+ (RecentCall *)createRecentCallFromVoIPGRIDDictionary:(NSDictionary *)dictionary inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

/**
 *  This method will try to find a RecentCall given the callID.
 *
 *  @param callID               The ID of the call that needs to be found.
 *  @param managedObjectContext The managedObjectContext where to look in.
 *
 *  @return Found RecentCall or nil.
 */
+ (RecentCall *)findRecentCallByID:(NSNumber *)callID inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end
