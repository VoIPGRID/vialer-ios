//
//  Gossip+Extra.h
//  Vialer
//
//  Created by Reinier Wieringa on 26/12/14.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import "Gossip.h"

@interface GSCall (Gossip_Extra)
@property (nonatomic, assign) BOOL paused;
@property (nonatomic, readonly) NSString *remoteInfo;
@property (nonatomic, readonly) NSTimeInterval callDuration;

+ (NSArray *)activeCalls;

- (void)startRinging;
- (void)stopRinging;

@end

@interface GSAccount (Gossip_Extra)

- (void)disconnect:(void (^)())finished;
+ (void)reregisterActiveAccounts;

@end

@interface GSUserAgent (Gossip_Extra)

- (BOOL)configure:(GSConfiguration *)config withRegistrationTimeOut:(NSUInteger)registrationTimeOut;

@end