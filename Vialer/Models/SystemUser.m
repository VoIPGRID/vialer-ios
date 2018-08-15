//
//  SystemUser.m
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import "SystemUser.h"

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

NSString * const SystemUserUse3GPlusNotification             = @"SystemUserUse3GPlusNotification";

NSString * const SystemUserTwoFactorAuthenticationTokenNotification = @"SystemUserTwoFactorAuthenticationTokenNotification";
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
static NSString * const SystemUserApiKeySIPAccount      = @"appaccount_account_id";
static NSString * const SystemUserApiKeySIPPassword     = @"appaccount_password";
static NSString * const SystemUserApiKeyUseEncryption   = @"appaccount_use_encryption";
static NSString * const SystemUserApiKeyCountry         = @"appaccount_country";
static NSString * const SystemUserApiKeyAPIToken        = @"api_token";

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
static NSString * const SystemUserSUDShowWiFiNotification = @"ShowWiFiNotification";
static NSString * const SystemUserSUDSIPUseEncryption   = @"SIPUseEncryption";
static NSString * const SystemUserSUDUse3GPlus          = @"Use3GPlus";
static NSString * const SystemUserSUDUseTLS             = @"UseTLS";
static NSString * const SystemuserSUDUseStunServers     = @"UseStunServers";
static NSString * const SystemUserSUDMigrationCompleted = @"v2.0_MigrationComplete";
static NSString * const SystemUserSUDAPIToken           = @"APIToken";
static NSString * const SystemUserSUDCountry            = @"Country";
static NSString * const SystemUserCurrentAvailabilitySUDKey = @"AvailabilityModelSUDKey";


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
@property (strong, nonatomic) NSString *apiToken;
@property (strong, nonatomic) NSString *country;

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

@property (nonatomic) BOOL loggingOut;
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
    self.apiToken           = [defaults objectForKey:SystemUserSUDAPIToken];
    self.country            = [defaults objectForKey:SystemUserSUDCountry];

    /**
     *  If there is a username, the user is supposed to be logged in.
     *
     *  Warning, this is not a check on the server if the user still has proper credentials.
     */
    self.loggedIn = self.username != nil;

    /**
     *  SIP settings.
     */
    self.sipAccount         = [defaults objectForKey:SystemUserSUDSIPAccount];
    self.sipEnabled         = [defaults boolForKey:SystemUserSUDSIPEnabled];
    self.sipUseEncryption   = self.sipUseEncryption;
    self.showWiFiNotification = [defaults boolForKey:SystemUserSUDShowWiFiNotification];

    self.loggingOut = NO;
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
    if (!self.loggedIn) {
        return;
    }
    NSString *stringFromSipEnabledProperty = NSStringFromSelector(@selector(sipEnabled));
    // If sip is being enabled, check if there is an sipAccount and fire notification.
    if (sipEnabled && !_sipEnabled && self.sipAccount) {
        [self willChangeValueForKey:stringFromSipEnabledProperty];
        _sipEnabled = YES;
        [self didChangeValueForKey:stringFromSipEnabledProperty];

        // Post the notification async. Do not use NSNotificationQueue because when the app starts
        // the app delegate does not pickup on the notification when posted using the NSNotificationQueue.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            VialerLogDebug(@"Post from sipenabled");
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
    if (self.useTLS && self.sipUseEncryption) {
        return [[Configuration defaultConfiguration] UrlForKey:ConfigurationEncryptedSIPDomain];
    }
    return [[Configuration defaultConfiguration] UrlForKey:ConfigurationSIPDomain];
}

- (NSString *)sipProxy {
    return self.sipDomain;
}

- (NSString *)serviceName {
    return [[NSBundle mainBundle] bundleIdentifier];
}

- (BOOL)use3GPlus {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    // 3G+ calling is opt-out. So check if the key is not there, set it to yes.
    if(![[[defaults dictionaryRepresentation] allKeys] containsObject:SystemUserSUDUse3GPlus]){
        self.use3GPlus = YES;
    }
    return [defaults boolForKey:SystemUserSUDUse3GPlus];
}

- (BOOL)useTLS {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![[[defaults dictionaryRepresentation] allKeys] containsObject:SystemUserSUDUseTLS]) {
        self.useTLS = YES;
    }
    return [defaults boolForKey:SystemUserSUDUseTLS];
}

- (BOOL)useStunServers {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![[[defaults dictionaryRepresentation] allKeys] containsObject:SystemuserSUDUseStunServers]) {
        self.useStunServers = YES;
    }
    return [defaults boolForKey:SystemuserSUDUseStunServers];
}

-(BOOL)sipUseEncryption {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if(![[[defaults dictionaryRepresentation] allKeys] containsObject:SystemUserSUDSIPUseEncryption]){
        self.sipUseEncryption = YES;
    }
    return [defaults boolForKey:SystemUserSUDSIPUseEncryption];
}

