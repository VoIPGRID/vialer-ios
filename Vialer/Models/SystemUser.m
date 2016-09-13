//
//  SystemUser.m
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import "SystemUser.h"

@import AVFoundation;
#import "Configuration.h"
#import "NSString+SubString.h"
#import "SAMKeychain.h"
#import "VoIPGRIDRequestOperationManager.h"


NSString * const SystemUserErrorDomain = @"Vialer.Systemuser";

NSString * const SystemUserLoginNotification                = @"SystemUserLoginNotification";
NSString * const SystemUserLogoutNotification               = @"SystemUserLogoutNotification";
NSString * const SystemUserLogoutNotificationDisplayNameKey = @"SystemUserLogoutNotificationDisplayNameKey";
NSString * const SystemUserLogoutNotificationErrorKey       = @"SystemUserLogoutNotificationErrorKey";

NSString * const SystemUserSIPCredentialsChangedNotification = @"SystemUserSIPCredentialsChangedNotification";
NSString * const SystemUserSIPDisabledNotification           = @"SystemUserSIPDisabledNotification";

NSString * const SystemUserOutgoingNumberUpdatedNotification = @"SystemUserOutgoingNumberUpdatedNotification";

/**
 *  Api Dictionary keys.
 *
 *  These keys can be used to get the information from the dictionary received from the VoIPGRID platform.
 */
static NSString * const SystemUserApiKeyClient          = @"client";
static NSString * const SystemUserApiKeyPartner         = @"partner";
static NSString * const SystemUserApiKeyMobileNumber    = @"mobile_nr";
static NSString * const SystemUserApiKeyOutgoingNumber  = @"outgoing_cli";
static NSString * const SystemUserApiKeyEmailAddress    = @"email";
static NSString * const SystemUserApiKeyFirstName       = @"first_name";
static NSString * const SystemUserApiKeyPreposition     = @"preposition";
static NSString * const SystemUserApiKeyLastName        = @"last_name";
static NSString * const SystemUserApiKeyAppAccountURL   = @"app_account";
static NSString * const SystemUserApiKeySIPAccount      = @"account_id";
static NSString * const SystemUserApiKeySIPPassword     = @"password";

// Constant for "suppressed" key as supplied by api for outgoingNumber
static NSString * const SystemUserSuppressedKey = @"suppressed";

/**
 *  NSUserDefault keys.
 *
 *  These keys are used to store and retrieve information in the NSUserDefaults.
 */
static NSString * const SystemUserSUDUsername           = @"User";
static NSString * const SystemUserSUDOutgoingNumber     = @"OutgoingCLI";
static NSString * const SystemUserSUDMobileNumber       = @"MobileNumber";
static NSString * const SystemUserSUDEmailAddress       = @"Email";
static NSString * const SystemUserSUDFirstName          = @"FirstName";
static NSString * const SystemUserSUDPreposition        = @"Preposition";
static NSString * const SystemUserSUDLastName           = @"LastName";
static NSString * const SystemUserSUDClientID           = @"ClientID";
static NSString * const SystemUserSUDSIPAccount         = @"SIPAccount";
static NSString * const SystemUserSUDSIPEnabled         = @"SipEnabled";
static NSString * const SystemUserSUDMigrationCompleted = @"v2.0_MigrationComplete";


@interface SystemUser ()
@property (nonatomic) BOOL loggedIn;

/**
 *  User properties.
 */
@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSString *outgoingNumber;
@property (strong, nonatomic) NSString *mobileNumber;
@property (strong, nonatomic) NSString *emailAddress;
@property (strong, nonatomic) NSString *firstName;
@property (strong, nonatomic) NSString *preposition;
@property (strong, nonatomic) NSString *lastName;
@property (strong, nonatomic) NSString *clientID;

/**
 *  This boolean will keep track if the migration from app version 1.x to 2.x already happend.
 */
@property (readwrite, nonatomic) BOOL migrationCompleted;

/**
 *  SIP Properties
 */
@property (strong, nonatomic) NSString *sipAccount;
@property (readwrite, nonatomic) BOOL sipRegisterOnAdd;

/**
 *  Depenpency Injection.
 */
@property (strong, nonatomic) VoIPGRIDRequestOperationManager *operationsManager;

/**
 *  This value is used to store and retrieve keys from the Keychain.
 */
@property (strong, nonatomic) NSString *serviceName;
@end

@implementation SystemUser

#pragma mark - Life cycle

