//
//  Gossip+Extra.m
//  Vialer
//
//  Created by Reinier Wieringa on 26/12/14.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import "Gossip+Extra.h"

#import "PJSIP.h"

@implementation GSCall (Gossip_Extra)

@dynamic paused;

- (void)setPaused:(BOOL)paused {
    if (paused) {
        pjsua_call_set_hold(self.callId, NULL);
    } else {
        pjsua_call_reinvite(self.callId, PJ_TRUE, NULL);
    }
}

@end
