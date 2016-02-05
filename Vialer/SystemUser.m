//
//  SystemUser.m
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import "SystemUser.h"

#import <AVFoundation/AVAudioSession.h>
#import "SSKeychain.h"
#import "VoIPGRIDRequestOperationManager.h"


NSString * const SystemUserErrorDomain = @"Vialer.Systemuser";

NSString * const SystemUserLoginNotification = @"SystemUserLoginNotification";
NSString * const SystemUserLogoutNotification = @"SystemUserLogoutNotification";

NSString * const SystemUserSIPCredentialsChangedNotification = @"SystemUserSIPCredentialsChangedNotification";

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
static NSString * const SystemUserApiKeyLastName        = @"last_name";
static NSString * const SystemUserApiKeySIPAllowed      = @"allow_app_account";
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
static NSString * const SystemUserSUDLastName           = @"LastName";
static NSString * const SystemUserSUDSIPAccount         = @"SIPAccount";
static NSString * const SystemUserSUDSIPEnabled         = @"SipEnabled";
static NSString * const SystemUserSUDSipAllowed         = @"SIPAllowed";
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
@property (strong, nonatomic) NSString *lastName;

/**
 *  This boolean will keep track if the migration from app version 1.x to 2.x already happend.
 */
@property (readwrite, nonatomic) BOOL migrationCompleted;

/**
 *  SIP Properties
 */
@property (strong, nonatomic) NSString *sipAccount;
@property (readwrite, nonatomic) BOOL sipAllowed;

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
    self.lastName           = [defaults objectForKey:SystemUserSUDLastName];
    self.migrationCompleted = [defaults boolForKey:SystemUserSUDMigrationCompleted];

    /**
     *  SIP settings.
     */
    self.sipAllowed     = [defaults boolForKey:SystemUserSUDSipAllowed];
    self.sipEnabled     = [defaults boolForKey:SystemUserSUDSIPEnabled];
    self.sipAccount     = [defaults objectForKey:SystemUserSUDSIPAccount];

    /**
     *  If there is a username, the user is supposed to be logged in.
     *
     *  Warning, this is not a check on the server if the user still has proper credentials.
     */
    self.loggedIn = self.username != nil;
}

#pragma mark - Properties

- (VoIPGRIDRequestOperationManager *)operationsManager {
    if (!_operationsManager) {
        _operationsManager = [VoIPGRIDRequestOperationManager sharedRequestOperationManager];
    }
    return _operationsManager;
}

-(NSString *)displayName {
    if (self.firstName || self.lastName) {
        return [[NSString stringWithFormat:@"%@ %@", self.firstName ?: @"", self.lastName ?: @""] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    } else if (self.emailAddress) {
        return self.emailAddress;
    } else if (self.username) {
        return self.username;
    }
    return NSLocalizedString(@"No email address configured", nil);
}

- (void)setSipEnabled:(BOOL)sipEnabled {
    _sipEnabled = sipEnabled;
    [[NSUserDefaults standardUserDefaults] setBool:sipEnabled forKey:SystemUserSUDSIPEnabled];
}

- (NSString *)sipPassword {
    if (self.sipAccount) {
        return [SSKeychain passwordForService:self.serviceName account:self.sipAccount];
    }
    return nil;
}

- (NSString *)serviceName {
    return [[NSBundle mainBundle] bundleIdentifier];
}

- (void)setMobileNumber:(NSString *)mobileNumber {
    _mobileNumber = mobileNumber;
    [[NSUserDefaults standardUserDefaults] setObject:mobileNumber forKey:SystemUserSUDMobileNumber];
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
        [SSKeychain deletePasswordForService:self.serviceName account:_sipAccount];
    }
    _sipAccount = sipAccount;
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

        if (self.sipAllowed) {
            NSString *appAccountURL = [responseData objectForKey:SystemUserApiKeyAppAccountURL];
            [self updateSIPAccountWithURL:appAccountURL withCompletion:completion];
        } else {
            if (completion) {
                completion(YES, nil);
            }
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:SystemUserLoginNotification object:self];
    }];
}

- (void)logout {
    [self removeCurrentUser];
    [[NSNotificationCenter defaultCenter] postNotificationName:SystemUserLogoutNotification object:self];
}

- (void)removeCurrentUser {
    [SSKeychain deletePasswordForService:self.serviceName account:self.username];

    self.loggedIn = NO;
    self.username = nil;
    self.outgoingNumber = nil;
    self.mobileNumber = nil;
    self.emailAddress = nil;
    self.firstName = nil;
    self.lastName = nil;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:SystemUserSUDUsername];
    [defaults removeObjectForKey:SystemUserSUDOutgoingNumber];
    [defaults removeObjectForKey:SystemUserSUDMobileNumber];
    [defaults removeObjectForKey:SystemUserSUDEmailAddress];
    [defaults removeObjectForKey:SystemUserSUDFirstName];
    [defaults removeObjectForKey:SystemUserSUDLastName];

    [self removeSIPCredentials];
    self.sipAllowed = NO;
    [defaults removeObjectForKey:SystemUserSUDSipAllowed];

    [defaults synchronize];
}

