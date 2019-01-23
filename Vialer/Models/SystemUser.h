//
//  SystemUser.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VialerSIPLib/VialerSIPLib.h>

/**
 *  Error Domain.
 */
extern NSString * const SystemUserErrorDomain;

extern NSString * const SystemUserAvailabilityPhoneNumberKey;
extern NSString * const SystemUserAvailabilityDescriptionKey;
extern NSString * const SystemUserAvailabilityLastFetchKey;
extern NSString * const SystemUserAvailabilityAvailabilityKey;

/**
 *  Errors the SystemUser can have.
 */
typedef NS_ENUM(NSInteger, SystemUserErrors) {
    /**
     *  The user tries to login with a type of user that isn't allowed to login.
     */
    SystemUserErrorUserTypeNotAllowed,
    /**
     *  It was not possible to login with the given credentials.
     */
    SystemUserErrorLoginFailed,
    /**
     *  It was not possible to fetch the SIP account of the user.
     */
    SystemUserErrorFetchingSIPAccount,
    /**
     *  It was not possible to fetch the user profile.
     */
    SystemUserErrorFetchingUserProfile,
    /**
     *  The mobile number is to short.
     */
    SystemUserErrorMobileNumberToShort,
    /**
     *  The mobile number has no prefix.
     */
    SystemUserErrorMobileNumberNoPrefix,
    /**
     *  The mobile number couldn't be stored remotely.
     */
    SystemUserFailedToSaveNumberRemote,
    /**
     *  When the encryption setting couldn't be stored remotely.
     */
    SystemUserFailedToSaveEncryptionToRemote,
    /**
     *  When the use of opus couldn't be stored remotely.
     */
    SystemUserFailedToSaveOpusToRemote,
    /**
     *  The user is unauthorized.
     */
    SystemUserUnAuthorized,
    /**
     * Two factor authentication token required.
     */
    SystemUserTwoFactorAuthenticationTokenRequired,
    /**
     * Two factor authentication token invalid.
     */
    SystemUserTwoFactorAuthenticationTokenInvalid
};

/**
 *  Notification that can be listened to when the user does login.
 */
extern NSString * const SystemUserLoginNotification;

/**
 *  Notification that can be listened to when the user does logout.
 */
extern NSString * const SystemUserLogoutNotification;

/**
 *  Key where in the dictionary the display name in the logoutNotification is stored.
 */
extern NSString * const SystemUserLogoutNotificationDisplayNameKey;

/**
 *  Key where in the dictionary the error in the logoutNotification is stored.
 */
extern NSString * const SystemUserLogoutNotificationErrorKey;

/**
 *  Notification that can be listened to when the user has changed SIP credentials.
 */
extern NSString * const SystemUserSIPCredentialsChangedNotification;

/**
 *  Notification that can be listened to when the user has changed the use of STUN.
 */
extern NSString * const SystemUserStunUsageChangedNotification;

/**
 *  Notification that can be listened to when the user has changed the use of encryption.
 */
extern NSString * const SystemUserEncryptionUsageChangedNotification;

/**
 *  Notification that can be listened to when the user has disabled SIP.
 */
extern NSString * const SystemUserSIPDisabledNotification;

/**
 *  Notification that can be listened to when the outgoing number has changed.
 */
extern NSString * const SystemUserOutgoingNumberUpdatedNotification;

/**
 * Notification that can be listened to when the use 3G plus for calling has changed.
 */
extern NSString * const SystemUserUse3GPlusNotification;

extern NSString * const SystemUserTwoFactorAuthenticationTokenNotification;

/**
 *  SystemUser class is representing the user information as available on the VoIPGRID platform.
 *
 *  Current the SystemUser class also represents a lot of information maintained/stored by the VoIPGRIDRequestOperationManager in the user defaults.
 */
@interface SystemUser : NSObject <SIPEnabledUser>

/**
 *  BOOL that will indicate is the user is logged in.
 */
@property (readonly, nonatomic) BOOL loggedIn;

/**
 *  The username that is used to login.
 */
@property (readonly, nonatomic) NSString *username;

/**
 *  The password of the user that is logged in.
 */
@property (readonly, nonatomic) NSString *password;

/**
 *  The API token to be used for API requests.
 */
@property (readonly, nonatomic) NSString *apiToken;

/**
 *  The name of the user to display, this could be:
 *
 *  1. Firstname + Lastname.
 *  2. Firstname.
 *  3. Lastname.
 *  4. User property.
 *  5. A message that no name could be displayed (should not happen).
 */
@property (readonly, nonatomic) NSString *displayName;

/**
 *  The outgoing number of the user.
 */
@property (readonly, nonatomic) NSString *outgoingNumber;

/**
 *  The mobile number of the user.
 */
@property (readonly, nonatomic) NSString *mobileNumber;

/**
 *  The first name of the user.
 */
@property (readonly, nonatomic) NSString *firstName;

