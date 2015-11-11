//
//  SystemUser.m
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import "SystemUser.h"

#import "AppDelegate.h"
#import "ConnectionHandler.h"
#import "LogInViewController.h"
#import "PZPushMiddleware.h"
#import "VoIPGRIDRequestOperationManager.h"

#import <AVFoundation/AVAudioSession.h>

#import "SSKeychain.h"

static NSString * const SystemUserMobileNumberKey = @"mobile_nr";
static NSString * const SystemUserSIPAccountKey = @"account_id";
static NSString * const SystemUserSIPPasswordKey = @"password";
static NSString * const SystemUserOutgoingNumberKey = @"outgoing_cli";
static NSString * const SystemUserEmailAddressKey = @"email";
static NSString * const SystemUserSIPAllowedKey = @"allow_app_account";
static NSString * const SystemUserAppAccount = @"app_account";
static NSString * const SystemUserFirstName = @"first_name";
static NSString * const SystemUserLastName = @"last_name";

static NSString * const SystemUserUserSUD = @"User";
static NSString * const SystemUserSIPAccountSUD = @"SIPAccount";
static NSString * const SystemUserOutgoingNumberSUD = @"OutgoingCLI";
static NSString * const SystemUserMobileNumberSUD = @"MobileNumber";
static NSString * const SystemUserEmailAddressSUD = @"Email";
static NSString * const SystemUserSIPEnabledSUD = @"SipEnabled";
static NSString * const SystemUserSIPAllowedSUD = @"SIPAllowed";
static NSString * const SystemUserFirstNameSUD = @"FirstName";
static NSString * const SystemUserLastNameSUD = @"LastName";

// Constant for "suppressed" key as supplied by api for outgoingNumber
static NSString * const SystemUserSuppressedKey = @"suppressed";

@interface SystemUser ()

@property (strong, nonatomic)NSString *user;
@property (strong, nonatomic)NSString *sipAccount;
@property (strong, nonatomic)NSString *mobileNumber;
@property (strong, nonatomic)NSString *emailAddress;
@property (strong, nonatomic)NSString *firstName;
@property (strong, nonatomic)NSString *lastName;

/** Quick check if a system user has logged in successfully */
@property (nonatomic)BOOL loggedIn;
/** Retrieve if the system user is allowed to have an app_account according to VoIPGRID */
@property (nonatomic)BOOL isSipAllowed;
@end

@implementation SystemUser
@synthesize sipEnabled = _sipEnabled;

+ (instancetype)currentUser {
    static SystemUser *_currentUser = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _currentUser = [[[self class] alloc] initPrivate];
    });
    return _currentUser;
}

- (void)setOwnPropertiesFromUserDict:(NSDictionary *)userDict withUsername:(NSString *)username andPassword:(NSString *)password {
    self.outgoingNumber = [userDict objectForKey:SystemUserOutgoingNumberKey];
    self.mobileNumber = [userDict objectForKey:SystemUserMobileNumberKey];
    self.firstName = [userDict objectForKey:SystemUserFirstName];
    self.lastName = [userDict objectForKey:SystemUserLastName];

    NSString *emailAddress = [userDict objectForKey:SystemUserEmailAddressKey];
    if ([emailAddress isKindOfClass:[NSString class]]) {
        [[self class] persistObject:emailAddress forKey:SystemUserEmailAddressSUD];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:SystemUserEmailAddressSUD];
    }

    // Store credentials
    [[self class] persistObject:username forKey:SystemUserUserSUD];
    [SSKeychain setPassword:password forService:[[self class] serviceName] account:username];
}

- (BOOL)isSipAllowed {
    return [[self class] readBoolForKey:SystemUserSIPAllowedSUD];
}

- (NSString *)emailAddress {
    return [[self class] readObjectForKey:SystemUserEmailAddressSUD];
}

- (NSString *)user {
    return [[self class] readObjectForKey:SystemUserUserSUD];
}
- (NSString *)sipAccount {
    return [[self class] readObjectForKey:SystemUserSIPAccountSUD];
}

- (BOOL)isLoggedIn {
    return self.user != nil;
}

- (void)removeCurrentUser {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    self.user = nil;
    self.loggedIn = false;
    self.sipAccount = nil;
    self.outgoingNumber = nil;
    self.mobileNumber = nil;
    self.emailAddress = nil;

    self.firstName = nil;
    self.lastName = nil;
    self.sipEnabled = false;
    self.isSipAllowed = false;

    NSString *username = [defaults objectForKey:SystemUserUserSUD];

    [defaults removeObjectForKey:SystemUserUserSUD];
    [defaults removeObjectForKey:SystemUserSIPAccountSUD];
    [defaults removeObjectForKey:SystemUserEmailAddressSUD];
    [defaults removeObjectForKey:SystemUserSIPEnabledSUD];
    [defaults removeObjectForKey:SystemUserSIPAllowedSUD];
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
    if (self = [super init]) {
    }
    return self;
}

-(NSString *)displayName {
    if (self.emailAddress) {
        return self.emailAddress;
    } else if (self.user) {
        return self.user;
    }
    return NSLocalizedString(@"No email address configured", nil);
}

