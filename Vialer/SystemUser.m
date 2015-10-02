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
#import "AppDelegate.h"
#import "UIAlertView+Blocks.h"
#import <AVFoundation/AVAudioSession.h>

#define kMobileNumberKey    @"mobile_nr"
#define kSIPAccountKey      @"account_id"
#define kSIPPasswordKey     @"password"
#define kOutgoingNumberKey  @"outgoing_cli"
#define kEmailAddressKey    @"email"
#define kSIPAllowedKey      @"allow_app_account"
#define kAppAccount         @"app_account"

#define kUserSUD            @"User"
#define kSIPAccountSUD      @"SIPAccount"
#define kOutgoingNumberSUD  @"OutgoingCLI"
#define kMobileNumberSUD    @"MobileNumber"
#define kEmailAddressSUD    @"Email"
#define kSIPEnabledSUD      @"SipEnabled"
#define kSIPAllowedSUD      @"SIPAllowed"

// Constant for "suppressed" key as supplied by api for outgoingNumber
NSString * const kSuppressedKey = @"suppressed";

@interface SystemUser ()

@end

@implementation SystemUser {
    BOOL _loggedIn;
    BOOL _isSipAllowed;
    BOOL _sipEnabled;
}

@synthesize emailAddress = _emailAddress;

+ (instancetype)currentUser {
    static SystemUser *_currentUser = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _currentUser = [[SystemUser alloc] initPrivate];
    });

    return _currentUser;
}

+ (instancetype)initWithUserDict:(NSDictionary *)userDict withUsername:(NSString *)username andPassword:(NSString *)password {
    NSString *outgoingCli = [userDict objectForKey:kOutgoingNumberKey];
    if ([outgoingCli isKindOfClass:[NSString class]]) {
        [[NSUserDefaults standardUserDefaults] setObject:outgoingCli forKey:kOutgoingNumberSUD];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kOutgoingNumberSUD];
    }

    NSString *mobileNumber = [userDict objectForKey:kMobileNumberKey];
    if ([mobileNumber isKindOfClass:[NSString class]]) {
        [[NSUserDefaults standardUserDefaults] setObject:mobileNumber forKey:kMobileNumberSUD];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kMobileNumberSUD];
    }

    NSString *emailAddress = [userDict objectForKey:kEmailAddressKey];
    if ([emailAddress isKindOfClass:[NSString class]]) {
        [[NSUserDefaults standardUserDefaults] setObject:emailAddress forKey:kEmailAddressSUD];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kEmailAddressSUD];
    }

    // Store credentials
    [[NSUserDefaults standardUserDefaults] setObject:username forKey:kUserSUD];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [SSKeychain setPassword:password forService:[[self class] serviceName] account:username];

    return [[SystemUser alloc] initPrivate];
}

- (void)removeCurrentUser {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    _user = nil;
    _loggedIn = false;
    _sipAccount = nil;
    _outgoingNumber = nil;
    _mobileNumber = nil;
    _emailAddress = nil;
    _sipEnabled = false;
    _isSipAllowed = false;

    NSString *username = [defaults objectForKey:kUserSUD];

    [defaults removeObjectForKey:kUserSUD];
    [defaults removeObjectForKey:kSIPAccountSUD];
    [defaults removeObjectForKey:kOutgoingNumberSUD];
    [defaults removeObjectForKey:kEmailAddressSUD];
    [defaults removeObjectForKey:kMobileNumberSUD];
    [defaults removeObjectForKey:kSIPEnabledSUD];
    [defaults removeObjectForKey:kSIPAllowedSUD];
    [defaults synchronize];

    [SSKeychain deletePasswordForService:[[self class] serviceName] account:username];
}

// Override the init and throw an exception not allowing new instances
- (instancetype)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

// Private initialisation used to load the singleton
- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        [self reloadCurrentUser];
    }
    return self;
}

-(NSString *)emailAddress {
    if (_emailAddress) {
        return _emailAddress;
    } else if (self.user) {
        return self.user;
    }
    return NSLocalizedString(@"No email address configured", nil);
}

