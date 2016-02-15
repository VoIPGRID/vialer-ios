//
//  AppDelegate.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "AppDelegate.h"

#import "AFNetworkActivityLogger.h"
@import AVFoundation;
#ifdef DEBUG
#import "SDStatusBarManager.h"
#endif
#import "SSKeychain.h"

#import "APNSHandler.h"
#import "HDLumberjackLogFormatter.h"
#import "GAITracker.h"
#import "SIPUtils.h"
#import "SystemUser.h"
#import <VialerSIPLib-iOS/VialerSIPLib.h>

@interface AppDelegate()
@property (readwrite, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readwrite, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readwrite, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@end

@implementation AppDelegate

#pragma mark - UIApplication delegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self setupCocoaLumberjackLogging];
    [SSKeychain setAccessibilityType:kSecAttrAccessibleAfterFirstUnlock];
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];

    [[APNSHandler sharedHandler] registerForVoIPNotifications];

    //Only when the app is run for screenshot purposes do the following:
    if ([[self class] isSnapshotScreenshotRun]) {
#ifdef DEBUG
        [[SDStatusBarManager sharedInstance] setTimeString:@"09:41"];
        [[SDStatusBarManager sharedInstance] enableOverrides];
#endif
        [GAITracker setupGAITrackerWithLogLevel:kGAILogLevelNone andDryRun:YES];

        //Clear out the userdefaults
        NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
        [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    } else {
        [GAITracker setupGAITracker];
    }

#ifdef DEBUG
    // Network logging
    [[AFNetworkActivityLogger sharedLogger] startLogging];
    [[AFNetworkActivityLogger sharedLogger] setLevel:AFLoggerLevelInfo];
#endif

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatedSIPCredentials:) name:SystemUserSIPCredentialsChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLoggedOut:) name:SystemUserLogoutNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextSaved:) name:NSManagedObjectContextDidSaveNotification object:nil];

    if ([SystemUser currentUser].sipEnabled) {
        [SIPUtils setupSIPEndpoint];
    }

    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [[SystemUser currentUser] updateSIPAccountWithCompletion:^(BOOL success, NSError *error) {
            if (!error) {
                //[[PZPushMiddleware sharedInstance] updateDeviceRecord];
            }
        }];
    });
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [self saveContext];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

#pragma mark - setup helper methods

+ (BOOL)isSnapshotScreenshotRun {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"FASTLANE_SNAPSHOT"];
}

- (void)setupCocoaLumberjackLogging {
    //Add the Terminal and TTY(XCode console) loggers to CocoaLumberjack (simulate the default NSLog behaviour)
    HDLumberjackLogFormatter* logFormat = [[HDLumberjackLogFormatter alloc] init];

    DDASLLogger *aslLogger = [DDASLLogger sharedInstance];
    [aslLogger setLogFormatter: logFormat];
    DDTTYLogger *ttyLogger = [DDTTYLogger sharedInstance];
    [ttyLogger setLogFormatter:logFormat];
    [ttyLogger setColorsEnabled:YES];

    //Give INFO a color
    UIColor *pink = [UIColor colorWithRed:(255/255.0) green:(58/255.0) blue:(159/255.0) alpha:1.0];
    [[DDTTYLogger sharedInstance] setForegroundColor:pink backgroundColor:nil forFlag:DDLogFlagInfo];

    [DDLog addLogger:aslLogger];
    [DDLog addLogger:ttyLogger];
}

# pragma mark - Notifications

- (void)updatedSIPCredentials:(NSNotification *)notification {
    if ([SystemUser currentUser].sipEnabled) {
        [SIPUtils setupSIPEndpoint];
    } else {
        [SIPUtils removeSIPEndpoint];
    }
}

- (void)userLoggedOut:(NSNotification *)notification {
    [SIPUtils removeSIPEndpoint];
}

- (void)managedObjectContextSaved:(NSNotification *)notification {
    [self.managedObjectContext performBlock:^{
        [self.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
    }];
}

#pragma mark - Handle person(s) & calls
- (void)handleSipCall:(GSCall *)sipCall {
    // TODO: fix sip call
}

#pragma mark - Core Data

- (void)saveContext {
    NSError *error;
    if (self.managedObjectContext && [self.managedObjectContext hasChanges] && ![self.managedObjectContext save:&error]) {
        NSLog(@"Unresolved error: %@", error);
        abort();
    }
}

- (NSManagedObjectContext *)managedObjectContext {
    if (!_managedObjectContext) {
        NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
        if (coordinator) {
            _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            _managedObjectContext.persistentStoreCoordinator = coordinator;
        }
    }
    return _managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
    if (!_managedObjectModel) {
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"VialerModel" withExtension:@"momd"];
        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    }
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (!_persistentStoreCoordinator) {
        NSURL *applicationsDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        NSURL *storeURL = [applicationsDirectory URLByAppendingPathComponent:@"Vialer.sqlite"];

        NSError *error;
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
            // For now, we will let the app crash and watch if this is happening during production. It doesn't break the app completely if the app crashes.recent
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
    return _persistentStoreCoordinator;
}

@end
