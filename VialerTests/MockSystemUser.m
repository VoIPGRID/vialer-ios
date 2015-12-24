//
//  MockSystemUser.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "MockSystemUser.h"

@implementation MockSystemUser

- (void)loginWithUser:(NSString *)user password:(NSString *)password completion:(void (^)(BOOL))completion {
    self.enteredUsername = user;
    self.enteredPassword = password;
    completion(self.returnSuccess);
}

@end
