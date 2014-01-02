//
//  VoysRequestOperationManager.m
//  Vialer
//
//  Created by Reinier Wieringa on 31/10/13.
//  Copyright (c) 2013 Voys. All rights reserved.
//

#import "VoysRequestOperationManager.h"
#import "NSDate+RelativeDate.h"

#import "SSKeychain.h"

#define BASE_URL @"https://api.voipgrid.nl/api"
#define SERVICE_NAME @"com.voys.vialer"

enum VoysHttpErrors {
    kVoysHTTPBadCredentials = 401,
};
typedef enum VoysHttpErrors VoysHttpErrors;

@implementation VoysRequestOperationManager

+ (VoysRequestOperationManager *)sharedRequestOperationManager {
    static dispatch_once_t pred;
    static VoysRequestOperationManager *_sharedRequestOperationManager = nil;

    dispatch_once(&pred, ^{
		_sharedRequestOperationManager = [[self alloc] initWithBaseURL:[NSURL URLWithString:BASE_URL]];
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
            NSString *password = [SSKeychain passwordForService:SERVICE_NAME account:user];
            [self.requestSerializer setAuthorizationHeaderFieldWithUsername:user password:password];
        }
    }
	return self;
}

- (void)loginWithUser:(NSString *)user password:(NSString *)password success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    [self.requestSerializer setAuthorizationHeaderFieldWithUsername:user password:password];

    [self userDestinationWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        // Store credentials
        [[NSUserDefaults standardUserDefaults] setObject:user forKey:@"User"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [SSKeychain setPassword:password forService:SERVICE_NAME account:user];

        [[NSNotificationCenter defaultCenter] postNotificationName:LOGIN_SUCCEEDED_NOTIFICATION object:nil];
        
        success(operation, success);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(operation, error);
        if ([operation.response statusCode] != kVoysHTTPBadCredentials) {
            [self connectionFailed];
        }
    }];
}

- (void)logout {
    [self.operationQueue cancelAllOperations];

    NSString *user = [[NSUserDefaults standardUserDefaults] objectForKey:@"User"];
    
    NSError *error;
    [SSKeychain deletePasswordForService:SERVICE_NAME account:user error:&error];

    if (error) {
        NSLog(@"Error logging out: %@", [error localizedDescription]);
    }
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"User"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:LOGIN_FAILED_NOTIFICATION object:nil];
}

- (BOOL)isLoggedIn {
    NSString *user = [[NSUserDefaults standardUserDefaults] objectForKey:@"User"];
    return (user != nil) && ([SSKeychain passwordForService:SERVICE_NAME account:user] != nil);
}

- (void)userDestinationWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    [self GET:@"userdestination/" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(operation, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(operation, error);
        if ([operation.response statusCode] == kVoysHTTPBadCredentials) {
            [self loginFailed];
        }
    }];
}

- (void)phoneAccountWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    [self GET:@"phoneaccount/phoneaccount/" parameters:[NSDictionary dictionary] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(operation, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(operation, error);
        if ([operation.response statusCode] == kVoysHTTPBadCredentials) {
            [self loginFailed];
        }
    }];
}

- (void)clickToDialToNumber:(NSString *)toNumber fromNumber:(NSString *)fromNumber success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    [self POST:@"clicktodial/" parameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                           toNumber, @"b_number",
                                           fromNumber, @"a_number",
                                           @"default_number", @"b_cli",
                                           nil
                                           ] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(operation, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(operation, error);
        if ([operation.response statusCode] == kVoysHTTPBadCredentials) {
            [self loginFailed];
        }
    }];
}

- (void)clickToDialStatusForCallId:(NSString *)callId success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    NSString *url = [[@"clicktodial/" stringByAppendingString:callId] stringByAppendingString:@"/"];

    [self GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(operation, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(operation, error);
        if ([operation.response statusCode] == kVoysHTTPBadCredentials) {
            [self loginFailed];
        }
    }];
}

- (void)cdrRecordWithLimit:(NSInteger)limit offset:(NSInteger)offset sourceNumber:(NSString *)sourceNumber callDateGte:(NSDate *)date success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    [self GET:@"cdr/record/" parameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                         @(limit), @"limit",
                                         @(offset), @"offset",
                                         sourceNumber, @"src_number",
                                         nil
                                         ]
      success:^(AFHTTPRequestOperation *operation, id responseObject) {
          success(operation, responseObject);
      } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
          failure(operation, error);
          if ([operation.response statusCode] == kVoysHTTPBadCredentials) {
              [self loginFailed];
          }
      }];
}

- (void)passwordResetWithEmail:(NSString *)email success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:BASE_URL]];
    [manager setRequestSerializer:[AFJSONRequestSerializer serializer]];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    [manager POST:@"permission/password_reset/" parameters:[NSDictionary dictionaryWithObjectsAndKeys:email, @"email", nil]
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              success(operation, responseObject);
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              failure(operation, error);
          }];
}

- (void)loginFailed {
    // No credentials
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection failed", nil) message:NSLocalizedString(@"Your email and/or password is incorrect.", nil) delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Ok", nil), nil];
    [alert show];
}

- (void)connectionFailed {
    // No credentials
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection failed", nil) message:NSLocalizedString(@"Unknown error, please check your internet connection.", nil) delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Ok", nil), nil];
    [alert show];
}

#pragma mark - Alert view delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    [[NSNotificationCenter defaultCenter] postNotificationName:LOGIN_FAILED_NOTIFICATION object:nil];
}

@end