+ (instancetype)currentUser {
    static SystemUser *_currentUser = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _currentUser = [[[self class] alloc] initPrivate];
    });
    return _currentUser;
}

/**
 *  Override the init and throw an exception not allowing new instances.
 */
- (instancetype)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

/**
 *  Private initialisation used to load the singleton.
 */
- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        [self readPropertyValuesFromUserDefaults];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authorizationFailedNotification:) name:VoIPGRIDRequestOperationManagerUnAuthorizedNotification object:nil];
        self.sipRegisterOnAdd = YES;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)readPropertyValuesFromUserDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    /**
     *  User settings.
     */
    self.username           = [defaults objectForKey:SystemUserSUDUsername];
    self.outgoingNumber     = [defaults objectForKey:SystemUserSUDOutgoingNumber];
    self.mobileNumber       = [defaults objectForKey:SystemUserSUDMobileNumber];
    self.emailAddress       = [defaults objectForKey:SystemUserSUDEmailAddress];
    self.firstName          = [defaults objectForKey:SystemUserSUDFirstName];
    self.preposition        = [defaults objectForKey:SystemUserSUDPreposition];
    self.lastName           = [defaults objectForKey:SystemUserSUDLastName];
    self.clientID           = [defaults objectForKey:SystemUserSUDClientID];
    self.migrationCompleted = [defaults boolForKey:SystemUserSUDMigrationCompleted];

    /**
     *  If there is a username, the user is supposed to be logged in.
     *
     *  Warning, this is not a check on the server if the user still has proper credentials.
     */
    self.loggedIn = self.username != nil;

    /**
     *  SIP settings.
     */
    self.sipAccount     = [defaults objectForKey:SystemUserSUDSIPAccount];
    self.sipEnabled     = [defaults boolForKey:SystemUserSUDSIPEnabled];
}

#pragma mark - Properties

- (VoIPGRIDRequestOperationManager *)operationsManager {
    if (!_operationsManager) {
        _operationsManager = [[VoIPGRIDRequestOperationManager alloc] initWithDefaultBaseURL];
    }
    return _operationsManager;
}

- (NSString *)displayName {
    if (self.firstName || self.lastName) {
        NSString *lastName = [[NSString stringWithFormat:@"%@ %@", self.preposition ?: @"", self.lastName ?: @""] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        return [[NSString stringWithFormat:@"%@ %@", self.firstName ?: @"", lastName] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    } else if (self.emailAddress) {
        return self.emailAddress;
    } else if (self.username) {
        return self.username;
    }
    return NSLocalizedString(@"No email address configured", nil);
}

- (void)setSipEnabled:(BOOL)sipEnabled {
    NSString *stringFromSipEnabledProperty = NSStringFromSelector(@selector(sipEnabled));
    // If sip is being enabled, check if there is an sipAccount and fire notification.
    if (sipEnabled && !_sipEnabled && self.sipAccount) {
        [self willChangeValueForKey:stringFromSipEnabledProperty];
        _sipEnabled = YES;
        [self didChangeValueForKey:stringFromSipEnabledProperty];

        // Post the notification async. Do not use NSNotificationQueue because when the app starts
        // the app delegate does not pickup on the notification when posted using the NSNotificationQueue.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:SystemUserSIPCredentialsChangedNotification object:self];
        });

        // If sip is being disabled, fire a notification.
    } else if (!sipEnabled && _sipEnabled) {
        [self willChangeValueForKey:stringFromSipEnabledProperty];
        _sipEnabled = NO;
        [self didChangeValueForKey:stringFromSipEnabledProperty];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:SystemUserSIPDisabledNotification object:[self.sipAccount copy]];
            [self fetchUserProfile];
        });
    }
    [[NSUserDefaults standardUserDefaults] setBool:_sipEnabled forKey:SystemUserSUDSIPEnabled];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)sipPassword {
    if (self.sipAccount) {
        return [SAMKeychain passwordForService:self.serviceName account:self.sipAccount];
    }
    return nil;
}

- (NSString *)password {
    if (self.username) {
        return [SAMKeychain passwordForService:self.serviceName account:self.username];
    }
    return nil;
}

- (NSString *)sipDomain {
    return [[Configuration defaultConfiguration] UrlForKey:ConfigurationSIPDomain];
}

- (NSString *)sipProxy {
    return self.sipDomain;
}

- (NSString *)serviceName {
    return [[NSBundle mainBundle] bundleIdentifier];
}

