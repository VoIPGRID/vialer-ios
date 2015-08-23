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

@interface PZPushMiddleware ()
/**
 * @property pzMiddleware represents the API endpoint of the middleware.
 */
@property (nonatomic, strong)AFHTTPRequestOperationManager *pzMiddleware;
@property (nonatomic, strong)NSMutableArray *storedCallPayloadsToSent;
@end

@implementation PZPushMiddleware

+ (PZPushMiddleware *)sharedInstance {
    static dispatch_once_t pred;
    static PZPushMiddleware *_sharedInstance = nil;
    
    dispatch_once(&pred, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

- (AFHTTPRequestOperationManager *)pzMiddleware {
    if (!_pzMiddleware) {
        _pzMiddleware = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:self.baseLink]];
    }
    return _pzMiddleware;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pjConnectionStatusChangedNotification:) name:ConnectionStatusChangedNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ConnectionStatusChangedNotification object:nil];
}

- (void)pjConnectionStatusChangedNotification:(NSNotification *)notification {
    ConnectionHandler *handler = [notification object];

    if (handler.accountStatus == GSAccountStatusConnected)
        [self sentCallStoredPayloads];
}

- (void)sentCallStoredPayloads {
    if ([ConnectionHandler sharedConnectionHandler].accountStatus == GSAccountStatusConnected) {
        NSLog(@"%s GSAccountStatusConnected, sending #%d stored payload(s)", __PRETTY_FUNCTION__, [self.storedCallPayloadsToSent count]);
        //TODO:we probably want to implement a queue and lock the array but the change of multiple simultatious calls is quite small
        for (id storedPayload in self.storedCallPayloadsToSent)
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                // notify the PZ middleware that we registered, the PJSIP and are ready for calls using data from payload.
                [self updateMiddleWareWithData:storedPayload];
            });
        
        self.storedCallPayloadsToSent = nil;
    } else {
        NSLog(@"%s. PJSIP not connected, not sending stored Payloads!", __PRETTY_FUNCTION__);
    }
}


- (NSString*)baseLink {
    static NSString* baseLink;
    if (!baseLink) {
        NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"]];
        NSAssert(config != nil, @"Config.plist not found!");
        
        baseLink = [[config objectForKey:@"URLS"] objectForKey:@"Middelware BaseLink"];
        NSAssert(baseLink, @"URLS - Middelware BaseLink not found in Config.plist!");
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
* @param state the state of the application. Determines behaviour when receiving call (Background or not).
* @param payload data for presenting the notification to a user.
*/
- (void)handleReceivedNotificationForApplicationState:(UIApplicationState)state payload:(NSDictionary*)payload {
    NSString *type = payload[@"type"];
    if ([type isEqualToString:@"call"]) {
        // We only try to force a SIP reconnection when we don't have an active one.
        if ([ConnectionHandler sharedConnectionHandler].accountStatus != GSAccountStatusConnected) {
            [[ConnectionHandler sharedConnectionHandler] sipUpdateConnectionStatus];
        }
        
        //Check to see if we have a SIP connection, if so, update middleware directly, if not, store payload to sent when middleware becomes connected
        if ([ConnectionHandler sharedConnectionHandler].accountStatus == GSAccountStatusConnected) {
            NSLog(@"PJSIP connected with SIP Proxy, update middleware");
            [self updateMiddleWareWithData:payload];
        } else {
            //Store the payload so it can be sent when PJSIP becomes connected
            NSLog(@"PJSIP not connected, %s Storing Payload", __PRETTY_FUNCTION__);
            [self.storedCallPayloadsToSent addObject:payload];
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
    NSString *link = payload[@"response_api"];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *storedVoipToken = [defaults objectForKey:VOIP_TOKEN_STORAGE_KEY];
    [self.pzMiddleware POST:link parameters:@{@"token": storedVoipToken}  success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Device successfully checked in with Middleware");
            // TODO: notify user?
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            // TODO: notify user?
            NSLog(@"Unable to unregister device. Error:%@", [error localizedDescription]);
        }];
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
    
    NSLog(@"Updating middleware: %@ %@", link, uniqueKey);
    //sleep(40);
    if (link && uniqueKey) {
        [self.pzMiddleware POST:link parameters:@{@"unique_key" :uniqueKey} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"%s Success", __PRETTY_FUNCTION__); // TODO: should I tell the user something?
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error); //TODO: We should probably tell someone... ?
        }];
    } else {
        NSLog(@"Error! Did not get enough info to notify the middleware!");
    }
}

- (void)updateDeviceRecord {
    NSString* voipTokenString = [[NSUserDefaults standardUserDefaults] objectForKey:VOIP_TOKEN_STORAGE_KEY];
    NSString *sipAccount = [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] sipAccount];
    
    [self updateDeviceRecordForVoIPToken:voipTokenString sipAccount:sipAccount];
}

