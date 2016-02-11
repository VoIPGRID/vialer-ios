//
//  SystemUser.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VialerSIPLib-iOS/VialerSIPLib.h>

/**
 *  Error Domain.
 */
extern NSString * const SystemUserErrorDomain;

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
     *  It was not possible to fetch the SIP account of the user
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
     *  The user is unauthorized.
     */
    SystemUserUnAuthorized,
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
 *  The username that is used to login
 */
@property (readonly, nonatomic) NSString *username;

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
 *  Indication if the user has done the migration from version 1.x to 2.x.
 */
@property (readonly, nonatomic) BOOL migrationCompleted;

#pragma mark - Sip specific handling

/**
 *  The account that will be used for SIP calling.
 */
@property (readonly, nonatomic) NSString *sipAccount;

/**
 *  The password that will be user for sip calling.
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

@property (nonatomic) BOOL sipRegisterOnAdd;

/**
 *  Is the user allowed to make SIP calls.
 */
@property (readonly, nonatomic) BOOL sipAllowed;

/**
 *  Does the user want to use SIP.
 */
@property (nonatomic) BOOL sipEnabled;

/**
 *  Singleton instance of the current user.
 *
 *  @return SystemUser singleton instance.
 */
+ (instancetype)currentUser;

/**
 *  This will login the user with the given user and password.
 *
 *  When login on remote was successful or failure, the completionblock will be called.
 *
 *  @param username   The username that will be used to login.
 *  @param password   The password that will be user to login.
 *  @param completion Block will be called after login. BOOL loggedin will tell if login was successful, NSError will return an error if there was one set.
 */
- (void)loginWithUsername:(NSString *)username password:(NSString *)password completion:(void(^)(BOOL loggedin, NSError *error))completion;

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
 *  This will fetch the up to date information from the VoIPGRID platform.
 *
 *  @param success Block will be called after the fetch from the VoIPGRID platform. BOOL success will tell if update was successful, NSError will return an error if there was one set.
 */
- (void)updateSIPAccountWithSuccess:(void (^)(BOOL success, NSError *error))completion;

/**
 *  This will fetch up to date information from the VoIPGRID platform.
 *
 *  @param completion Block that will be called after fetch. If an error during the fetch happend, this will be passed to the block.
 */
- (void)updateSystemUserFromVGWithCompletion:(void (^)(NSError *error))completion;

@end