#pragma mark - Login specific handling
/** Login with the specified user / password combination. The completion handler will be called with a boolean indicating if the login succeeded or not.
 @param user Username to use for the login (on success will be stored)
 @param password Passowrd to use for the login (on success is stored safely)
 @param completion Completion handled called when login was succesfull or failed.
 */
- (void)loginWithUser:(NSString *)user password:(NSString *)password completion:(void(^)(BOOL loggedin))completion {
    // Perform the login to VoIPGRID, in the future we would like to move more responsibility to the SystemUser class
    [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] loginWithUser:user password:password success:^(NSDictionary *responseData) {
        [self setOwnPropertiesFromUserDict:responseData withUsername:user andPassword:password];
        // Check the reponse if this user is allowed to have an app_account
        if ([[responseData objectForKey:SystemUserSIPAllowedKey] boolValue] ||
            [responseData objectForKey:SystemUserSIPAllowedKey] == nil) {
            [self setAllowedToSip:YES];
            // Enabled SIP when allowed, or for development purpose disable if allow_app_account is not available.
            self.sipEnabled = [[responseData objectForKey:SystemUserSIPAllowedKey] boolValue];

            // This user is allowed to use SIP, check if the account is configured
            NSString *appAccount = [responseData objectForKey:SystemUserAppAccount];
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
    } failure:^(NSError *error) {
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

    //Remove the Migration completed from system userdefaults.
    [[self class]persistObject:nil forKey:LoginViewControllerMigrationCompleted];
}

#pragma mark -
#pragma mark Account information

- (NSString *)sipPassword {
    if (self.sipAccount) {
        return [SSKeychain passwordForService:[[self class] serviceName] account:self.sipAccount];
    }
    return nil;
}

/** Private method to set the local information is sip is allowed for this system user.
 Stores this to the private member variable for retrieve via isAllowedToSip, and stored to user defaults.
 @param allowed Boolean indicating if SIP is allowed or not
 */
- (void)setAllowedToSip:(BOOL)allowed {
    _isSipAllowed = allowed;
    [[NSUserDefaults standardUserDefaults] setBool:allowed forKey:SystemUserSIPAllowedSUD];
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
        [[NSUserDefaults standardUserDefaults] setBool:sipEnabled forKey:SystemUserSIPEnabledSUD];
        [self updateSipAccountStatus:_sipEnabled];
    }
}

#pragma mark - SIP Handling
/** Used to check / perform the initial SIP Status at startup of the app. */
- (void)checkSipStatus {
    [self updateSipAccountStatus:self.sipEnabled];
}

/** Request to update the SIP Account information from the VoIPGRID Platform */
- (void)updateSIPAccountWithSuccess:(void (^)(BOOL success))completion {
    if (self.loggedIn && self.sipEnabled) {
        // Update the user profile
        [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] userProfileWithCompletion:^(id responseObject, NSError *error) {
            // This user is allowed to use SIP, check if the account is configured
            if  (!error) {
                NSString *appAccount = [responseObject objectForKey:SystemUserAppAccount];
                [self updateSIPAccountWithURL:appAccount andSuccess:^(BOOL success) {
                    if (completion) {
                        completion(success);
                    }
                }];
            } else {
                if (completion) {
                    completion(NO);
                }
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
            NSObject *account = [responseObject objectForKey:SystemUserSIPAccountKey];
            NSObject *password = [responseObject objectForKey:SystemUserSIPPasswordKey];
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
            [[self class] persistObject:sipUsername forKey:SystemUserSIPAccountSUD];
            [SSKeychain setPassword:sipPassword forService:[[self class] serviceName] account:sipUsername];

            [self updateSipAccountStatus:self.sipEnabled];
        }
    } else {
        NSLog(@"%s No SIP Account disconnecting and deleting", __PRETTY_FUNCTION__);
        [self updateSipAccountStatus:NO];

        // Now delete it from the user defaults
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:SystemUserSIPAccountSUD];
        [SSKeychain deletePasswordForService:[[self class] serviceName] account:_sipAccount error:NULL];
        _sipAccount = nil;
    }
}

/** Private helper to switch the SIP Account status and trigger the correct methods */
- (void)updateSipAccountStatus:(BOOL)enabled {
    if (enabled) {
        [[ConnectionHandler sharedConnectionHandler] registerForPushNotifications];
        [[PZPushMiddleware sharedInstance] registerForVoIPNotifications];
        [[PZPushMiddleware sharedInstance] updateDeviceRecord];
        [[ConnectionHandler sharedConnectionHandler] sipConnect];
    } else {
        if (self.sipAccount) {
            // First unregister the account with the middleware
            [[PZPushMiddleware sharedInstance] unregisterSipAccount:self.sipAccount];
        }
        // And disconnect the Sip Connection Handler
        [[ConnectionHandler sharedConnectionHandler] sipDisconnect:nil];
    }
}

#pragma mark - Properties
//For read/write property, if you override the getter and setter, the backing ivar is not automatically created.
//This is the behaviour I want here because I'm using the userdefaults as storage.
//If you still would like a backing ivar, you could declare it in the interface or use @synthesize ivar = _ivar.
//Possible return value's: a number, suppressed (localized) or nil.
- (NSString *)outgoingNumber {
    NSString *storedOutgoingNumber = [[self class] readObjectForKey:SystemUserOutgoingNumberSUD];

    if ([storedOutgoingNumber isEqualToString:SystemUserSuppressedKey]) {
        return NSLocalizedString(@"suppressed", @"Localized outgoing number, catching/translating suppressed");
    } else {
        return storedOutgoingNumber;
    }
}

- (void)setOutgoingNumber:(NSString *)outgoingNumber {
    if (![self.outgoingNumber isEqualToString:outgoingNumber]) {
        [[self class] persistObject:outgoingNumber forKey:SystemUserOutgoingNumberSUD];
    }
}

- (NSString *)mobileNumber {
    return [[self class] readObjectForKey:SystemUserMobileNumberSUD];
}

- (void)setMobileNumber:(NSString *)mobileNumber {
    if (![self.mobileNumber isEqualToString:mobileNumber]) {
        [[self class] persistObject:mobileNumber forKey:SystemUserMobileNumberSUD];
    }
}

- (NSString *)lastName {
    return [[self class] readObjectForKey:SystemUserLastNameSUD];
}

- (void)setLastName:(NSString *)lastName {
    if (![self.lastName isEqualToString:lastName]) {
        [[self class] persistObject:lastName forKey:SystemUserLastNameSUD];
    }
}

- (NSString *)firstName {
    return [[self class] readObjectForKey:SystemUserFirstNameSUD];
}

- (void)setFirstName:(NSString *)firstName {
    if (![self.firstName isEqualToString:firstName]) {
        [[self class] persistObject:firstName forKey:SystemUserFirstNameSUD];
    }
}

#pragma mark - API calls
- (void)updateSystemUserFromVGWithCompletion:(void (^)(NSError *error))completion {
    NSAssert(completion, @"A completion block must be specified.");
    [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] userProfileWithCompletion:^(id responseObject, NSError *error) {
        if (!error) {
            self.outgoingNumber = [responseObject objectForKey:SystemUserOutgoingNumberKey];
            self.mobileNumber = [responseObject objectForKey:SystemUserMobileNumberKey];
            self.firstName = [responseObject objectForKey:SystemUserFirstName];
            self.lastName = [responseObject objectForKey:SystemUserLastName];
            completion(nil);
        } else {
            completion(error);
        }
    }];
}