- (void)setMobileNumber:(NSString *)mobileNumber {
    _mobileNumber = mobileNumber;
    if (mobileNumber) {
        [[NSUserDefaults standardUserDefaults] setObject:mobileNumber forKey:SystemUserSUDMobileNumber];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:SystemUserSUDMobileNumber];
    }
}

- (void)setOutgoingNumber:(NSString *)outgoingNumber {
    if (outgoingNumber != _outgoingNumber) {
        _outgoingNumber = outgoingNumber;
        [[NSUserDefaults standardUserDefaults] setObject:outgoingNumber forKey:SystemUserSUDOutgoingNumber];
        [[NSNotificationCenter defaultCenter] postNotificationName:SystemUserOutgoingNumberUpdatedNotification object:self];
    }
}

- (void)setMigrationCompleted:(BOOL)migrationCompleted {
    _migrationCompleted = migrationCompleted;
    [[NSUserDefaults standardUserDefaults] setBool:migrationCompleted forKey:SystemUserSUDMigrationCompleted];
}

- (void)setSipAccount:(NSString *)sipAccount {
    /**
     *  Remove the password from the old sipAccount if the sipAccount has changed.
     */
    if (_sipAccount && _sipAccount != sipAccount) {
        [SAMKeychain deletePasswordForService:self.serviceName account:_sipAccount];
    }
    _sipAccount = sipAccount;
    [[NSUserDefaults standardUserDefaults] setObject:_sipAccount forKey:SystemUserSUDSIPAccount];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setClientID:(NSString *)clientID {
    NSString *newClientID = [self parseStringForClientID:clientID];
    NSString *stringFromClientIDProperty = NSStringFromSelector(@selector(clientID));

    if (_clientID != newClientID && ![_clientID isEqualToString:newClientID]) {
        [self willChangeValueForKey:stringFromClientIDProperty];
        _clientID = newClientID;
        [self didChangeValueForKey:stringFromClientIDProperty];
    }
}

#pragma mark - Actions

- (void)loginWithUsername:(NSString *)username password:(NSString *)password completion:(void(^)(BOOL loggedin, NSError *error))completion {
    [self.operationsManager loginWithUsername:username password:password withCompletion:^(NSDictionary *responseData, NSError *error) {
        /**
         *  Login failed.
         */
        if (error) {
            [self removeCurrentUser];
            if (completion) {
                NSDictionary *userInfo = @{NSUnderlyingErrorKey: error};
                completion(NO, [NSError errorWithDomain:SystemUserErrorDomain code:SystemUserErrorLoginFailed userInfo:userInfo]);
            }
            return;
        }

        /**
         *  Check if the user is a Client or a Partner user.
         */
        NSString *client = [responseData objectForKey:SystemUserApiKeyClient];
        NSString *partner = [responseData objectForKey:SystemUserApiKeyPartner];
        // Client should be valid, and partner should not be present.
        BOOL clientValid = client && ![client isKindOfClass:[NSNull class]];
        BOOL partnerValid = partner && ![partner isKindOfClass:[NSNull class]];
        if (!clientValid || partnerValid) {
            // This is a partner or superuser account, don't log in!
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : NSLocalizedString(@"user type not allowed", nil)};
            completion(NO, [NSError errorWithDomain:SystemUserErrorDomain code:SystemUserErrorUserTypeNotAllowed userInfo:userInfo]);
            return;
        }

        [self setOwnPropertiesFromUserDict:responseData withUsername:username andPassword:password];
        [self updateSystemUserFromVGWithCompletion:^(NSError *error) {
            if (completion) {
                if (!error) {
                    completion(YES, nil);
                } else {
                    completion(NO, error);
                }
            }
        }];
        [[NSNotificationCenter defaultCenter] postNotificationName:SystemUserLoginNotification object:self];
    }];
}

- (void)logout {
    [self logoutWithUserInfo:nil];
}

- (void)logoutWithUserInfo:(NSDictionary *)userInfo {
    [self removeCurrentUser];
    [[NSNotificationCenter defaultCenter] postNotificationName:SystemUserLogoutNotification object:self userInfo:userInfo];
}