/**
 *  The last name of the user.
 */
@property (readonly, nonatomic) NSString *lastName;

/**
 *  The client ID for this User.
 */
@property (readonly, nonatomic) NSString *clientID;

/**
 *  To which country code the app account was set.
 */
@property (readonly, nonatomic) NSString *country;

/**
 *  Indication if the user has done the migration from version 1.x to 2.x.
 */
@property (readonly, nonatomic) BOOL migrationCompleted;

#pragma mark - Sip specific handling

/**
 *  The account that will be used for SIP calling.
 */
@property (readonly, nonatomic) NSString *sipAccount;

/**
 *  The password that will be used for SIP calling.
 */
@property (readonly, nonatomic) NSString *sipPassword;

/**
 *  The domain where the PBX can be found.
 */
@property (readonly, nonatomic) NSString *sipDomain;

/**
 *  The proxy address where to connect to.
 */
@property (readonly, nonatomic) NSString *sipProxy;

/**
 *  Specify how Contact update will be done with the registration.
 */
@property (readonly, nonatomic) BOOL sipContactRewriteMethodAlwaysUpdate;

/**
 *  This will return if the SIP account should register when the user is added to the endpoint.
 */
@property (readonly, nonatomic) BOOL sipRegisterOnAdd;

/**
 *  Does the user want to use SIP.
 */
@property (nonatomic) BOOL sipEnabled;

/**
 * If SIP needs to be using encryption.
 */
@property (readonly, nonatomic) BOOL sipUseEncryption;

/**
 *  Does the user want a WiFi Notification when setting up a call.
 */
@property (nonatomic) BOOL showWiFiNotification;

/**
 * Use 3G+ to make VoIP calls.
 */
@property (nonatomic) BOOL use3GPlus;

/**
 * Use TLS to make VoIP calls.
 */
@property (nonatomic) BOOL useTLS;

/**
 * Use STUN servers in setting up VoIP calls.
 */
@property (nonatomic) BOOL useStunServers;

/**
 *  The users current availability.
 */
@property (strong, nonatomic) NSDictionary* currentAvailability;

/**
 *  The users current audio quality for VoIP calls.
 */
@property (nonatomic) NSInteger currentAudioQuality;

/**
 *  Singleton instance of the current user.
 *
 *  @return SystemUser singleton instance.
 */
+ (instancetype)currentUser;

/**
 *  This will login the user with the given user and password and/or token.
 *
 *  When login on remote was successful or failure, the completion block will be called.
 *
 *  @param username   The username that will be used to login.
 *  @param password   The password that will be user to login.
 *  @param token      The generated two factor authentication token.
 *  @param completion Block will be called after login.
                        BOOL loggedin will tell if login was successful,
                        BOOL tokenRequired will tell if a two factor token is required,
                        NSError will return an error if there was one set.
 */
- (void)loginToCheckTwoFactorWithUserName:(NSString *)username password:(NSString *)password andToken:(NSString *)token completion:(void(^)(BOOL loggedin, BOOL tokenRequired, NSError *error))completion;

/**
 *  Destroy all the setting of the current instance.
 */
- (void)removeCurrentUser;

/**
 *  This will logout the user.
 */
- (void)logout;

/**
 *  Update the mobile number of the user. This will update the number remotely also.
 *
 *  An unchanged number will be handled as a successfull update.
 *
 *  @param mobileNumber The new number.
 *  @param completion   A will be called after the update. BOOL success will tell if the update was successful, NSError will return an error if there was one set.
 */
- (void)updateMobileNumber:(NSString *)mobileNumber withCompletion:(void(^)(BOOL success, NSError *error))completion;

/**
 *  Update the setting to user Opus. This will update the codec setting on remote also.
 *
 *  @param codec        Which codec will be used.
 *  @param completion   A will be called after the update. BOOL success will tell if the update was successful, NSError will return an error if there was one set.
 */
- (void)updateUseOpus:(NSInteger)codec withCompletion:(void(^)(BOOL success, NSError *error))completion;

/**
 *  This will fetch the up to date information from the VoIPGRID platform and on success enables SIP.
 *
 *  @param completion Block will be called after the fetch from the VoIPGRID platform. BOOL success will tell if fetch was successful, NSError will return an error if there was one set.
 */
- (void)getAndActivateSIPAccountWithCompletion:(void (^)(BOOL success, NSError *error))completion;

/**
 *  This will fetch up to date information from the VoIPGRID platform.
 *
 *  @param completion Block that will be called after fetch. If an error during the fetch happened, this will be passed to the block.
 */
- (void)updateSystemUserFromVGWithCompletion:(void (^)(NSError *error))completion;

/**
 * Store the provided availability options for the current user.
 *
 * @param option Dictionary containing the new availability options.
 * @return String representation of the phone number and description or an indication the user isn't available.
 */
- (NSString *)storeNewAvailabilityInSUD:(NSDictionary *)option;

@end
