//
//  VoIPGRIDRequestOperationManager.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "AFHTTPSessionManager.h"

/**
 *  Error Domain for VoIPGRIDRequestOperationManager.
 */
extern NSString * _Nonnull const VoIPGRIDRequestOperationManagerErrorDomain;

/**
 *  Error the VoIPGRIDRequestOperationManager can have.
 */
typedef NS_ENUM(NSInteger, VoIPGRIDRequestOperationsManagerErrors) {
    /**
     *  Failed to login.
     */
    VoIPGRIDRequestOperationsManagerErrorLoginFailed,
};

/**
 *  The HTTP error statuscodes the VoIPGRID platform can return.
 */
typedef NS_ENUM(NSInteger, VoIPGRIDHttpErrors) {
    /**
     *  Bad request.
     */
    VoIPGRIDHttpErrorBadRequest = 400,
    /**
     *  Unauthorized.
     */
    VoIPGRIDHttpErrorUnauthorized = 401,
    /**
     *  Forbidden.
     */
    VoIPGRIDHttpErrorForbidden = 403,
    /**
     *  Not found.
     */
    VoIPGRIDHttpErrorNotFound = 404,
    /**
     *  Request timeout.
     */
    VoIPGRIDHttpErrorRequestTimeout = 408,
};

/**
 *   Notification that can be listened to when there was an unauthorized request made.
 */
extern NSString * const VoIPGRIDRequestOperationManagerUnAuthorizedNotification;

@interface VoIPGRIDRequestOperationManager : AFHTTPSessionManager

@property (readonly) AFURLSessionManager *manager;

/**
 *  Default initializer for this class.
 *
 *  @return A VoIPGRIDRequestOperationManager instance.
 */
- (instancetype)initWithDefaultBaseURL;

/**
 *  Initializes a VoIPGRIDRequestOperationManager connection to the default Base URL
 *  with a given request timeout interval.
 *
 *  @param requestTimeoutInterval The desired request timeout interval.
 *
 *  @return A VoIPGRIDRequestOperationManager instance with the given timeout interval.
 */
- (instancetype)initWithDefaultBaseURLandRequestOperationTimeoutInterval:(NSTimeInterval)requestTimeoutInterval;

/**
 * This init is not available.
 */
-  (instancetype _Nonnull)init __attribute__((unavailable("Init is not available")));
/**
 *  This method will do a HTTP GET request on the given url with given parameters.
 *
 *  When the request is completed, the completionblock will be called.
 *
 *  If the request was unauthorized, a VoIPGRIDRequestOperationManagerUnAuthorizedNotification will be posted.
 *
 *  @param url        The url that will be requested.
 *  @param parameters The url parameters that should be sent with the request.
 *  @param completion A block that will be called after the request has been finished. It will have the operation, possible responseData and an Error if something went wrong.
 *
 *  @return The NSURLResponse instance.
 */
- (nullable NSURLSessionDataTask *)GET:(nonnull NSString *)URLString
                            parameters:(nullable id)parameters
                        withCompletion:(void (^ _Nullable)(NSURLResponse * _Nonnull operation, NSDictionary * _Nullable responseData, NSError * _Nullable error))completion;

/**
 *  This method will do a HTTP PUT request on the given url with given parameters.
 *
 *  When the request is completed, the completionblock will be called.
 *
 *  If the request was unauthorized, a VoIPGRIDRequestOperationManagerUnAuthorizedNotification will be posted.
 *
 *  @param url        The url that will be requested.
 *  @param parameters The url parameters that should be sent with the request.
 *  @param completion A block that will be called after the request has been finished. It will have the operation, possible responseData and an Error if something went wrong.
 *
 *  @return The NSURLResponse instance.
 */
- (nullable NSURLSessionDataTask *)PUT:(nonnull NSString *)URLString
                            parameters:(nullable id)parameters
                        withCompletion:(void (^ _Nullable)(NSURLResponse * _Nonnull operation, NSDictionary * _Nullable responseData, NSError * _Nullable error))completion;