- (void)removeCurrentUser {
    [SAMKeychain deletePasswordForService:self.serviceName account:self.username];

    self.loggedIn = NO;
    self.username = nil;
    self.outgoingNumber = nil;
    self.mobileNumber = nil;
    self.emailAddress = nil;
    self.firstName = nil;
    self.preposition = nil;
    self.lastName = nil;
    self.clientID = nil;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:SystemUserSUDUsername];
    [defaults removeObjectForKey:SystemUserSUDOutgoingNumber];
    [defaults removeObjectForKey:SystemUserSUDMobileNumber];
    [defaults removeObjectForKey:SystemUserSUDEmailAddress];
    [defaults removeObjectForKey:SystemUserSUDFirstName];
    [defaults removeObjectForKey:SystemUserSUDPreposition];
    [defaults removeObjectForKey:SystemUserSUDLastName];
    [defaults removeObjectForKey:SystemUserApiKeyClient];

    [self removeSIPCredentials];

    [defaults removeObjectForKey:SystemUserSUDSIPAccount];
    [defaults synchronize];
}

- (void)removeSIPCredentials {
    [SAMKeychain deletePasswordForService:self.serviceName account:self.sipAccount];
    self.sipEnabled = NO;
    self.sipAccount = nil;

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:SystemUserSUDSIPAccount];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:SystemUserSUDSIPEnabled];
}

- (void)setOwnPropertiesFromUserDict:(NSDictionary *)userDict withUsername:(NSString *)username andPassword:(NSString *)password {
    if (username && password) {
        self.username = username;
        [SAMKeychain setPassword:password forService:self.serviceName account:username];
    }
    self.outgoingNumber = userDict[SystemUserApiKeyOutgoingNumber];
    if (![userDict[SystemUserApiKeyMobileNumber] isEqual:[NSNull null]]) {
        self.mobileNumber   = userDict[SystemUserApiKeyMobileNumber];
    }
    self.emailAddress   = userDict[SystemUserApiKeyEmailAddress];
    self.firstName      = userDict[SystemUserApiKeyFirstName];
    self.preposition    = userDict[SystemUserApiKeyPreposition];
    self.lastName       = userDict[SystemUserApiKeyLastName];
    self.clientID       = userDict[SystemUserApiKeyClient];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // If the defaults contains a value for SIP Enabled, use that value,
    if ([defaults objectForKey:SystemUserSUDSIPEnabled]) {
        self.sipEnabled = [defaults boolForKey:SystemUserSUDSIPEnabled];
    } else {
        // else set to YES which will try to enable SIP for this user.
        self.sipEnabled = YES;
    }

    [defaults setObject:self.username forKey:SystemUserSUDUsername];
    [defaults setObject:self.outgoingNumber forKey:SystemUserSUDOutgoingNumber];
    [defaults setObject:self.mobileNumber forKey:SystemUserSUDMobileNumber];
    [defaults setObject:self.emailAddress forKey:SystemUserSUDEmailAddress];
    [defaults setObject:self.firstName forKey:SystemUserSUDFirstName];
    [defaults setObject:self.preposition forKey:SystemUserSUDPreposition];
    [defaults setObject:self.lastName forKey:SystemUserSUDLastName];
    [defaults setObject:self.clientID forKey:SystemUserApiKeyClient];

    [defaults synchronize];
    self.loggedIn = YES;
}

- (void)fetchUserProfile {
    [self.operationsManager userProfileWithCompletion:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject, NSError *error) {
        if (!error) {
            self.outgoingNumber = responseObject[SystemUserApiKeyOutgoingNumber];
        }
    }];
}

- (void)updateMobileNumber:(NSString *)mobileNumber withCompletion:(void(^)(BOOL success, NSError *error))completion {
    if (!mobileNumber.length) {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: NSLocalizedString(@"The number is to short", nil)};
        completion(NO, [NSError errorWithDomain:SystemUserErrorDomain code:SystemUserErrorMobileNumberToShort userInfo:userInfo]);
        return;
    }

    // Strip whitespaces.
    mobileNumber = [mobileNumber stringByReplacingOccurrencesOfString:@" " withString:@""];

    // Change country code from 00xx to +xx.
    if ([mobileNumber hasPrefix:@"00"])
        mobileNumber = [NSString stringWithFormat:@"+%@", [mobileNumber substringFromIndex:2]];

    // Has the user entered the number in the international format with check above 00xx is also accepted.
    if (![mobileNumber hasPrefix:@"+"]) {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: NSLocalizedString(@"Your mobile number should start with your country code e.g. +31 or 0031", nil)};
        completion(NO, [NSError errorWithDomain:SystemUserErrorDomain code:SystemUserErrorMobileNumberNoPrefix userInfo:userInfo]);
        return;
    }

    if (self.mobileNumber != mobileNumber || !self.migrationCompleted) {
        [self.operationsManager pushMobileNumber:mobileNumber withCompletion:^(BOOL success, NSError *error) {
            if (success) {
                self.mobileNumber = mobileNumber;
                self.migrationCompleted = YES;
                completion(YES, nil);
            } else {
                NSDictionary *userInfo = @{NSUnderlyingErrorKey: error,
                                           NSLocalizedDescriptionKey: NSLocalizedString(@"Unable to save the number, please update the number.", nil)
                                           };
                completion(NO, [NSError errorWithDomain:SystemUserErrorDomain code:SystemUserFailedToSaveNumberRemote userInfo:userInfo]);
            }
        }];
    } else {
        completion(YES, nil);
    }
}

