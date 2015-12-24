//
//  MockSystemUser.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "SystemUser.h"

@interface MockSystemUser : SystemUser

@property (nonatomic) NSString *returnUser;
@property (nonatomic) NSString *enteredUsername;
@property (nonatomic) NSString *enteredPassword;
@property (nonatomic) BOOL returnSuccess;

- (instancetype)initPrivate;

@end