- (void)reloadCurrentUser {
    _user = [[NSUserDefaults standardUserDefaults] objectForKey:kUserSUD];
    // A user is considered logged in when its username is stored in the user defaults
    _loggedIn = (_user != nil);
    _sipAccount = [[NSUserDefaults standardUserDefaults] objectForKey:kSIPAccountSUD];
    _outgoingNumber = [[NSUserDefaults standardUserDefaults] objectForKey:kOutgoingNumberSUD];
    _mobileNumber = [[NSUserDefaults standardUserDefaults] objectForKey:kMobileNumberSUD];
    _emailAddress = [[NSUserDefaults standardUserDefaults] objectForKey:kEmailAddressSUD];
    _sipEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:kSIPEnabledSUD];
    _isSipAllowed = [[NSUserDefaults standardUserDefaults] boolForKey:kSIPAllowedSUD];
}

#pragma mark - Login specific handling

/** Quick check if a system user has logged in successfully */
- (BOOL)isLoggedIn {
    return _loggedIn;
}

/** Login with the specified user / password combination. The completion handler will be called with a boolean indicating if the loggin succeeded or not.
 @param user Username to use for the login (on success will be stored)
 @param password Passowrd to use for the login (on success is stored safely)
 @param completion Completion handled called when login was succesfull or failed.
 */
- (void)loginWithUser:(NSString *)user password:(NSString *)password completion:(void(^)(BOOL loggedin))completion {
    // Perform the login to VoIPGRID, in the future we would like to move more responsibility to the SystemUser class
    [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] loginWithUser:user password:password success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self reloadCurrentUser];
        // Check the reponse if this user is allowed to have an app_account
        if ([[responseObject objectForKey:kSIPAllowedKey] boolValue] ||
            [responseObject objectForKey:kSIPAllowedKey] == nil) {
            [self setAllowedToSip:YES];
            // Enabled SIP when allowed, or for development purpose disable if allow_app_account is not available.
            self.sipEnabled = [[responseObject objectForKey:kSIPAllowedKey] boolValue];

            // This user is allowed to use SIP, check if the account is configured
            NSString *appAccount = [responseObject objectForKey:kAppAccount];
            [self updateSIPAccountWithURL:appAccount andSuccess:^(BOOL success) {
                if (completion) {
                    completion(YES);
                }
            }];
        } else {
            // Not allowed to use SIP..
            [self setAllowedToSip:NO];
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

- (void)logout {
    [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] logout];
    // Clear the setting if SIP is allowed
    [self setAllowedToSip:NO];

    // Remove sip account if present also disconnects PJSIP and signals Middleware
    [self setSIPAccount:nil andPassword:nil];
}

#pragma mark -
#pragma mark Account information

- (NSString *)sipPassword {
    if (self.sipAccount) {
        return [SSKeychain passwordForService:[[self class] serviceName] account:self.sipAccount];
    }
    return nil;
}

/** Retrieve if the system user is allowed to have an app_account according to VoIPGRID */
- (BOOL)isAllowedToSip {
    return _isSipAllowed;
}

/** Private method to set the local information is sip is allowed for this system user.
 Stores this to the private member variable for retrieve via isAllowedToSip, and stored to user defaults.
 @param allowed Boolean indicating if SIP is allowed or not
 */
