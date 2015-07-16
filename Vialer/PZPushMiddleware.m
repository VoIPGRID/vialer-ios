//
//  PZPushMiddleWare.m
//  Vialer
//
//  Created by Karsten Westra on 18/06/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import "PZPushMiddleware.h"
#import "AFHTTPRequestOperationManager.h"
#import "VoIPGRIDRequestOperationManager.h"

#import "ConnectionHandler.h"

#import <PushKit/PushKit.h>


#define VOIP_TOKEN_STORAGE_KEY @"VOIP-TOKEN"

@implementation PZPushMiddleware {
    AFHTTPRequestOperationManager *_manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _manager = [AFHTTPRequestOperationManager manager];
    }
    return self;
}

- (NSString*)baseLink {
    static NSString* baseLink;
    if (!baseLink) {
        NSLog(@"FETCHED FROM PLIST");
        NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"]];
        NSAssert(config != nil, @"Config.plist not found!");
        
        baseLink = [[config objectForKey:@"URLS"] objectForKey:@"Middelware BaseLink"];
        NSAssert(baseLink, @"URLS - Middelware BaseLink not found in Config.plist!");
    } else {
        NSLog(@"Using stored baseLink from PLIST");
    }
    return baseLink;
}

/**
 * Use PushKit to register for VoIP notifications from an external source. Handle the notification receival and registration in self.
 */
- (void)registerForVoIPNotifications {
    PKPushRegistry *voipRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
    voipRegistry.desiredPushTypes = [NSSet setWithArray:@[PKPushTypeVoIP]];
    voipRegistry.delegate = (AppDelegate<PKPushRegistryDelegate>*)[UIApplication sharedApplication].delegate;
}

/**
* Refresh the sip session and update the middleware that we are ready for incoming calls.
*
* @param payload data dictionary containing date to notify the middleware with.
*/
- (void)handleNotificationWithDictionary:(NSDictionary*)payload {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Connect tot the voys sip service.
        [[ConnectionHandler sharedConnectionHandler] sipUpdateConnectionStatus];
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // notify the PZ middleware that we registered and are ready for calls using data from payload.
        [self updateMiddleWareWithData:payload];
    });
}

/**
* @param state the state of the application. Determines behaviour when receiving call (Background or not).
* @param payload data for presenting the notification to a user.
*/
- (void)handleReceivedNotificationForApplicationState:(UIApplicationState)state payload:(NSDictionary*)payload {
    
    NSString *type = payload[@"type"];
    if ([type isEqualToString:@"call"]) {
        if(state == UIApplicationStateBackground) {
            // present a local notifcation to visually see when we are recieving a VoIP Notification.
            [self showLocalIncomingCallNotificationWithPayload:payload];
        } else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                // If the app is open: try and handle the notification
                [self handleNotificationWithDictionary:payload];
            });
        }
    } else if ([type isEqualToString:@"checkin"]) {
        [self doDeviceCheckinWithData:payload];
    } else if ([type isEqualToString:@"message"]) {
        NSString *message = payload[@"message"];
        if (state == UIApplicationStateBackground) {
            [self showLocalAlertMessage:message];
        } else {
            if (message) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                                    message:message
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                                          otherButtonTitles:nil];
                    [alert show];
                });
            }
        }
    }
}

/**
* Register your APNS token with the backend as SIP call ready.
*/
- (void)doDeviceCheckinWithData:(NSDictionary*)payload {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[ConnectionHandler sharedConnectionHandler] sipUpdateConnectionStatus];
    });

    NSString *link = payload[@"response_api"];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *storedVoipToken = [defaults objectForKey:VOIP_TOKEN_STORAGE_KEY];
    [_manager POST:link parameters:@{@"token": storedVoipToken}  success:^(AFHTTPRequestOperation *operation, id responseObject) {
        // TODO: notify user?
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // TODO: notify user?
    }];
}

/**
* Show a local to the user that we have an incoming caller and info about him/her.
*
* @param payload dictionary with a callerId and phonenumber to present to a user as the incoming caller.
*/
- (void)showLocalIncomingCallNotificationWithPayload:(NSDictionary*)payloadDict {
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    NSString *callerId = (payloadDict[@"caller_id"] ? payloadDict[@"caller_id"] : @"Unknown");
    localNotification.alertBody = [NSString stringWithFormat:@"Incoming call from %@", callerId];
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    localNotification.userInfo = @{@"type": @"call"};
    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
}

