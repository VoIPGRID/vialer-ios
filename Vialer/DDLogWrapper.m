//
//  DDLogWrapper.m
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

#import "DDLogWrapper.h"

@import UIKit;
#import <CocoaLumberjack/CocoaLumberjack.h>
#import "SPLumberjackLogFormatter.h"

@implementation DDLogWrapper

+ (void)setup {
    SPLumberjackLogFormatter *logFormatter = [[SPLumberjackLogFormatter alloc] init];

    DDTTYLogger *ttyLogger = [DDTTYLogger sharedInstance];
    [ttyLogger setLogFormatter:logFormatter];

    [DDLog addLogger:ttyLogger];

#ifdef DEBUG
    // File logging
    DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
    fileLogger.maximumFileSize = 1024 * 1024 * 1; // Size in bytes
    fileLogger.rollingFrequency = 0; // Set rollingFrequency to 0, only roll on file size.
    [fileLogger logFileManager].maximumNumberOfLogFiles = 3;
    fileLogger.logFormatter = logFormatter;
    [DDLog addLogger:fileLogger];
#endif
}

+ (void)logVerbose:(NSString *)message {
    DDLogVerbose(@"%@", message);
}

+ (void)logInfo:(NSString *)message {
    DDLogInfo(@"%@", message);
}

+ (void)logWarn:(NSString *)message {
    DDLogWarn(@"%@", message);
}

+ (void)logError:(NSString *)message {
    DDLogError(@"%@", message);
}


@end