- (void)removeSIPCredentials {
    [SSKeychain deletePasswordForService:self.serviceName account:self.sipAccount];
    self.sipAccount = nil;
    self.sipEnabled = NO;
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:SystemUserSUDSIPAccount];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:SystemUserSUDSIPEnabled];

    [[NSNotificationCenter defaultCenter] postNotificationName:SystemUserSIPCredentialsChangedNotification object:self];
}

- (void)setOwnPropertiesFromUserDict:(NSDictionary *)userDict withUsername:(NSString *)username andPassword:(NSString *)password {
    if (username && password) {
        self.username = username;
        [SSKeychain setPassword:password forService:self.serviceName account:username];
    }
    self.outgoingNumber = userDict[SystemUserApiKeyOutgoingNumber];
    self.mobileNumber   = userDict[SystemUserApiKeyMobileNumber];
    self.emailAddress   = userDict[SystemUserApiKeyEmailAddress];
    self.firstName      = userDict[SystemUserApiKeyFirstName];
    self.lastName       = userDict[SystemUserApiKeyLastName];

    self.sipAllowed     = [userDict[SystemUserApiKeySIPAllowed] boolValue];


    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.username forKey:SystemUserSUDUsername];
    [defaults setObject:self.outgoingNumber forKey:SystemUserSUDOutgoingNumber];
    [defaults setObject:self.mobileNumber forKey:SystemUserSUDMobileNumber];
    [defaults setObject:self.emailAddress forKey:SystemUserSUDEmailAddress];
    [defaults setObject:self.firstName forKey:SystemUserSUDFirstName];
    [defaults setObject:self.lastName forKey:SystemUserSUDLastName];

    [defaults setBool:self.sipAllowed forKey:SystemUserSUDSipAllowed];

    [defaults synchronize];
    self.loggedIn = YES;
}

- (void)updateMobileNumber:(NSString *)mobileNumber withCompletion:(void(^)(BOOL success, NSError *error))completion {
    if (![mobileNumber length] > 0) {
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
        self.migrationCompleted = YES;
        [self.operationsManager pushMobileNumber:mobileNumber withCompletion:^(BOOL success, NSError *error) {
            if (success) {
                self.mobileNumber = mobileNumber;
                completion(YES, nil);
            } else {
                completion(NO, error);
            }
        }];
    } else {
        completion(YES, nil);
    }
}

#pragma mark - SIP Handling

- (void)updateSIPAccountWithSuccess:(void (^)(BOOL success, NSError *error))completion {
    if (self.loggedIn && self.sipEnabled) {
        // Update the user profile.
        [self.operationsManager userProfileWithCompletion:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject, NSError *error) {
            // This user is allowed to use SIP, check if the account is configured.
            if  (!error) {
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
        if (![self.sipAccount isEqualToString:[sipAccount stringValue]] || [self.sipPassword isEqualToString:sipPassword]) {
            self.sipAccount = [sipAccount stringValue];
            [[NSUserDefaults standardUserDefaults] setObject:self.sipAccount forKey:SystemUserSUDSIPAccount];
            [SSKeychain setPassword:sipPassword forService:self.serviceName account:self.sipAccount];

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
            completion(nil);
        } else {
            completion(error);
        }
    }];
}

# pragma mark - Notifications

- (void)authorizationFailedNotification:(NSNotification *)notification {
    [self logout];
}

# pragma mark - Debug help

- (NSString *)debugDescription {
    NSMutableString *desc = [[NSMutableString alloc] initWithFormat:@"%@\n", [self description]];
    [desc appendFormat:@"\tusername: %@\n", self.username];
    [desc appendFormat:@"\tdisplayName: %@\n", self.displayName];
    [desc appendFormat:@"\toutgoingNumber: %@\n", self.outgoingNumber];
    [desc appendFormat:@"\tmobileNumber: %@\n", self.mobileNumber];
    [desc appendFormat:@"\tsipAccount: %@\n", self.sipAccount];
    [desc appendFormat:@"\tsipPassword: %@\n", self.sipPassword];
    [desc appendFormat:@"\tfirstName: %@\n", self.firstName];
    [desc appendFormat:@"\tlastName: %@\n", self.lastName];
    [desc appendFormat:@"\tmigrationCompleted: %@\n", self.migrationCompleted ? @"YES" : @"NO"];

    [desc appendFormat:@"\tisAllowedToSip: %@\n", self.sipAllowed ? @"YES" : @"NO"];
    [desc appendFormat:@"\tsipEnabled: %@\n", self.sipEnabled ? @"YES" : @"NO"];
    [desc appendFormat:@"\tloggedIn: %@", self.loggedIn ? @"YES" : @"NO"];
    
    return desc;
}

@end
