//
//  VoIPGRIDRequestOperationManager.m
//  Vialer
//
//  Created by Reinier Wieringa on 31/10/13.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import "VoIPGRIDRequestOperationManager.h"
#import "NSDate+RelativeDate.h"

#import "SSKeychain.h"

#define GetPermissionSystemUserProfileUrl @"permission/systemuser/profile/"
#define GetUserDestinationUrl @"userdestination/"
#define GetPhoneAccountUrl @"phoneaccount/phoneaccount/"
#define GetClickToDialUrl @"clicktodial/"
#define GetCdrRecordUrl @"cdr/record/"
#define PostPermissionPasswordResetUrl @"permission/password_reset/"
#define GetAutoLoginTokenUrl @"autologin/token/"
#define PutMobileNumber @"/api/permission/mobile_number/"


@interface VoIPGRIDRequestOperationManager ()
@end

@implementation VoIPGRIDRequestOperationManager

+ (VoIPGRIDRequestOperationManager *)sharedRequestOperationManager {
    static dispatch_once_t pred;
    static VoIPGRIDRequestOperationManager *_sharedRequestOperationManager = nil;

    dispatch_once(&pred, ^{
        NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"]];
        NSAssert(config != nil, @"Config.plist not found!");

        NSString *baseUrl = [[config objectForKey:@"URLS"] objectForKey:@"API"];
        NSAssert(baseUrl != nil, @"URLS - API not found in Config.plist!");

        _sharedRequestOperationManager = [[self alloc] initWithBaseURL:[NSURL URLWithString:baseUrl]];
    });
    return _sharedRequestOperationManager;
}

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (self) {
        [self setRequestSerializer:[AFJSONRequestSerializer serializer]];
        [self.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];

        // Set basic authentication if user is logged in
        NSString *user = [[NSUserDefaults standardUserDefaults] objectForKey:@"User"];
        if (user) {
            NSString *password = [SSKeychain passwordForService:[[self class] serviceName] account:user];
            [self.requestSerializer setAuthorizationHeaderFieldWithUsername:user password:password];
        }
    }
    return self;
}

- (void)retrievePhoneAccountForUrl:(NSString *)phoneAccountUrl success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    [self GET:[phoneAccountUrl stringByReplacingOccurrencesOfString:@"/api/" withString:@""] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(operation, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(operation, error);
    }];
}

- (void)loginWithUser:(NSString *)user password:(NSString *)password success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    [self.requestSerializer setAuthorizationHeaderFieldWithUsername:user password:password];
    
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"GET" URLString:[[NSURL URLWithString:GetPermissionSystemUserProfileUrl relativeToURL:self.baseURL] absoluteString] parameters:nil error:nil];
    //deprecated
    //NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"GET" URLString:[[NSURL URLWithString:GetPermissionSystemUserProfileUrl relativeToURL:self.baseURL] absoluteString] parameters:nil];
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *client = [responseObject objectForKey:@"client"];
        if (!client) {
            // This is a partner account, don't log in!
            failure(operation, nil);

            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Login failed", nil) message:NSLocalizedString(@"Your email and/or password is incorrect.", nil) delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Ok", nil), nil];
            [alert show];
        } else {
            
            
            NSString *outgoingCli = [responseObject objectForKey:@"outgoing_cli"];
            if ([outgoingCli isKindOfClass:[NSString class]]) {
                [[NSUserDefaults standardUserDefaults] setObject:outgoingCli forKey:@"OutgoingNumber"];
            } else {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"OutgoingNumber"];
            }
            
            NSString *mobile_nr = [responseObject objectForKey:@"mobile_nr"];
            if ([mobile_nr isKindOfClass:[NSString class]]) {
                [[NSUserDefaults standardUserDefaults] setObject:mobile_nr forKey:@"MobileNumber"];
            } else {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"MobileNumber"];
            }

            // Store credentials
            [[NSUserDefaults standardUserDefaults] setObject:user forKey:@"User"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [SSKeychain setPassword:password forService:[[self class] serviceName] account:user];

            [[NSNotificationCenter defaultCenter] postNotificationName:LOGIN_SUCCEEDED_NOTIFICATION object:nil];

            // Fetch SIP account credentials
            NSString *appAccountUrl = [responseObject objectForKey:@"app_account"];
            if ([appAccountUrl isKindOfClass:[NSString class]]) {
                [self retrievePhoneAccountForUrl:appAccountUrl success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    NSObject *account = [responseObject objectForKey:@"account_id"];
                    NSObject *password = [responseObject objectForKey:@"password"];
                    if ([account isKindOfClass:[NSNumber class]] && [password isKindOfClass:[NSString class]]) {
                        [self setSipAccount:[(NSNumber *)account stringValue] andSipPassword:(NSString *)password];
                    } else {
                        [self setSipAccount:nil andSipPassword:nil];
                    }
                    success(operation, success);
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    [self setSipAccount:nil andSipPassword:nil];
                    success(operation, success);
                }];
            } else {
                [self setSipAccount:nil andSipPassword:nil];
                success(operation, success);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(operation, error);
        if ([operation.response statusCode] == kVoIPGRIDHTTPBadCredentials) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Login failed", nil) message:NSLocalizedString(@"Your email and/or password is incorrect.", nil) delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Ok", nil), nil];
            [alert show];
        } else {
            [self connectionFailed];
        }
    }];

    [self setHandleAuthorizationRedirectForRequest:request andOperation:operation];
    [self.operationQueue addOperation:operation];
}

