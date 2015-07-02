//
//  Gossip+Extra.m
//  Vialer
//
//  Created by Reinier Wieringa on 26/12/14.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import "Gossip+Extra.h"
#import "ConnectionHandler.h"

#import "GSPJUtil.h"
#import "PJSIP.h"
#import "GSNotifications.h"
#import "GSDispatch.h"
#import "Util.h"

#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

/*
 * GSCall
 */

@implementation GSCall (Gossip_Extra)

static NSTimer *ringTimer = nil;
static SystemSoundID ringSoundId;

- (void)setPaused:(BOOL)paused {
    if (paused) {
        pjsua_call_set_hold(self.callId, NULL);
    } else {
        pjsua_call_reinvite(self.callId, PJ_TRUE, NULL);
    }
}

- (BOOL)paused {
    pjsua_call_info callInfo;
    pjsua_call_get_info(self.callId, &callInfo);
    return (callInfo.media_status == PJSUA_CALL_MEDIA_LOCAL_HOLD) || (callInfo.media_status == PJSUA_CALL_MEDIA_REMOTE_HOLD);
}

- (BOOL)active {
    // NOTE: Hack to receive the new call status when the other line has ended the call, otherwise we're not notified
    GSLogIfFails(pjsua_call_update(self.callId,  PJSUA_CALL_UPDATE_CONTACT, NULL));

    return pjsua_call_is_active(self.callId) != 0;
}

- (NSTimeInterval)callDuration {
    pjsua_call_info callInfo;
    pjsua_call_get_info(self.callId, &callInfo);

    return ((NSTimeInterval)PJ_TIME_VAL_MSEC(callInfo.total_duration)) / 1000.f;
}

- (NSString *)remoteInfo {
    pjsua_call_info callInfo;
    pjsua_call_get_info(self.callId, &callInfo);

    NSString *remoteInfo = [[GSPJUtil stringWithPJString:&callInfo.remote_info] copy];
    NSRange range = [remoteInfo rangeOfString:@"\"" options:NSBackwardsSearch];
    if (range.location != NSNotFound) {
        remoteInfo = [remoteInfo substringToIndex:range.location];
    }
    return [remoteInfo stringByReplacingOccurrencesOfString:@"\"" withString:@""];
}

+ (NSArray *)activeCalls {
    NSMutableArray *activeCalls = [NSMutableArray array];

    unsigned callCount = pjsua_call_get_count();
    if (callCount) {
        pjsua_call_id callIds[callCount];
        pjsua_enum_calls(callIds, &callCount);

        GSAccount *account = [GSUserAgent sharedAgent].account;
        for (unsigned i = 0; i < callCount; i++) {
            [activeCalls addObject:[GSCall incomingCallWithId:callIds[i] toAccount:account]];
        }
    }

    return activeCalls;
}

- (void)startRinging {
    if (ringTimer) {
        return;
    }

    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:NULL];

    NSString *filename = [[NSBundle mainBundle] pathForResource:@"incoming" ofType:@"wav"];
    OSStatus error = AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL URLWithString:filename], &ringSoundId);
    if (error == kAudioServicesNoError) {
        ringTimer = [NSTimer timerWithTimeInterval:3.f target:self selector:@selector(ringTimerInterval:) userInfo:@(ringSoundId) repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:ringTimer forMode:NSDefaultRunLoopMode];
        [ringTimer fire];
    }
}

- (void)stopRinging {
    if (ringTimer) {
        [ringTimer invalidate];
        ringTimer = nil;
        AudioServicesDisposeSystemSoundID(ringSoundId);
    }
}

- (void)ringTimerInterval:(NSTimer *)timer {
    AudioServicesPlayAlertSound(ringSoundId);
}

@end

/*
 * GSAccount
 */

typedef void (^disconnectFinishedBlock)();

static pj_thread_desc a_thread_desc;
static pj_thread_t *a_thread;

@implementation GSAccount (Gossip_Extra)

- (void)disconnect:(void (^)())finished {
    if (self.status == GSAccountStatusConnected) {
        [self addObserver:self
               forKeyPath:@"status"
                  options:NSKeyValueObservingOptionInitial
                  context:(void *)CFBridgingRetain(finished)];
        [self disconnect];
    } else if (finished) {
        finished();
    }
}

+ (void)reregisterActiveAccounts {
    if (!pj_thread_is_registered()) {
        pj_thread_register("ipjsua", a_thread_desc, &a_thread);
    }

    for (int i = 0; i < (int)pjsua_acc_get_count(); ++i) {
        NSLog(@"Keep account %d alive", i);
        if (pjsua_acc_is_valid(i)) {
            pjsua_acc_set_registration(i, PJ_TRUE);
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:@"status"]) {
        if (self.status == GSAccountStatusOffline) {
            disconnectFinishedBlock finished = (__bridge disconnectFinishedBlock)(context);
            if (finished) {
                double delayInSeconds = 1.0;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    finished();
                });
            }
            [self removeObserver:self forKeyPath:@"status"];
        }
    }
}

@end

/*
 * GSUserAgent
 */

@implementation GSUserAgent (Gossip_Extra)

- (BOOL)configure:(GSConfiguration *)config withEchoCancellation:(NSUInteger)echoCancellation {
    if ([self configure:config]) {
        GSLogIfFails(pjsua_set_ec((unsigned int)echoCancellation, 100));
    }

    return YES;
}

@end

/*
 * GSDispatch
 */

void onRegistrationStarted(pjsua_acc_id accountId, pj_bool_t renew);
void onRegistrationState(pjsua_acc_id accountId);
void onIncomingCall(pjsua_acc_id accountId, pjsua_call_id callId, pjsip_rx_data *rdata);
void onCallMediaState(pjsua_call_id callId);
void onCallState(pjsua_call_id callId, pjsip_event *e);

@implementation GSDispatch (Gossip_Extra)

+ (void)configureCallbacksForAgent:(pjsua_config *)uaConfig {
    // NOTE: Override original GSDispatch hook for incoming call that was set in the primary class
    uaConfig->cb.on_reg_started = &onRegistrationStarted;
    uaConfig->cb.on_reg_state = &onRegistrationState;
    uaConfig->cb.on_incoming_call = &onIncomingCallOverride;
    uaConfig->cb.on_call_media_state = &onCallMediaState;
    uaConfig->cb.on_call_state = &onCallState;

    // Set our user agent
    NSString *userAgent = [NSString stringWithFormat:@"%@/%@ (%@; iOS %@; Scale/%0.2f)", [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleExecutableKey] ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleIdentifierKey], (__bridge id)CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey) ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleVersionKey], [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion], ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] ? [[UIScreen mainScreen] scale] : 1.0f)];
    uaConfig->user_agent = [GSPJUtil PJStringWithString:userAgent];
}

void onIncomingCallOverride(pjsua_acc_id accountId, pjsua_call_id callId, pjsip_rx_data *rdata) {
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
        onIncomingCall(accountId, callId, rdata);
    } else {
        [ConnectionHandler showLocalNotificationForIncomingCall:[GSCall incomingCallWithId:callId toAccount:[GSUserAgent sharedAgent].account]];
    }
}

@end