- (BOOL)showWiFiNotification {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if(![[[defaults dictionaryRepresentation] allKeys] containsObject:SystemUserSUDShowWiFiNotification]){
        self.showWiFiNotification = YES;
    }
    return [defaults boolForKey:SystemUserSUDShowWiFiNotification];
}


- (void)setMobileNumber:(NSString *)mobileNumber {
    _mobileNumber = mobileNumber;
    if (mobileNumber) {
        [[NSUserDefaults standardUserDefaults] setObject:mobileNumber forKey:SystemUserSUDMobileNumber];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:SystemUserSUDMobileNumber];
    }
}

- (void)setSipUseEncryption:(BOOL)sipUseEncryption {
    [[NSUserDefaults standardUserDefaults] setBool:sipUseEncryption forKey:SystemUserSUDSIPUseEncryption];
}

- (void)setOutgoingNumber:(NSString *)outgoingNumber {
    if (outgoingNumber != _outgoingNumber) {
        _outgoingNumber = outgoingNumber;
        if (![outgoingNumber isKindOfClass:[NSNull class]]) {
            [[NSUserDefaults standardUserDefaults] setObject:outgoingNumber forKey:SystemUserSUDOutgoingNumber];
        }
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

- (NSDictionary *)currentAvailability {
    return [[NSUserDefaults standardUserDefaults] objectForKey:SystemUserCurrentAvailabilitySUDKey];
}

- (void)setCurrentAvailability:(NSDictionary *)currentAvailability {
    [[NSUserDefaults standardUserDefaults] setObject:currentAvailability forKey:SystemUserCurrentAvailabilitySUDKey];
}

- (void)setShowWiFiNotification:(BOOL)showWiFiNotification {
    showWiFiNotification = showWiFiNotification;
    [[NSUserDefaults standardUserDefaults] setBool:showWiFiNotification forKey:SystemUserSUDShowWiFiNotification];
}

- (void)setUse3GPlus:(BOOL)use3GPlus {
    use3GPlus = use3GPlus;
    [[NSUserDefaults standardUserDefaults] setBool:use3GPlus forKey:SystemUserSUDUse3GPlus];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:SystemUserUse3GPlusNotification object:self];
    });
}

- (void)setUseTLS:(BOOL)useTLS {
    useTLS = useTLS;
    [[NSUserDefaults standardUserDefaults] setBool:useTLS forKey:SystemUserSUDUseTLS];

    [self updateUseEncryptionWithCompletion:^(BOOL success, NSError *error) {
        if (!success) {
            self.sipUseEncryption = NO;
        } else {
            self.sipUseEncryption = useTLS;
        }

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            VialerLogDebug(@"post from setusetls");
            [[NSNotificationCenter defaultCenter] postNotificationName:SystemUserSIPCredentialsChangedNotification object:self];
        });
    }];
}

- (void)setUseStunServers:(BOOL)useStunServers {
    useStunServers = useStunServers;
    [[NSUserDefaults standardUserDefaults] setBool:useStunServers forKey:SystemuserSUDUseStunServers];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        VialerLogDebug(@"Post from setusestunservers");
        [[NSNotificationCenter defaultCenter] postNotificationName:SystemUserSIPCredentialsChangedNotification object:self];
    });
}

#pragma mark - Actions

- (void)loginToCheckTwoFactorWithUserName:(NSString *)username password:(NSString *)password andToken:(NSString *)token completion:(void(^)(BOOL loggedin, BOOL tokenRequired, NSError *error))completion {
    [self.operationsManager loginWithUserNameForTwoFactor:username password:password orToken:token withCompletion:^(NSDictionary *responseData, NSError *error) {

        if (error && [responseData objectForKey:@"apitoken"]) {
            NSDictionary *apiTokenDict = responseData[@"apitoken"];

                // There is no token supplied!
            if ([apiTokenDict objectForKey:@"two_factor_token"]) {
                if (completion) {
                    NSDictionary *userInfo = @{NSUnderlyingErrorKey: error};
                    NSString *twoFactorToken = apiTokenDict[@"two_factor_token"][0];

                    SystemUserErrors tokenErrorCode = SystemUserTwoFactorAuthenticationTokenRequired;

                    if ([twoFactorToken isEqualToString:@"invalid two_factor_token"]) {
                        tokenErrorCode = SystemUserTwoFactorAuthenticationTokenInvalid;
                    }

                    completion(NO, YES, [NSError errorWithDomain:SystemUserErrorDomain
                                                           code:tokenErrorCode
                                                       userInfo:userInfo]);
                    return;
                }
            }

            // Invalid email or password.
            if ([apiTokenDict objectForKey:@"email"] || [apiTokenDict objectForKey:@"password"]) {
                [self removeCurrentUser];
                if (completion) {
                    NSDictionary *userInfo = @{NSUnderlyingErrorKey: error};
                    completion(NO, NO, [NSError errorWithDomain:SystemUserErrorDomain
                                                           code:SystemUserErrorLoginFailed
                                                       userInfo:userInfo]);
                    return;
                }
            }
        } else {
            // No token required, or token accepted.
            self.apiToken = responseData[SystemUserApiKeyAPIToken];
            [self.operationsManager updateAuthorisationHeaderWithTokenForUsername:username];

            [self getSystemUserInfoWithUsername:username password:password completion:^(BOOL loggedin, NSError *error) {

                if (loggedin) {
                    [[NSUserDefaults standardUserDefaults] setObject:self.apiToken forKey:SystemUserSUDAPIToken];
                    completion(YES, YES, nil);
                } else {
                    completion(NO, YES, error);
                }
            }];


        }
    }];
}