- (void)logout {
    [self.operationQueue cancelAllOperations];
    [self.requestSerializer clearAuthorizationHeader];

    // Clear cookies for web view
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in cookieStorage.cookies) {
        [cookieStorage deleteCookie:cookie];
    }

    // Remove sip account if present
    NSString *sipAccount = [[NSUserDefaults standardUserDefaults] objectForKey:@"SIPAccount"];
    if (sipAccount) {
        [SSKeychain deletePasswordForService:[[self class] serviceName] account:sipAccount error:NULL];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SIPAccount"];
    }

    NSError *error;
    NSString *user = [[NSUserDefaults standardUserDefaults] objectForKey:@"User"];

    [SSKeychain deletePasswordForService:[[self class] serviceName] account:user error:&error];
    if (error) {
        NSLog(@"Error logging out: %@", [error localizedDescription]);
    }

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"User"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"OutgoingNumber"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"MobileNumber"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [[NSNotificationCenter defaultCenter] postNotificationName:LOGIN_FAILED_NOTIFICATION object:nil];
}

+ (BOOL)isLoggedIn {
    NSString *user = [[NSUserDefaults standardUserDefaults] objectForKey:@"User"];
    return (user != nil);
}

- (void)userDestinationWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    [self GET:GetUserDestinationUrl parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(operation, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(operation, error);
        if ([operation.response statusCode] == kVoIPGRIDHTTPBadCredentials) {
            [self loginFailed];
        }
    }];
}

- (void)userProfileWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"GET" URLString:[[NSURL URLWithString:GetPermissionSystemUserProfileUrl relativeToURL:self.baseURL] absoluteString] parameters:nil error:nil];
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *outgoingCli = [responseObject objectForKey:@"outgoing_cli"];
        if ([outgoingCli isKindOfClass:[NSString class]]) {
            [[NSUserDefaults standardUserDefaults] setObject:outgoingCli forKey:@"OutgoingNumber"];
        } else {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"OutgoingNumber"];
        }
        success(operation, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(operation, error);
        if ([operation.response statusCode] == kVoIPGRIDHTTPBadCredentials) {
            [self loginFailed];
        }
    }];

    [self setHandleAuthorizationRedirectForRequest:request andOperation:operation];
    [self.operationQueue addOperation:operation];
}

- (void)phoneAccountWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    [self GET:GetPhoneAccountUrl parameters:[NSDictionary dictionary] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(operation, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(operation, error);
        if ([operation.response statusCode] == kVoIPGRIDHTTPBadCredentials) {
            [self loginFailed];
        }
    }];
}

- (void)clickToDialToNumber:(NSString *)toNumber fromNumber:(NSString *)fromNumber success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    [self POST:GetClickToDialUrl parameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                             toNumber, @"b_number",
                                             fromNumber, @"a_number",
                                             @"default_number", @"b_cli",
                                             @"default_number", @"a_cli",
                                             nil
                                             ] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(operation, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(operation, error);
        if ([operation.response statusCode] == kVoIPGRIDHTTPBadCredentials) {
            [self loginFailed];
        }
    }];
}

- (void)clickToDialStatusForCallId:(NSString *)callId success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    NSString *url = [[GetClickToDialUrl stringByAppendingString:callId] stringByAppendingString:@"/"];

    [self GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(operation, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(operation, error);
        if ([operation.response statusCode] == kVoIPGRIDHTTPBadCredentials) {
            [self loginFailed];
        }
    }];
}

- (void)cdrRecordWithLimit:(NSInteger)limit offset:(NSInteger)offset sourceNumber:(NSString *)sourceNumber callDateGte:(NSDate *)date success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    [self GET:GetCdrRecordUrl parameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                          @(limit), @"limit",
                                          @(offset), @"offset",
                                          sourceNumber, @"src_number",
                                          nil
                                          ]
      success:^(AFHTTPRequestOperation *operation, id responseObject) {
          success(operation, responseObject);
      } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
          failure(operation, error);
      }];
}