# pragma mark - Persisting data
/**
 This method is responsible for persisting the given object under the given key in the persistant store of choice.
 When we want to change the persistant store, these read/write should be the only in need of updating.

 @param object The object to persist
 @param key the onder which to store the given object
 */
+ (void)persistObject:(id)object forKey:(nonnull id)key {
    NSAssert(key, @"Key must be a valid object");
    if (object && ![object isKindOfClass:[NSNull class]]) {
        [[NSUserDefaults standardUserDefaults] setObject:object forKey:key];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    }
}

/**
 Returns an object persisted onder the given key

 @param key The key for which to find the desired object
 @return an object for the given key, nil, 0 or False
 */
+ (id)readObjectForKey:(nonnull id)key {
    return [[NSUserDefaults standardUserDefaults] objectForKey:key];
}
/*BOOL's are special*/
+ (BOOL)readBoolForKey:(nonnull id)key {
    return [[NSUserDefaults standardUserDefaults] boolForKey:key];
}

#pragma mark - Utility function
/**
 This function is userd by SSKeyChain so it can store variables under a "Service name"
 In this case, the bundle identifier of the app.

 @return The app's bundle identifier.
 */
+ (NSString *)serviceName {
    return [[NSBundle mainBundle] bundleIdentifier];
}

- (NSString *)debugDescription {
    NSMutableString *desc = [[NSMutableString alloc] initWithFormat:@"%@\n", [self description]];
    [desc appendFormat:@"\tUser: %@\n", self.user];
    [desc appendFormat:@"\tdisplayName: %@\n", self.displayName];
    [desc appendFormat:@"\toutgoingNumber: %@\n", self.outgoingNumber];
    [desc appendFormat:@"\tmobileNumber: %@\n", self.mobileNumber];
    [desc appendFormat:@"\tsipAccount: %@\n", self.sipAccount];
    [desc appendFormat:@"\tsipPassword: %@\n", self.sipPassword];
    [desc appendFormat:@"\tfirstName: %@\n", self.firstName];
    [desc appendFormat:@"\tlastName: %@\n", self.lastName];

    [desc appendFormat:@"\tisAllowedToSip: %@\n", self.isAllowedToSip ? @"YES" : @"NO"];
    [desc appendFormat:@"\tsipEnabled: %@\n", self.sipEnabled ? @"YES" : @"NO"];
    [desc appendFormat:@"\tloggedIn: %@", self.loggedIn ? @"YES" : @"NO"];
    
    return desc;
}

@end