/**
 *  This method will do a HTTP POST request on the given url with given parameters.
 *
 *  When the request is completed, the completionblock will be called.
 *
 *  If the request was unauthorized, a VoIPGRIDRequestOperationManagerUnAuthorizedNotification will be posted.
 *
 *  @param url        The url that will be requested.
 *  @param parameters The url parameters that should be sent with the request.
 *  @param completion A block that will be called after the request has been finished. It will have the operation, possible responseData and an Error if something went wrong.
 *
 *  @return The NSURLResponse instance.
 */
- (nullable NSURLSessionDataTask *)POST:(nonnull NSString *)URLString
                            parameters:(nullable id)parameters
                        withCompletion:(void (^ _Nullable)(NSURLResponse * _Nonnull operation, NSDictionary * _Nullable responseData, NSError * _Nullable error))completion;
/**
 *  This method will do a HTTP DELETE request on the given url with given parameters.
 *
 *  When the request is completed, the completionblock will be called.
 *
 *  If the request was unauthorized, a VoIPGRIDRequestOperationManagerUnAuthorizedNotification will be posted.
 *
 *  @param url        The url that will be requested.
 *  @param parameters The url parameters that should be sent with the request.
 *  @param completion A block that will be called after the request has been finished. It will have the operation, possible responseData and an Error if something went wrong.
 *
 *  @return The NSURLResponse instance.
 */
- (nullable NSURLSessionDataTask *)DELETE:(nonnull NSString *)URLString
                               parameters:(nullable id)parameters
                           withCompletion:(void (^ _Nullable)(NSURLResponse * _Nonnull operation, NSDictionary * _Nullable responseData, NSError * _Nullable error))completion;

- (void)loginWithUserNameForTwoFactor:(nonnull NSString *)username
                             password:(nonnull NSString *)password
                              orToken:(nonnull NSString *)token
                       withCompletion:(void (^ _Nullable)(NSDictionary * _Nullable responseData, NSError * _Nullable error))completion;

/**
 *  This method will try to remotely login the user.
 *
 *  If login was successful, the credentials will be stored internally to authenticate the next requests.
 *
 *  @param username   The username that should be used on login.
 *  @param password   The password that should be used on login.
 *  @param completion A block that will be called after the login attempt. It will return the response data if any or an error if any.
 */
- (void)getSystemUserInfowithCompletion:(void (^ _Nullable )(NSDictionary * _Nullable responseData, NSError * _Nullable error))completion;

/**
 *  Logout the user notification for overriding in the subclass
 *
 *  @param notification NSNotification
 */
- (void)logoutUserNotification:(NSNotification * _Nullable)notification;

/**
 *  This method will try to fetch the profile of the currently authenticated user.
 *
 *  @param completion A block that will be called after the fetch attempt. It will return the response data if any or an error if any.
 */
- (void)userProfileWithCompletion:(void (^ _Nullable)(NSURLResponse * _Nonnull operation, NSDictionary * _Nullable responseData, NSError * _Nullable error))completion;

/**
 *  Pushes the user's mobile number to the server
 *
 *  @param mobileNumber The mobile number to push.
 *  @param completion   A block that will be called after fetch attempt. It will return the response data if any or an error if any.
 */
- (void)pushMobileNumber:(nonnull NSString *)mobileNumber withCompletion:(void (^ _Nullable)(BOOL success, NSError * _Nullable error))completion;

/**
 *  Enables secure calling for the users connected VoIP Account.
 *
 *  @param completion   A block that will be called after the push attempt. It will return the response data if any or an error if any.
 */
- (void)pushUseEncryptionWithCompletion:(void(^ _Nullable)(BOOL success, NSError * _Nullable error))completion;

/**
 *  This method will try to enable or disable the use of the opus codec.
 *
 *  @param enable       Wheter to enable the opus codec.
 *  @param completion   A block that will be called after the push attempt. It will return the response data if any or an error if any.
 */