#pragma mark - SIP Handling

- (void)getAndActivateSIPAccountWithCompletion:(void (^)(BOOL success, NSError *error))completion {
    if (self.loggedIn) {
        [self fetchSIPAcountFromRemoteWithCompletion:^(BOOL success, NSError *error) {
            // It is only an success if the request was success and there was an sipAcount set.
            if (success && self.sipAccount) {
                self.sipEnabled = YES;
            } else {
                success = NO;
            }

            if (completion) {
                completion(success, error);
            }
        }];
    }
}

- (void)updateSIPAccountWithCompletion:(void (^)(BOOL success, NSError *error))completion {
    if (self.loggedIn) {
        if (self.sipEnabled) {
            [self fetchSIPAcountFromRemoteWithCompletion:completion];
        } else {
            [self fetchUserProfile];
        }
    }
}

- (void)fetchSIPAcountFromRemoteWithCompletion:(void (^)(BOOL success, NSError *error))completion {
    // Update the user profile.
    [self.operationsManager userProfileWithCompletion:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject, NSError *error) {
        // This user is allowed to use SIP, check if the account is configured.
        if  (!error) {
            // Set the outgoing number when getting the SIP account.
            self.outgoingNumber = responseObject[SystemUserApiKeyOutgoingNumber];

            NSString *appAccountURL = [responseObject objectForKey:SystemUserApiKeyAppAccountURL];
            [self updateSIPAccountWithURL:appAccountURL withCompletion:completion];
        } else {
            if (completion) {
                NSDictionary *userInfo = @{NSUnderlyingErrorKey: error};
                NSError *error = [NSError errorWithDomain:SystemUserErrorDomain code:SystemUserErrorFetchingUserProfile userInfo:userInfo];
                completion(NO, error);
            }
        }
    }];
}

/**
 *  Private helper to retrieve the SIP Account credentials from the supplied accountURL.
 *
 *  @param accountURL string with the url to the sip account
 *  @param completion A block that will be called with a success or failure of retrieving the sip credentials.
 */
- (void)updateSIPAccountWithURL:(NSString *)accountURL withCompletion:(void(^)(BOOL success, NSError *error))completion {
    // If there is no SIP Account for the user, it is removed.
    if ([accountURL isKindOfClass:[NSNull class]]) {
        [self removeSIPCredentials];

        if (completion) {
            completion(YES, nil);
        }
        return;
    }

    // Fetch the credentials.
    [self.operationsManager retrievePhoneAccountForUrl:accountURL withCompletion:^(AFHTTPRequestOperation *operation, NSDictionary *responseData, NSError *error) {

        // Couldn't fetch the credentials.
        if (error) {
            if (completion) {
                NSDictionary *userInfo = @{NSUnderlyingErrorKey: error};
                NSError *error = [NSError errorWithDomain:SystemUserErrorDomain code:SystemUserErrorFetchingSIPAccount userInfo:userInfo];
                completion(NO, error);
            }
            return;
        }

        id sipAccount = responseData[SystemUserApiKeySIPAccount];
        id sipPassword = responseData[SystemUserApiKeySIPPassword];
        // Check if the values returned are proper values.
        if (![sipAccount isKindOfClass:[NSNumber class]] || ![sipPassword isKindOfClass:[NSString class]]) {
            if (completion) {
                NSError *error = [NSError errorWithDomain:SystemUserErrorDomain code:SystemUserErrorFetchingSIPAccount userInfo:nil];
                completion(NO, error);
            }
            return;
        }

        // Only update settings if the credentials have changed.
        if (![self.sipAccount isEqualToString:[sipAccount stringValue]] || ![self.sipPassword isEqualToString:sipPassword]) {
            self.sipAccount = [sipAccount stringValue];
            [SAMKeychain setPassword:sipPassword forService:self.serviceName account:self.sipAccount];
            [[NSNotificationCenter defaultCenter] postNotificationName:SystemUserSIPCredentialsChangedNotification object:self];
        }
        if (completion) {
            completion(YES, nil);
        }
    }];
}

