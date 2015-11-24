//
//  Gossip+Extra.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "Gossip.h"
#import "GSDispatch.h"

@interface GSCall (Gossip_Extra)
@property (nonatomic, assign) BOOL paused;
@property (nonatomic, readonly) BOOL active;
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

- (BOOL)configure:(GSConfiguration *)config withEchoCancellation:(NSUInteger)echoCancellation;

@end

@interface GSDispatch (Gossip_Extra)

+ (void)configureCallbacksForAgent:(pjsua_config *)uaConfig;

@end