- (void)passwordResetWithEmail:(NSString *)email success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:self.baseURL];
    [manager setRequestSerializer:[AFJSONRequestSerializer serializer]];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];

    [manager POST:PostPermissionPasswordResetUrl parameters:[NSDictionary dictionaryWithObjectsAndKeys:email, @"email", nil]
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              success(operation, responseObject);
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              failure(operation, error);
          }];
}

- (void)autoLoginTokenWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    [self GET:GetAutoLoginTokenUrl parameters:[NSDictionary dictionary]
      success:^(AFHTTPRequestOperation *operation, id responseObject) {
          success(operation, responseObject);
      } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
          failure(operation, error);
      }];
}

- (void)loginFailed {
    // No credentials
    [self logout];

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Login failed", nil) message:NSLocalizedString(@"Your email and/or password is incorrect.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Ok", nil), nil];
    [alert show];
}

- (void)connectionFailed {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection failed", nil) message:NSLocalizedString(@"Unknown error, please check your internet connection.", nil) delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Ok", nil), nil];
    [alert show];
}

+ (NSString *)serviceName {
    return [[NSBundle mainBundle] bundleIdentifier];
}

- (void)setHandleAuthorizationRedirectForRequest:(NSURLRequest *)request andOperation:(AFHTTPRequestOperation *)operation {
    __block NSString *authorization = [request.allHTTPHeaderFields objectForKey:@"Authorization"];
    [operation setRedirectResponseBlock:^NSURLRequest *(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *redirectResponse) {
        if ([request.allHTTPHeaderFields objectForKey:@"Authorization"] != nil) {
            return request;
        }

        NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:request.URL cachePolicy:request.cachePolicy timeoutInterval:request.timeoutInterval];
        [urlRequest setValue:authorization forHTTPHeaderField:@"Authorization"];
        return urlRequest;
    }];
}

- (void)setSipAccount:(NSString *)sipAccount andSipPassword:(NSString *)sipPassword {
    if (sipAccount) {
        [[NSUserDefaults standardUserDefaults] setObject:sipAccount forKey:@"SIPAccount"];
        [SSKeychain setPassword:sipPassword forService:[[self class] serviceName] account:sipAccount];
        NSLog(@"Setting SIP Account %@", sipAccount);
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SIPAccount"];
        NSLog(@"No SIP Account");
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)user {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"User"];
}

- (NSString *)outgoingNumber {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"OutgoingNumber"];
}

- (NSString *)sipAccount {
    NSString *sipAccount = [[NSUserDefaults standardUserDefaults] objectForKey:@"SIPAccount"];
    return sipAccount;
}

- (NSString *)sipPassword {
    NSString *sipAccount = [self sipAccount];
    if (sipAccount) {
        return [SSKeychain passwordForService:[[self class] serviceName] account:sipAccount];
    }
    return nil;
}

- (void)pushMobileNumber:(NSString *)mobileNumber success:(void (^)())success  failure:(void (^)(NSError *error, NSString *userFriendlyErrorString))failure {
    //Has the user entered a number
    if (![mobileNumber length] > 0) {
        if (failure) failure(nil, NSLocalizedString(@"Unable to save \"My number\"", nil));
        return;
    }
    //Strip whitespaces
    mobileNumber = [mobileNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    //Change country code from 00xx to +xx
    if ([mobileNumber hasPrefix:@"00"])
        mobileNumber = [NSString stringWithFormat:@"+%@", [mobileNumber substringFromIndex:2]];
    
    //Has the user entered the number in the international format with check above 00xx is also accepted
    if (![mobileNumber hasPrefix:@"+"]) {
        if (failure) failure(nil, NSLocalizedString(@"MOBILE_NUMBER_SHOULD_START_WITH_COUNTRY_CODE_ERROR", nil));
        return;
    }

    //With all the checks and replacements done, is the number actually different from the stored one?
    if ([mobileNumber isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:@"MobileNumber"]]) {
        if (success) success();
        return;
    }
    
    //Sent the new number to the server
    NSDictionary *parameters = @{@"mobile_nr" : mobileNumber};
    [self PUT:PutMobileNumber parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [[NSUserDefaults standardUserDefaults] setObject:mobileNumber forKey:@"MobileNumber"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        if (success) success();
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSString *userFriendlyErrorString;
        
        if (operation.response.statusCode == 400)
            userFriendlyErrorString = [[operation.responseObject objectForKey:@"mobile_nr"] firstObject];
        
        if (failure) failure(error, userFriendlyErrorString);
    }];

}

#pragma mark - Alert view delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    [[NSNotificationCenter defaultCenter] postNotificationName:LOGIN_FAILED_NOTIFICATION object:nil];
}

@end