#pragma mark - API calls

- (void)updateSystemUserFromVGWithCompletion:(void (^)(NSError *error))completion {
    [self.operationsManager userProfileWithCompletion:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject, NSError *error) {
        if (!error) {
            [self setOwnPropertiesFromUserDict:responseObject withUsername:nil andPassword:nil];

            NSString *appAccountURL = [responseObject objectForKey:SystemUserApiKeyAppAccountURL];
            [self updateSIPAccountWithURL:appAccountURL withCompletion:^(BOOL success, NSError *error) {
                if (!error) {
                    [self setOwnPropertiesFromUserDict:responseObject withUsername:nil andPassword:nil];
                    if (completion) completion(nil);
                } else {
                    if (completion) completion(error);
                }
            }];
        } else {
            if (completion) completion(error);
        }
    }];
}

# pragma mark - Notifications / KVO

- (void)authorizationFailedNotification:(NSNotification *)notification {
    NSDictionary *errorUserInfo = @{NSLocalizedDescriptionKey: NSLocalizedString(@"You're not authorized", nil)};
    NSDictionary *logoutUserInfo = @{SystemUserLogoutNotificationDisplayNameKey: [self.displayName copy],
                                     SystemUserLogoutNotificationErrorKey: [NSError errorWithDomain:SystemUserErrorDomain code:SystemUserUnAuthorized userInfo:errorUserInfo]
                                     };
    [self logoutWithUserInfo:logoutUserInfo];
}

// Override default KVO behaviour for automatic notificationing
+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    if ([key isEqualToString:NSStringFromSelector(@selector(sipEnabled))] ||
        [key isEqualToString:NSStringFromSelector(@selector(clientID))]) {
        return NO;
    }
    return YES;
}

# pragma mark - helper functions

/**
 *  Given a string looking something like : client = "/api/apprelation/client/12345/"
 *  or only the id 12345 will return the found client ID.
 *
 *  @param clientID A string containing a client ID
 *
 *  @return the plain clientID or nil.
 */
- (NSString *)parseStringForClientID:(NSString *) givenString {
    NSString *clientIDPatternToSearch = @"/client/";
    NSCharacterSet* notDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];

    if (!givenString || [givenString isEqualToString:@""]) {
        return nil;

    } else if ([givenString containsString:clientIDPatternToSearch]) {
        return [givenString substringBetweenString:clientIDPatternToSearch andString:@"/"];

    } else if ([givenString rangeOfCharacterFromSet:notDigits].location == NSNotFound) {
        // The given string only contains numbers, return this as the Client ID.
        return givenString;

    } else {
        DDLogWarn(@"Unable to find a Client ID in string:%@", givenString);
        return nil;
    }
}

- (NSString *)debugDescription {
    NSMutableString *desc = [[NSMutableString alloc] initWithFormat:@"%@\n", [self description]];
    [desc appendFormat:@"\tusername: %@\n", self.username];
    [desc appendFormat:@"\tdisplayName: %@\n", self.displayName];
    [desc appendFormat:@"\toutgoingNumber: %@\n", self.outgoingNumber];
    [desc appendFormat:@"\tmobileNumber: %@\n", self.mobileNumber];
    [desc appendFormat:@"\tsipAccount: %@\n", self.sipAccount];
    [desc appendFormat:@"\tsipPassword: %@\n", self.sipPassword];
    [desc appendFormat:@"\tsipProxy: %@\n", self.sipProxy];
    [desc appendFormat:@"\tsipDomain: %@\n", [self sipDomain]];
    [desc appendFormat:@"\tsipRegisterOnAdd: %@\n", self.sipRegisterOnAdd ? @"YES" : @"NO"];
    [desc appendFormat:@"\tfirstName: %@\n", self.firstName];
    [desc appendFormat:@"\tlastName: %@\n", self.lastName];
    [desc appendFormat:@"\tclient id: %@\n", self.clientID];
    [desc appendFormat:@"\tmigrationCompleted: %@\n", self.migrationCompleted ? @"YES" : @"NO"];

    [desc appendFormat:@"\tsipEnabled: %@\n", self.sipEnabled ? @"YES" : @"NO"];
    [desc appendFormat:@"\tloggedIn: %@", self.loggedIn ? @"YES" : @"NO"];

    return desc;
}
@end
