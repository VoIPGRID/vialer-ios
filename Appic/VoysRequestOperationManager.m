//
//  VoysRequestOperationManager.m
//  Appic
//
//  Created by Reinier Wieringa on 31/10/13.
//  Copyright (c) 2013 Voys. All rights reserved.
//

#import "VoysRequestOperationManager.h"

#import "SSKeychain.h"
#import "SVProgressHUD.h"

#define BASE_URL @"https://api.voipgrid.nl/api"
#define SERVICE_NAME @"com.voys.appic"

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

- (void)loginWithUser:(NSString *)user password:(NSString *)password success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success {
    [self.requestSerializer setAuthorizationHeaderFieldWithUsername:user password:password];

    [self userDestinationWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        // Store credentials
        [[NSUserDefaults standardUserDefaults] setObject:user forKey:@"User"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [SSKeychain setPassword:password forService:SERVICE_NAME account:user];

        success(operation, success);
    } failure:nil];
}

- (void)logout {
    NSError *error;

    NSString *user = [[NSUserDefaults standardUserDefaults] objectForKey:@"User"];
    [SSKeychain deletePasswordForService:SERVICE_NAME account:user error:&error];
    
    if (error) {
        NSLog(@"Error logging out: %@", [error localizedDescription]);
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"User"];
        [[NSUserDefaults standardUserDefaults] synchronize];

        [[NSNotificationCenter defaultCenter] postNotificationName:LOGIN_FAILED_NOTIFICATION object:nil];
    }
}

- (BOOL)isLoggedIn {
    NSString *user = [[NSUserDefaults standardUserDefaults] objectForKey:@"User"];
    return (user != nil) && ([SSKeychain passwordForService:SERVICE_NAME account:user] != nil);
}

- (void)userDestinationWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    [SVProgressHUD show];
    [self GET:@"userdestination/" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [SVProgressHUD dismiss];
        success(operation, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [SVProgressHUD dismiss];
        if ([operation.response statusCode] == 401) {
            [self loginFailed];
        } else {
            failure(operation, error);
        }
    }];
}

- (void)phoneAccountWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    [SVProgressHUD show];
    [self GET:@"phoneaccount/phoneaccount/" parameters:[NSDictionary dictionary] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [SVProgressHUD dismiss];
        success(operation, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [SVProgressHUD dismiss];
        if ([operation.response statusCode] == 401) {
            [self loginFailed];
        } else {
            failure(operation, error);
        }
    }];
}

- (void)clickToDialNumber:(NSString *)number success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Dialing...", nil)];
    [self POST:@"clicktodial/" parameters:[NSDictionary dictionaryWithObjectsAndKeys:number, @"b_number", nil] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [SVProgressHUD dismiss];
        success(operation, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [SVProgressHUD dismiss];
        if ([operation.response statusCode] == 401) {
            [self loginFailed];
        } else {
            failure(operation, error);
        }
    }];
}

- (void)loginFailed {
    // No credentials
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection failed", nil) message:NSLocalizedString(@"Your username and/or password is incorrect.", nil) delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Ok", nil), nil];
    [alert show];
}

#pragma mark - Alert view delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    [[NSNotificationCenter defaultCenter] postNotificationName:LOGIN_FAILED_NOTIFICATION object:nil];
}

@end