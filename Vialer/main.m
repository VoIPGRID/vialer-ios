//
//  main.m
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AppDelegate.h"
#import "Configuration.h"
#import "lecore.h"

int main(int argc, char *argv[])
{
    @autoreleasepool {
        le_init();
        le_set_token([[[Configuration defaultConfiguration] logEntriesToken] UTF8String]);
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