- (void)updateDeviceRecordForToken:(NSData*)token {
    NSString* voipTokenString = [[self class] deviceTokenStringFromData:token];
    NSString *sipAccount = [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] sipAccount];

    [self updateDeviceRecordForVoIPToken:voipTokenString sipAccount:sipAccount];
}

/**
* Register a token with the PZ middleware which can be used to notify this device of incoming calls, etc.
*
* @param token the NSData object containing a APNS registration token used by a backend.
*/
- (void)updateDeviceRecordForVoIPToken:(NSString *)voipTokenString sipAccount:(NSString *)sipAccount {
    NSLog(@"voip token: %@", voipTokenString);

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    //Only check for Sip Account and VoiP Token, rest is "nice to know" info
    if (sipAccount.length > 0 && voipTokenString.length > 0) {
        // update middleware with the token
        NSDictionary *infoDict = [NSBundle mainBundle].infoDictionary;
        NSDictionary *params = @{
            // Pretty name for a device in middleware.
            @"name": [[UIDevice currentDevice] name],
            // token used to send notifications to this device.
            @"token": voipTokenString,
            // user id used as primary key of the SIP account registered with the currently logged in user.
            @"sip_user_id": sipAccount,
            // The version of the OS of this phone. Useful when debugging possible issues in the future.
            @"os_version": [NSString stringWithFormat:@"iOS %@", [UIDevice currentDevice].systemVersion],
            // The version of this client app. Useful when debugging possible issues in the future.
            @"client_version": [NSString stringWithFormat:@"%@ (%@)", [infoDict objectForKey:@"CFBundleShortVersionString"], [infoDict objectForKey:@"CFBundleVersion"]]
        };

        void (^success)(AFHTTPRequestOperation*, id) = ^(AFHTTPRequestOperation *operation, id responseObject) {
            // store token locally to keep track of SIP to device mapping and prevent duplicate tokens in backend.
            [defaults setObject:voipTokenString forKey:VOIP_TOKEN_STORAGE_KEY];

            NSLog(@"Middleware Registration successfull!");    // TODO: we should probably tell someone...
        };
        void (^failure)(AFHTTPRequestOperation *, NSError *) = ^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Registration failed! -> %@", error);    // TODO: we should probably tell someone...
        };
        NSString *apiLink = [NSString stringWithFormat:@"%@/api/register-apns-device/", [self baseLink]];
        [[AFHTTPRequestOperationManager manager] POST:apiLink
                                           parameters:params
                                              success:success
                                              failure:failure];
    } else {
        NSLog(@"SipAccount(%@) or VoIPToken(%@) not provided unable to update middleware", sipAccount, voipTokenString);
    }
}

- (void)unregisterSipAccount:(NSString *)sipAccount {
    [self unregisterToken:[[NSUserDefaults standardUserDefaults] objectForKey:VOIP_TOKEN_STORAGE_KEY] andSipAccount:sipAccount];
}

- (void)unregisterToken:(NSString *)token andSipAccount:(NSString *)sipAccount {
    if (sipAccount.length > 0 && token.length > 0) {
        NSDictionary *params = @{@"token": token,
                                 @"sip_user_id": sipAccount };

        NSString *apiLink = @"/api/unregister-apns-device/";
        [self.pzMiddleware POST:apiLink parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Device was successfully unregistered");
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Unable to unregister device. Error:%@", [error localizedDescription]);
        }];
    } else {
        NSLog(@"Could not unregister, SipAccount(%@) or VoIPToken(%@) not provided", sipAccount, token);
    }
}

#pragma mark - token management
/**
* The app returns the NSData containing a APNS token.
*
* @param deviceToken NSData object to convert to hex string.
* @returns hexadecimal string containing APNS token.
*/
+ (NSString*) deviceTokenStringFromData:(NSData*)deviceToken {
    NSString* deviceTokenString = [[NSString alloc] initWithData:deviceToken encoding:NSASCIIStringEncoding];
    return [self _hexadecimalStringForString:deviceTokenString];
}

/**
* @param string data object to convert to hexadecimal format.
* @returns hexadecimal version of input string.
*/
+ (NSString*) _hexadecimalStringForString:(NSString*)string {
    NSMutableString* hexadecimalString = [[NSMutableString alloc] init];
    for(NSUInteger i = 0; i < [string length]; i++) {
        [hexadecimalString appendFormat:@"%02x", [string characterAtIndex:i]];
    }
    return hexadecimalString;
}

- (NSMutableArray *)storedCallPayloadsToSent {
    if (!_storedCallPayloadsToSent)
        _storedCallPayloadsToSent = [[NSMutableArray alloc] init];
    return _storedCallPayloadsToSent;
}

@end