/**
* @param message a string to present as local notification to a user that his/her device
 is not registered anymore for incoming calls when app runs in background.
*/
- (void)showLocalAlertMessage:(NSString*)message {
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.alertBody = message;
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    localNotification.userInfo = @{@"type": @"message"};
    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
}

/**
 * Update a service link from payload with a unique key to register we are ready for incoming calls.
 *
 * @param data dictionary with payload from a notification with all necessary data.
 */
- (void)updateMiddleWareWithData:(NSDictionary*)data {
    NSString *link      = data[@"response_api"];
    NSString *uniqueKey = data[@"unique_key"];
    
    if (link && uniqueKey) {
        [_manager POST:link parameters:@{@"unique_key" :uniqueKey} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success"); // TODO: should I tell the user something?
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error); //TODO: We should probably tell someone... ?
        }];
    } else {
        NSLog(@"Error! Did not get enough info to notify the middleware!");
    }
}

/**
* Register a token with the PZ middleware which can be used to notify this device of incoming calls, etc.
*
* @param token the NSData object containing a APNS registration token used by a backend.
*/
- (void)registerToken:(NSData*)token {
    NSString* voipTokenString = [self _deviceTokenStringFromData:token];
    NSLog(@"voip token: %@", voipTokenString);

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *storedVoipToken = [defaults objectForKey:VOIP_TOKEN_STORAGE_KEY];

    if (storedVoipToken == nil || ![voipTokenString isEqualToString:storedVoipToken]) {
         // update middleware with the token
        NSDictionary *params = @{
            // Pretty name for a device in middleware.
            @"name": [[UIDevice currentDevice] name],
            // token used to send notifications to this device.
            @"token": voipTokenString,
            // user id used as primary key of the SIP account registered with the currently logged in user.
            @"sip_user_id": [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] sipAccount],
            // The version of the OS of this phone. Useful when debugging possible issues in the future.
            @"os_version": [NSString stringWithFormat:@"iOS %@", [UIDevice currentDevice].systemVersion],
            // The version of this client app. Useful when debugging possible issues in the future.
            @"client_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey]
        };

        void (^success)(AFHTTPRequestOperation*, id) = ^(AFHTTPRequestOperation *operation, id responseObject) {
            // store token locally to keep track of SIP to device mapping and prevent duplicate tokens in backend.
            [defaults setObject:voipTokenString forKey:VOIP_TOKEN_STORAGE_KEY];

            NSLog(@"Registration successfull!");    // TODO: we should probably tell someone...
        };
        void (^failure)(AFHTTPRequestOperation *, NSError *) = ^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Registration failed! -> %@", error);    // TODO: we should probably tell someone...
        };
        NSString *apiLink = [NSString stringWithFormat:@"%@/api/register-apns-device/", [self baseLink]];
        [[AFHTTPRequestOperationManager manager] POST:apiLink
                                           parameters:params
                                              success:success
                                              failure:failure];
    }
}

/**
* When a token is disabled or invalidated we should notify the middleware.
*
* Currently NOTIMPLEMENTED in middleware!
*/
- (void)unregisterToken:(NSData*)token {
    /* TODO */
}

#pragma mark - token management
/**
* The app returns the NSData containing a APNS token.
*
* @param deviceToken NSData object to convert to hex string.
* @returns hexadecimal string containing APNS token.
*/
- (NSString*) _deviceTokenStringFromData:(NSData*)deviceToken {
    NSString* deviceTokenString = [[NSString alloc] initWithData:deviceToken encoding:NSASCIIStringEncoding];
    return [self _hexadecimalStringForString:deviceTokenString];
}

/**
* @param string data object to convert to hexadecimal format.
* @returns hexadecimal version of input string.
*/
- (NSString*) _hexadecimalStringForString:(NSString*)string {
    NSMutableString* hexadecimalString = [[NSMutableString alloc] init];
    for(NSUInteger i = 0; i < [string length]; i++) {
        [hexadecimalString appendFormat:@"%02x", [string characterAtIndex:i]];
    }
    return hexadecimalString;
}

@end
