//
//  SystemUser.m
//  Vialer
//
//  Created by Maarten de Zwart on 14/09/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import "SystemUser.h"
#import "VoIPGRIDRequestOperationManager.h"
#import "SSKeychain.h"  // Store the SipPassword safely
#import "PZPushMiddleware.h"
#import "ConnectionHandler.h"

@implementation SystemUser

#pragma mark - Login specific handling

/** Quick check if a system user has logged in successfully */
+ (BOOL)isLoggedIn {
    // A user is considered logged in when its username is stored in the user defaults
    NSString *user = [[NSUserDefaults standardUserDefaults] objectForKey:@"User"];
    return (user != nil);
}

/** Login with the specified user / password combination. The completion handler will be called with a boolean indicating if the loggin succeeded or not.
 @param user Username to use for the login (on success will be stored)
 @param password Passowrd to use for the login (on success is stored safely)
 @param completion Completion handled called when login was succesfull or failed.
 */
+ (void)loginWithUser:(NSString *)user password:(NSString *)password completion:(void(^)(BOOL loggedin))completion {
    // Perform the login to VoIPGRID, in the future we would like to move more responsibility to the SystemUser class
    [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] loginWithUser:user password:password success:^(AFHTTPRequestOperation *operation, id responseObject) {
        // Check the reponse if this user is allowed to have an app_account
//        if ([[responseObject objectForKey:@"allow_app_account"] boolValue]) {
        // For now always allow until available in the backend
        if (YES) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"allow_app_account"];
            [SystemUser enableSip:YES];
            
            // This user is allowed to use SIP, check if the account is configured
            NSString *app_account = [responseObject objectForKey:@"app_account"];
            [SystemUser updateSIPAccountWithURL:app_account andSuccess:^(BOOL success) {
                if (completion) {
                    completion(YES);
                }
            }];
        } else {
            // Not allowed to use SIP..
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"allow_app_account"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            if (completion) {
                completion(YES);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(NO);
        }
    }];
}

+ (void)logout {
    [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] logout];
    // Clear the setting if SIP is allowed
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"allow_app_account"];
    
    // Remove sip account if present also disconnects PJSIP and signals Middleware
    [SystemUser setSIPAccount:nil andPassword:nil];
}

#pragma mark -
#pragma mark Account information

+ (NSString *)user {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"User"];
}

+ (NSString *)outgoingNumber {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"OutgoingNumber"];
}
    
+ (NSString *)sipAccount {
    NSString *sipAccount = [[NSUserDefaults standardUserDefaults] objectForKey:@"SIPAccount"];
    return sipAccount;
}
    
+ (NSString *)sipPassword {
    NSString *sipAccount = [SystemUser sipAccount];
    if (sipAccount) {
        return [SSKeychain passwordForService:[[self class] serviceName] account:sipAccount];
    }
    return nil;
}

/** Retrieve if the system user is allowed to have an app_account according to VoIPGRID */
+ (BOOL)isAllowedToSip {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"allow_app_account"];
}

/** Check if the user has SIP currently enabled.
 @return Boolean indicating if enabled in the application, or not.
 */
+ (BOOL)isSipEnabled {
    return [SystemUser isAllowedToSip] && [[NSUserDefaults standardUserDefaults] boolForKey:@"sip_enabled"];
}

/** User setting to enable/disable SIP support from the application.
 @param enabled Boolean value to set for Enabling / Disabling SIP.
 @see isSipEnabled
 */
+ (void)enableSip:(BOOL)enabled {
    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:@"sip_enabled"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark -
#pragma mark SIP Handling

/** Request to update the SIP Account information from the VoIPGRID Platform */
+ (void)updateSIPAccountWithSuccess:(void (^)(BOOL success))completion {
    if ([SystemUser isLoggedIn] &&
        [SystemUser isSipEnabled]) {
        // Update the user profile
        [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] userProfileWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            // This user is allowed to use SIP, check if the account is configured
            NSString *app_account = [responseObject objectForKey:@"app_account"];
            [SystemUser updateSIPAccountWithURL:app_account andSuccess:^(BOOL success) {
                if (completion) {
                    completion(success);
                }
            }];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if (completion) {
                completion(NO);
            }
        }];
    }
}

/** Private helper to retrieve the SIP Account information from the supplied accountUrl */
+ (void)updateSIPAccountWithURL:(NSString *)accountUrl andSuccess:(void(^)(BOOL success))success {
    [SystemUser fetchSipAccountFromAppAccountURL:accountUrl withSuccess:^(NSString *sipUsername, NSString *sipPassword) {
        [SystemUser setSIPAccount:sipUsername andPassword:sipPassword];
        if (success) {
            success(YES);
        }
    } andFailure:^{
        if (success) {
            success(NO);
        }
    }];
}

/**
 * Given an URL to an App specific SIP account (phoneaccount) this function fetches and sets the SIP account details for use in the app if any, otherwise the SIP data is set to nil.
 * @param appAccountURL the URL from where to fetch the SIP account details e.g. /api/phoneaccount/basic/phoneaccount/XXXXX/
 */
+ (void)fetchSipAccountFromAppAccountURL:(NSString *)appAccountURL withSuccess:(void (^)(NSString *sipUsername, NSString *sipPassword))success andFailure:(void(^)())failure {
    if ([appAccountURL isKindOfClass:[NSString class]]) {
        [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] retrievePhoneAccountForUrl:appAccountURL success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSObject *account = [responseObject objectForKey:@"account_id"];
            NSObject *password = [responseObject objectForKey:@"password"];
            if ([account isKindOfClass:[NSNumber class]] && [password isKindOfClass:[NSString class]]) {
                if (success) success([(NSNumber *)account stringValue], (NSString *)password);
            } else {
                // No information about SIP account found, removed by user
                if (success) success(nil, nil);
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            // Failed to retrieve
            if (failure) {
                failure();
            }
        }];
    } else {
        // No URL supplied for Mobile app account, this means the user does not have the account set.
        // We are also going to unset it by calling success with but sipUsername and sipPassword set to nil
        if (success) success(nil, nil);
    }
}

/** Private helper to update the Sip Account information and possibly trigger a re-register to SIP */
+ (void)setSIPAccount:(NSString *)sipUsername andPassword:(NSString *)sipPassword {
    if (sipUsername.length > 0) {
        // Did the SIP Account change?
        if ([sipUsername isEqualToString:[SystemUser sipAccount]]) {
            NSLog(@"Not updating UserDefaults with SIP Account because the supplied account was no different from the stored one");
        } else {
            // We have a new SIP Account, store it
            [[NSUserDefaults standardUserDefaults] setObject:sipUsername forKey:@"SIPAccount"];
            [SSKeychain setPassword:sipPassword forService:[[self class] serviceName] account:sipUsername];
            
            [[PZPushMiddleware sharedInstance] updateDeviceRecord];
            [[ConnectionHandler sharedConnectionHandler] sipConnect];
        }
    } else {
        NSLog(@"%s No SIP Account disconnecting and deleting", __PRETTY_FUNCTION__);
        NSString *currentSipAccount = [SystemUser sipAccount];
        // First unregister the account with the middleware
        [[PZPushMiddleware sharedInstance] unregisterSipAccount:currentSipAccount];
        // Now delete it from the user defaults
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SIPAccount"];
        [SSKeychain deletePasswordForService:[[self class] serviceName] account:currentSipAccount error:NULL];
        // And disconnect the Sip Connection Handler
        [[ConnectionHandler sharedConnectionHandler] sipDisconnect:nil];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)serviceName {
    return [[NSBundle mainBundle] bundleIdentifier];
}

@end
