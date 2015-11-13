//
//  ReachabilityManager.h
//  Vialer
//
//  Created by Bob Voorneveld on 10/11/15.
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, ReachabilityManagerStatusType) {
    ReachabilityManagerStatusOffline,
    ReachabilityManagerStatusTwoStep,
    ReachabilityManagerStatusSIP,
};

@interface ReachabilityManager : NSObject

@property (nonatomic) ReachabilityManagerStatusType status;

- (void)startMonitoring;
- (void)stopMonitoring;

@end