- (void)pushUseOpus:(BOOL)enable withCompletion:(void(^)(BOOL success, NSError *error))completion;

/**
 *  This method will try to fetch the mobile profile of the currently authenticated user.
 *
 *  @param completion A block that will be called after request attempt. It will return the response data if any or an error if any.
 */
- (void)getMobileProfileWithCompletion:(void (^ _Nullable)(NSURLResponse * _Nonnull operation, NSDictionary * _Nullable responseData, NSError * _Nullable error))completion;

/**
 *  This method will try to request for a login token for the currently authenticated user.
 *
 *  @param completion A block that will be called after request attempt. It will return the response data if any or an error if any.
 */
- (void)autoLoginTokenWithCompletion:(void (^ _Nullable)(NSURLResponse * _Nonnull operation, NSDictionary * _Nullable responseData, NSError * _Nullable error))completion;

/**
 *  This method will try to remotely fetch the phone account credentials.
 *
 *  @param phoneAccountUrl Url of the phone account that needs to be fetched.
 *  @param completion      A block that will be called after fetch attempt. It will return the response data if any or an error if any.
 */
- (void)retrievePhoneAccountForUrl:(nonnull NSString *)phoneAccountUrl withCompletion:(void (^ _Nullable)(NSURLResponse * _Nonnull operation, NSDictionary * _Nonnull responseData, NSError * _Nonnull error))completion;

/**
 *  This method will try to remotely fetch the user destinations of the currently authenticated user.
 *
 *  @param completion A block that will be called after the fetch attempt. It will return the response data if any or an error if any.
 */
- (void)userDestinationsWithCompletion:(void (^ _Nullable)(NSURLResponse * _Nonnull operation, NSDictionary * _Nullable responseData, NSError * _Nullable error))completion;

/**
 *  This method will try to remotely set the user destination of the currently authenticated user.
 *
 *  @param selectedUserResourceUri The user destination URI where the request can be sent to.
 *  @param destinationDict         A dictionary with the new user destination.
 *  @param completion              A block that will be called after put attempt. It will return the response data if any or an error if any.
 */
- (void)pushSelectedUserDestination:(nonnull NSString *)selectedUserResourceUri
                    destinationDict:(nonnull NSDictionary *)destinationDict
                     withCompletion:(void (^ _Nullable)(NSURLResponse * _Nonnull operation, NSDictionary * _Nullable responseData, NSError * _Nullable error))completion;

/**
 *  This method will try to setup a TwoStep call remotely.
 *
 *  @param parameters A dictionary with parameters that are sent along with the request.
 *  @param completion A block that will be called after the setup attempt. It will return the response data if any or an error if any.
 */
- (void)setupTwoStepCallWithParameters:(nonnull NSDictionary *)parameters
                        withCompletion:(void (^ _Nullable )(NSURLResponse * _Nonnull operation, NSDictionary * _Nullable responseData, NSError * _Nullable error))completion;

/**
 *  This method will try to fetch the callstatus of a TwoStep call remotely.
 *
 *  @param callId     The ID of the call.
 *  @param completion A block that will be called after the fetch attempt. It will return the response data if any or an error if any.
 */
- (void)twoStepCallStatusForCallId:(nonnull NSString *)callId
                    withCompletion:(void (^ _Nullable)(NSURLResponse * _Nonnull operation, NSDictionary * _Nullable responseData, NSError * _Nullable error))completion;

/**
 *  This method will try to cancel to TwoStep call remotely.
 *
 *  @param callId     The ID of the call.
 *  @param completion A block that will be called after the cancel attempt. It will return the response data if any or an error if any.
 */
- (void)cancelTwoStepCallForCallId:(nonnull NSString *)callId withCompletion:(void (^ _Nullable)(NSURLResponse * _Nonnull operation, NSDictionary * _Nullable responseData, NSError * _Nullable error))completion;

- (void)updateAuthorisationHeaderWithTokenForUsername:(nonnull NSString *)username;
@end
