//
//  VoIPGRIDRequestOperationManager.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "AFHTTPRequestOperationManager.h"

/**
 *  Error Domain for VoIPGRIDRequestOperationManager.
 */
extern NSString * const VoIPGRIDRequestOperationManagerErrorDomain;

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
};

/**
 *   Notification that can be listened to when there was an unauthorized request made.
 */
extern NSString * const VoIPGRIDRequestOperationManagerUnAuthorizedNotification;

@interface VoIPGRIDRequestOperationManager : AFHTTPRequestOperationManager

/**
 *  Singleton instance of the Operation Manager.
 *
 *  @return VoIPGRIDRequestOperationManager instance.
 */
+ (VoIPGRIDRequestOperationManager *)sharedRequestOperationManager;

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
 *  @return The AFHTTPRequestOperation instance.
 */
- (AFHTTPRequestOperation *)GET:(NSString *)url parameters:(NSDictionary *)parameters withCompletion:(void (^)(AFHTTPRequestOperation *operation, NSDictionary *responseData, NSError *error))completion;

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
 *  @return The AFHTTPRequestOperation instance.
 */
- (AFHTTPRequestOperation *)PUT:(NSString *)url parameters:(NSDictionary *)parameters withCompletion:(void (^)(AFHTTPRequestOperation *operation, NSDictionary *responseData, NSError *error))completion;

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
 *  @return The AFHTTPRequestOperation instance.
 */
- (AFHTTPRequestOperation *)POST:(NSString *)url parameters:(NSDictionary *)parameters withCompletion:(void (^)(AFHTTPRequestOperation *operation, NSDictionary *responseData, NSError *error))completion;

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
 *  @return The AFHTTPRequestOperation instance.
 */
- (AFHTTPRequestOperation *)DELETE:(NSString *)url parameters:(NSDictionary *)parameters withCompletion:(void (^)(AFHTTPRequestOperation *operation, NSDictionary *responseData, NSError *error))completion;

/**
 *  This method will try to remotely login the user.
 *
 *  If login was successful, the credentials will be stored internally to authenticate the next requests.
 *
 *  @param username   The username that should be used on login.
 *  @param password   The password that should be used on login.
 *  @param completion A block that will be called after the login attempt. It will return the response data if any or an error if any.
 */
- (void)loginWithUsername:(NSString *)username password:(NSString *)password withCompletion:(void (^)(NSDictionary *responseData, NSError *error))completion;

/**
 *  This method will try to fetch the profile of the currently authenticated user.
 *
 *  @param completion A block that will be called after the fetch attempt. It will return the response data if any or an error if any.
 */
- (void)userProfileWithCompletion:(void (^)(AFHTTPRequestOperation *operation, NSDictionary *responseData, NSError *error))completion;

/**
 *  Pushes the user's mobile number to the server
 *
 *  @param mobileNumber The mobile number to push.
 *  @param completion   A block that will be called after fetch attempt. It will return the response data if any or an error if any.
 */
- (void)pushMobileNumber:(NSString *)mobileNumber withCompletion:(void (^)(BOOL success, NSError *error))completion;

/**
 *  This method will try to request for a pasword reset email sent to given email address.
 *
 *  @param email      The email address where the password reset is asked for.
 *  @param completion A block that will be called after request attempt. It will return the response data if any or an error if any.
 */
- (void)passwordResetWithEmail:(NSString *)email withCompletion:(void (^)(AFHTTPRequestOperation *operation, NSDictionary *responseData, NSError *error))completion;

/**
 *  This method will try to request for a login token for the currently authenticated user.
 *
 *  @param completion A block that will be called after request attempt. It will return the response data if any or an error if any.
 */
- (void)autoLoginTokenWithCompletion:(void (^)(AFHTTPRequestOperation *operation, NSDictionary *responseData, NSError *error))completion;

/**
 *  This method will try to remotely fetch the phone account credentials.
 *
 *  @param phoneAccountUrl Url of the phone account that needs to be fetched.
 *  @param completion      A block that will be called after fetch attempt. It will return the response data if any or an error if any.
 */
- (void)retrievePhoneAccountForUrl:(NSString *)phoneAccountUrl withCompletion:(void (^)(AFHTTPRequestOperation *operation, NSDictionary *responseData, NSError *error))completion;

/**
 *  This method will try to remotely fetch the user destinations of the currently authenticated user.
 *
 *  @param completion A block that will be called after the fetch attempt. It will return the response data if any or an error if any.
 */
- (void)userDestinationsWithCompletion:(void (^)(AFHTTPRequestOperation *operation, NSDictionary *responseData, NSError *error))completion;

/**
 *  This method will try to remotely set the user destination of the currently authenticated user.
 *
 *  @param selectedUserResourceUri The user destination URI where the request can be sent to.
 *  @param destinationDict         A dictionary with the new user destination.
 *  @param completion              A block that will be called after put attempt. It will return the response data if any or an error if any.
 */
- (void)pushSelectedUserDestination:(NSString *)selectedUserResourceUri destinationDict:(NSDictionary *)destinationDict withCompletion:(void (^)(AFHTTPRequestOperation *operation, NSDictionary *responseData, NSError *error))completion;

/**
 *  This method will try to setup a TwoStep call remotely.
 *
 *  @param parameters A dictionary with parameters that are sent along with the request.
 *  @param completion A block that will be called after the setup attempt. It will return the response data if any or an error if any.
 */
- (void)setupTwoStepCallWithParameters:(NSDictionary *)parameters withCompletion:(void (^)(AFHTTPRequestOperation *operation, NSDictionary *responseData, NSError *error))completion;

/**
 *  This method will try to fetch the callstatus of a TwoStep call remotely.
 *
 *  @param callId     The ID of the call.
 *  @param completion A block that will be called after the fetch attempt. It will return the response data if any or an error if any.
 */
- (void)twoStepCallStatusForCallId:(NSString *)callId withCompletion:(void (^)(AFHTTPRequestOperation *operation, NSDictionary *responseData, NSError *error))completion;

/**
 *  This method will try to cancel to TwoStep call remotely.
 *
 *  @param callId     The ID of the call.
 *  @param completion A block that will be called after the cancel attempt. It will return the response data if any or an error if any.
 */
- (void)cancelTwoStepCallForCallId:(NSString *)callId withCompletion:(void (^)(AFHTTPRequestOperation *operation, NSDictionary *responseData, NSError *error))completion;

@end