- (void)setAllowedToSip:(BOOL)allowed {
    _isSipAllowed = allowed;
    [[NSUserDefaults standardUserDefaults] setBool:allowed forKey:kSIPAllowedSUD];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

/** Check if the user has SIP currently enabled.
 @return Boolean indicating if enabled in the application, or not.
 */
- (BOOL)isSipEnabled {
    return self.isAllowedToSip && _sipEnabled;
}

/** User setting to enable/disable SIP support from the application.
 @param enabled Boolean value to set for Enabling / Disabling SIP.
 @see sipEnabled
 */
- (void)setSipEnabled:(BOOL)sipEnabled {
    if (_sipEnabled != sipEnabled) {
        _sipEnabled = sipEnabled;
        [[NSUserDefaults standardUserDefaults] setBool:sipEnabled forKey:kSIPEnabledSUD];
        [[NSUserDefaults standardUserDefaults] synchronize];

        [self updateSipAccountStatus:_sipEnabled];
    }
}

/** Retrieve a localized version of the outgoing number, this can match multiple translations if needed in the future
 but currently only serves, `suppressed` */
- (NSString *)localizedOutgoingNumber {
    if ([_outgoingNumber isEqualToString:kSuppressedKey]) {
        return NSLocalizedString(kSuppressedKey, @"Localized outgoing number, catching/translating suppressed");
    }
    return _outgoingNumber;
}

#pragma mark -
#pragma mark SIP Handling

/** Used to check / perform the initial SIP Status at startup of the app. */
- (void)checkSipStatus {
    [self updateSipAccountStatus:_sipEnabled];
}

/** Request to update the SIP Account information from the VoIPGRID Platform */
- (void)updateSIPAccountWithSuccess:(void (^)(BOOL success))completion {
    if (self.loggedIn &&
        self.sipEnabled) {
        // Update the user profile
        [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] userProfileWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            // This user is allowed to use SIP, check if the account is configured
            NSString *appAccount = [responseObject objectForKey:kAppAccount];
            [self updateSIPAccountWithURL:appAccount andSuccess:^(BOOL success) {
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
- (void)updateSIPAccountWithURL:(NSString *)accountUrl andSuccess:(void(^)(BOOL success))success {
    [self fetchSipAccountFromAppAccountURL:accountUrl withSuccess:^(NSString *sipUsername, NSString *sipPassword) {
        [self setSIPAccount:sipUsername andPassword:sipPassword];
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
- (void)fetchSipAccountFromAppAccountURL:(NSString *)appAccountURL withSuccess:(void (^)(NSString *sipUsername, NSString *sipPassword))success andFailure:(void(^)())failure {
    if ([appAccountURL isKindOfClass:[NSString class]]) {
        [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] retrievePhoneAccountForUrl:appAccountURL success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSObject *account = [responseObject objectForKey:kSIPAccountKey];
            NSObject *password = [responseObject objectForKey:kSIPPasswordKey];
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
- (void)setSIPAccount:(NSString *)sipUsername andPassword:(NSString *)sipPassword {
    if (sipUsername.length > 0) {
        // Did the SIP Account change?
        if ([sipUsername isEqualToString:_sipAccount]) {
            NSLog(@"Not updating UserDefaults with SIP Account because the supplied account was no different from the stored one");
        } else {
            _sipAccount = sipUsername;
            // We have a new SIP Account, store it
            [[NSUserDefaults standardUserDefaults] setObject:sipUsername forKey:kSIPAccountSUD];
            [SSKeychain setPassword:sipPassword forService:[[self class] serviceName] account:sipUsername];

            [self updateSipAccountStatus:_sipEnabled];
        }
    } else {
        NSLog(@"%s No SIP Account disconnecting and deleting", __PRETTY_FUNCTION__);
        [self updateSipAccountStatus:NO];

        // Now delete it from the user defaults
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSIPAccountSUD];
        [SSKeychain deletePasswordForService:[[self class] serviceName] account:_sipAccount error:NULL];
        _sipAccount = nil;
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

/** Private helper to switch the SIP Account status and trigger the correct methods */
- (void)updateSipAccountStatus:(BOOL)enabled {
    if (enabled) {
        [[ConnectionHandler sharedConnectionHandler] registerForPushNotifications];
        [[PZPushMiddleware sharedInstance] registerForVoIPNotifications];
        [[PZPushMiddleware sharedInstance] updateDeviceRecord];
        [[ConnectionHandler sharedConnectionHandler] sipConnect];
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
            if (!granted) {
                [UIAlertView showWithTitle:NSLocalizedString(@"Microphone Access Denied", nil)
                                   message:NSLocalizedString(@"You must allow microphone access in Settings > Privacy > Microphone.", nil)
                         cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                         otherButtonTitles:@[NSLocalizedString(@"Ok", nil)]
                                  tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                                      if (buttonIndex == 1 && UIApplicationOpenSettingsURLString != nil) {
                                          [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                                      }
                                  }];
            }
        }];

    } else {
        if (_sipAccount) {
            // First unregister the account with the middleware
            [[PZPushMiddleware sharedInstance] unregisterSipAccount:_sipAccount];
        }
        // And disconnect the Sip Connection Handler
        [[ConnectionHandler sharedConnectionHandler] sipDisconnect:nil];
    }
}

+ (NSString *)serviceName {
    return [[NSBundle mainBundle] bundleIdentifier];
}

@end