- (void)getSystemUserInfoWithUsername:(NSString *)username password:(NSString *)password completion:(void(^)(BOOL loggedin, NSError *error))completion {
    [self.operationsManager getSystemUserInfowithCompletion:^(NSDictionary *responseData, NSError *error) {
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
    VialerLogDebug(@"Logout!");
    self.loggingOut = YES;
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
    self.apiToken = nil;
    self.country = nil;

    [self removeSIPCredentials];

    // Clear out the userdefaults.
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removePersistentDomainForName:appDomain];
    [defaults synchronize];
}

- (void)removeSIPCredentials {
    [SAMKeychain deletePasswordForService:self.serviceName account:self.sipAccount];
    self.sipEnabled = NO;
    self.sipAccount = nil;
    self.sipUseEncryption = NO;

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:SystemUserSUDSIPAccount];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:SystemUserSUDSIPEnabled];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:SystemUserSUDSIPUseEncryption];
}

- (void)setOwnPropertiesFromUserDict:(NSDictionary *)userDict withUsername:(NSString *)username andPassword:(NSString *)password {
    if (username && password) {
        self.username = username;
        [SAMKeychain setPassword:password forService:self.serviceName account:username];
    }

    self.emailAddress   = userDict[SystemUserApiKeyEmailAddress];

    self.firstName      = userDict[SystemUserApiKeyFirstName];
    self.preposition    = userDict[SystemUserApiKeyPreposition];
    self.lastName       = userDict[SystemUserApiKeyLastName];
    self.clientID       = userDict[SystemUserApiKeyClient];

    if (![userDict[SystemUserApiKeyMobileNumber] isEqual:[NSNull null]]) {
        self.mobileNumber = userDict[SystemUserApiKeyMobileNumber];
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // If the defaults contains a value for SIP Enabled, use that value,
    if ([defaults objectForKey:SystemUserSUDSIPEnabled]) {
        self.sipEnabled = [defaults boolForKey:SystemUserSUDSIPEnabled];
    } else {
        // else set to YES which will try to enable SIP for this user.
        self.sipEnabled = YES;
    }

    [defaults setObject:self.username forKey:SystemUserSUDUsername];
    [defaults setObject:self.emailAddress forKey:SystemUserSUDEmailAddress];

    [defaults setObject:self.firstName forKey:SystemUserSUDFirstName];
    [defaults setObject:self.preposition forKey:SystemUserSUDPreposition];
    [defaults setObject:self.lastName forKey:SystemUserSUDLastName];
    [defaults setObject:self.clientID forKey:SystemUserApiKeyClient];

    [defaults setObject:self.mobileNumber forKey:SystemUserSUDMobileNumber];
    
    [defaults synchronize];
    self.loggedIn = YES;
    self.loggingOut = NO;
}

- (void)setMobileProfileFromUserDict:(NSDictionary *)profileDict {
    self.outgoingNumber = profileDict[SystemUserApiKeyOutgoingNumber];
    self.country = profileDict[SystemUserApiKeyCountry];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([profileDict[SystemUserApiKeyOutgoingNumber] isKindOfClass:[NSNull class]]) {
        self.outgoingNumber = @"";
    } else {
        self.outgoingNumber = profileDict[SystemUserApiKeyOutgoingNumber];
    }
    [defaults setObject:self.outgoingNumber forKey:SystemUserSUDOutgoingNumber];
    [defaults setObject:self.country forKey:SystemUserSUDCountry];

    [defaults synchronize];
}

- (void)fetchUserProfile {
    if (self.loggingOut) {
        VialerLogInfo(@"Already logging out, no need to fetch user profile");
        return;
    }
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

- (void)updateUseEncryptionWithCompletion:(void(^)(BOOL success, NSError *error))completion {
    [self.operationsManager pushUseEncryptionWithCompletion:^(BOOL success, NSError *error) {
        if (success) {
            completion(YES, nil);
        } else {
            NSDictionary *userInfo = @{NSUnderlyingErrorKey: error,
                                       NSLocalizedDescriptionKey: NSLocalizedString(@"Unable to save to use encryption.", nil)
                                       };
            completion(NO, [NSError errorWithDomain:SystemUserErrorDomain code:SystemUserFailedToSaveEncryptionToRemote userInfo:userInfo]);
        }
    }];
}

#pragma mark - SIP Handling

- (void)getAndActivateSIPAccountWithCompletion:(void (^)(BOOL success, NSError *error))completion {
    if (self.loggedIn) {
        [self fetchMobileProfileFromRemoteWithCompletion:^(BOOL success, NSError *error) {
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

- (void)fetchMobileProfileFromRemoteWithCompletion:(void(^)(BOOL success, NSError *error))completion {
    [self.operationsManager getMobileProfileWithCompletion:^(AFHTTPRequestOperation *operation, NSDictionary *responseData, NSError *error) {
        if (!error) {
            
            [self setMobileProfileFromUserDict:responseData];
            
            id sipAccount = responseData[SystemUserApiKeySIPAccount];
            id sipPassword = responseData[SystemUserApiKeySIPPassword];
            id useEncryption = responseData[SystemUserApiKeyUseEncryption];

            if ([sipAccount isKindOfClass:[NSNull class]] || [sipPassword isKindOfClass:[NSNull class]]) {
                [self removeSIPCredentials];
                
                if (completion) {
                    completion(YES, nil);
                }
                return;
            }
            
            if (![sipAccount isKindOfClass:[NSNumber class]] || ![sipPassword isKindOfClass:[NSString class]]) {
                [self removeSIPCredentials];
                if (completion) {
                    NSError *error = [NSError errorWithDomain:SystemUserErrorDomain code:SystemUserErrorFetchingSIPAccount userInfo:nil];
                    completion(NO, error);
                }
                return;
            }
            
            if (![self.sipAccount isEqualToString:[sipAccount stringValue]] || ![self.sipPassword isEqualToString:sipPassword]) {
                self.sipAccount = [sipAccount stringValue];
                [SAMKeychain setPassword:sipPassword forService:self.serviceName account:self.sipAccount];
                [[NSNotificationCenter defaultCenter] postNotificationName:SystemUserSIPCredentialsChangedNotification object:self];
            }

            // Encryption is turned off for this account. Make an api call and enable it.
            if (self.useTLS && ([useEncryption isEqualToNumber:@0] || !self.sipUseEncryption)) {
                [self updateUseEncryptionWithCompletion:^(BOOL success, NSError *error) {
                    if (success) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:SystemUserSIPCredentialsChangedNotification object:self];
                        self.sipUseEncryption = YES;
                    } else {
                        if (completion) {
                            completion(NO, error);
                        }
                        return;
                    }
                }];
            } else if (!self.useTLS && self.sipUseEncryption){
                VialerLogDebug(@"Turn TLS Off");
                [self updateUseEncryptionWithCompletion:^(BOOL success, NSError *error) {
                    if (success) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:SystemUserSIPCredentialsChangedNotification object:self];
                        self.sipUseEncryption = NO;
                    } else {
                        if (completion) {
                            completion(NO, error);
                        }
                        return;
                    }
                }];
            }

            if (completion) completion(YES, nil);
        } else {
            if (completion) completion(NO, error);
        }
    }];
}

#pragma mark - API calls

- (void)updateSystemUserFromVGWithCompletion:(void (^)(NSError *error))completion {
    [self.operationsManager userProfileWithCompletion:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject, NSError *error) {
        
        if (!error && [responseObject objectForKey:SystemUserApiKeyAPIToken]) {
            self.apiToken = responseObject[SystemUserApiKeyAPIToken];
            [[NSUserDefaults standardUserDefaults] setObject:self.apiToken forKey:SystemUserSUDAPIToken];

            [self updateSystemUserFromVGWithCompletion:completion];
        } else if (!error) {
            [self setOwnPropertiesFromUserDict:responseObject withUsername:nil andPassword:nil];
            
            [self fetchMobileProfileFromRemoteWithCompletion:^(BOOL success, NSError *error) {
                if (completion) {
                    if (success) {
                        completion(nil);
                    } else {
                        completion(error);
                    }
                }
            }];
        } else if (error && error.code == SystemUserTwoFactorAuthenticationTokenRequired) {
            // The user has enabled two factor authentication.
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:SystemUserTwoFactorAuthenticationTokenNotification object:self];
            });
            if (completion) {
                completion(error);
            }
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
        VialerLogWarning(@"Unable to find a Client ID in string:%@", givenString);
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
