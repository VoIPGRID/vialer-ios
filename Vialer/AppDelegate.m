//
//  AppDelegate.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "AppDelegate.h"

#import "AFNetworkActivityLogger.h"
#import "APNSHandler.h"
#import <AudioToolbox/AudioServices.h>
@import CoreData;
#import <VialerSIPLib/CallKitProviderDelegate.h>
#import "PhoneNumberModel.h"
#import "SIPUtils.h"
#import "SAMKeychain.h"
#import "SVProgressHUD.h"
#import "SystemUser.h"
#import <VialerSIPLib/VialerSIPLib.h>
#import "Vialer-Swift.h"

#ifdef DEBUG
@import Contacts;
#import "SDStatusBarManager.h"
#endif

@interface AppDelegate()
@property (readwrite, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readwrite, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readwrite, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic) UIBackgroundTaskIdentifier vibratingTask;
@property (nonatomic) BOOL stopVibrating;
@property (strong, nonatomic) UILocalNotification *incomingCallNotification;
@property (assign) BOOL isScreenshotRun;
@property (strong, nonatomic) CallKitProviderDelegate *callKitProviderDelegate;
@property (weak, nonatomic) VSLCallManager *callManager;
@end

NSString * const AppDelegateIncomingCallNotification = @"AppDelegateIncomingCallNotification";
NSString * const AppDelegateIncomingBackgroundCallAcceptedNotification = @"AppDelegateIncomingBackgroundCallAcceptedNotification";
NSString * const AppDelegateLocalNotificationCategory = @"AppDelegateLocalNotificationCategory";
NSString * const AppDelegateLocalNotificationAcceptCall = @"AppDelegateLocalNotificationAcceptCall";
NSString * const AppDelegateLocalNotificationDeclineCall = @"AppDelegateLocalNotificationDeclineCall";
NSString * const AppDelegateLocalNotificationCallIdKey = @"AppDelegateLocalNotificationCallIdKey";
static NSTimeInterval const AppDelegateVibratingTimeInterval = 2.0f;
static int const AppDelegateNumberOfVibrations = 5;

// Launch Arguments
static NSString * const AppLaunchArgumentScreenshotRun = @"ScreenshotRun";
static NSString * const AppLaunchArgumentNoAnimations = @"NoAnimations";

@implementation AppDelegate

#pragma mark - UIApplication delegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self interpretLaunchArguments];
    [VialerLogger setup];
    [VialerSIPLib sharedInstance].logCallBackBlock = ^(DDLogMessage *_Nonnull message) {
        [VialerLogger logWithDDLogMessage:message];
    };

    [SAMKeychain setAccessibilityType:kSecAttrAccessibleAfterFirstUnlock];
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];

    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeGradient];

    // Only when the app is run for screenshot purposes do the following:
    if (self.isScreenshotRun) {
#ifdef DEBUG
        [[SDStatusBarManager sharedInstance] setTimeString:@"09:41"];
        [[SDStatusBarManager sharedInstance] enableOverrides];

        // This is a fix for screenshot automation. It won't accept the "would like to access contacts" alert
        // if it is presented at the normal point in the app.
        CNContactStore *contactStore = [[CNContactStore alloc] init];
        [contactStore requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
            VialerLogDebug(@"Contacts access granted: %@", granted ? @"YES" : @"NO");
        }];
#endif
        [VialerGAITracker setupGAITrackerWithLogLevel:kGAILogLevelNone isDryRun:YES];

        // Clear out the userdefaults.
        NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
        [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    } else {
        [VialerGAITracker setupGAITracker];
    }

#ifdef DEBUG
    // Network logging
    [[AFNetworkActivityLogger sharedLogger] startLogging];
    [[AFNetworkActivityLogger sharedLogger] setLevel:AFLoggerLevelOff];
#endif

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatedSIPCredentials:) name:SystemUserSIPCredentialsChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sipDisabledNotification:) name:SystemUserSIPDisabledNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLoggedOut:) name:SystemUserLogoutNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextSaved:) name:NSManagedObjectContextDidSaveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeLocalNotification:) name:VSLCallStateChangedNotification object:nil];
    [[SystemUser currentUser] addObserver:self forKeyPath:NSStringFromSelector(@selector(clientID)) options:0 context:NULL];

    [[APNSHandler sharedHandler] registerForVoIPNotifications];

    if ([VialerSIPLib callKitAvailable]) {
        self.callKitProviderDelegate = [[CallKitProviderDelegate alloc] initWithCallManager:self.callManager];
    }
    [self setupCallbackForVoIPNotifications];

    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [[SystemUser currentUser] updateSystemUserFromVGWithCompletion:nil];
        // No completion necessary, because an update will follow over the "SystemUserSIPCredentialsChangedNotifications".

        VSLCall *call = [SIPUtils getFirstActiveCall];
        if (call.callState == VSLCallStateIncoming) {
            NSDictionary *notificationInfo = @{VSLNotificationUserInfoCallKey : call};
            [[NSNotificationCenter defaultCenter] postNotificationName:AppDelegateIncomingCallNotification
                                                                object:self
                                                              userInfo:notificationInfo];
        }
    });
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *))restorationHandler {
    if (![VialerSIPLib callKitAvailable]) {
        return NO;
    }

    NSString *handle = userActivity.startCallHandle;
    if (handle == nil) {
        return NO;
    }

    VSLAccount *account = [SIPUtils addSIPAccountToEndpoint];
    [VialerGAITracker setupOutgoingSIPCallEvent];
    [[[VialerSIPLib sharedInstance] callManager] startCallToNumber:handle forAccount:account completion:^(VSLCall *call, NSError *error) {
        if (error) {
            VialerLogWarning(@"Error starting call through User activity. Error: %@", error);
        }
    }];
    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [self stopVibratingInBackground];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    VSLCall *call = [SIPUtils getFirstActiveCall];
    if (call && call.callState == VSLCallStateIncoming) {
        [self createLocalNotificationForCall:call];
    }
    [self saveContext];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [[SystemUser currentUser] removeObserver:self forKeyPath:NSStringFromSelector(@selector(clientID))];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VSLCallStateChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SystemUserLogoutNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SystemUserSIPDisabledNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SystemUserSIPCredentialsChangedNotification object:nil];

    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification completionHandler:(void (^)())completionHandler {
    [self stopVibratingInBackground];
    if ([identifier isEqualToString:AppDelegateLocalNotificationAcceptCall] || [identifier isEqualToString:AppDelegateLocalNotificationDeclineCall]) {
        NSInteger callId = [(NSNumber *)notification.userInfo[AppDelegateLocalNotificationCallIdKey] integerValue];

        VialerLogVerbose(@"User accepted a local notification with Action Identifier: %@ for callId:%ld", identifier, (long)callId);
        [self handleIncomingLocalBackgroudNotifications:identifier forCallId:callId];
    } else {
        VialerLogDebug(@"Unsupported action for local Notification: %@", identifier);
    }
    completionHandler();
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    VialerLogVerbose(@"Notification clicked without \"Action Identifier\" : %@", notification);
    NSInteger callId = [(NSNumber *)notification.userInfo[AppDelegateLocalNotificationCallIdKey] integerValue];;

    [self handleIncomingLocalBackgroudNotifications:nil forCallId:callId];
}

#pragma mark - setup helper methods

- (VSLCallManager *)callManager {
    if (!_callManager) {
        _callManager = [VialerSIPLib sharedInstance].callManager;
    }
    return _callManager;
}

- (void)interpretLaunchArguments {
    NSArray *arguments = [NSProcessInfo processInfo].arguments;
    if ([arguments containsObject:AppLaunchArgumentScreenshotRun]) {
        self.isScreenshotRun = YES;
    }
    if ([arguments containsObject:AppLaunchArgumentNoAnimations]) {
        [UIView setAnimationsEnabled:NO];
    }
}

- (void)handleIncomingLocalBackgroudNotifications:(NSString *)notificationIdentifier forCallId:(NSInteger)callId {
    VSLCall *call = [self.callManager callWithCallId:callId];

    if (call.callState > VSLCallStateNull) {
        NSDictionary *notificationInfo = @{VSLNotificationUserInfoCallKey : call};

        // Call is declined through the button on the local notification.
        if ([notificationIdentifier isEqualToString:AppDelegateLocalNotificationDeclineCall]) {
            NSError *error;
            [call decline:&error];
            [VialerGAITracker declineIncomingCallEvent];
            if (error) {
                VialerLogError(@"Error declining call: %@", error);
            }

        } else if ([notificationIdentifier isEqualToString:AppDelegateLocalNotificationAcceptCall]) {
            // Call is accepted through the button on the local notification.
            [[NSNotificationCenter defaultCenter] postNotificationName:AppDelegateIncomingBackgroundCallAcceptedNotification
                                                                object:self
                                                              userInfo:notificationInfo];

        } else if (!notificationIdentifier) {
            // The local notification was just tapped, not declined, not answerd.
            [[NSNotificationCenter defaultCenter] postNotificationName:AppDelegateIncomingCallNotification
                                                                object:self
                                                              userInfo:notificationInfo];
        }
    }
}

# pragma mark - Notifications

// KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(clientID))]) {
        [VialerGAITracker setCustomDimensionWithClientID:[SystemUser currentUser].clientID];
    }
}

- (void)updatedSIPCredentials:(NSNotification *)notification {
    VialerLogInfo(@"SIP Credentials have changed");
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([SystemUser currentUser].sipEnabled) {
            [SIPUtils setupSIPEndpoint];
            [[APNSHandler sharedHandler] registerForVoIPNotifications];

            if (![VialerSIPLib callKitAvailable]) {
                [self registerForLocalNotifications];
            }
        }
    });
}

- (void)sipDisabledNotification:(NSNotification *)notification {
    VialerLogInfo(@"SIP has been disabled");
    dispatch_async(dispatch_get_main_queue(), ^{
        [SIPUtils removeSIPEndpoint];
    });
}

- (void)registerForLocalNotifications {
    UIMutableUserNotificationAction *acceptCall = [[UIMutableUserNotificationAction alloc] init];
    acceptCall.activationMode = UIUserNotificationActivationModeForeground;
    acceptCall.title = NSLocalizedString(@"Accept", nil);
    acceptCall.identifier = AppDelegateLocalNotificationAcceptCall;
    acceptCall.destructive = NO;
    acceptCall.authenticationRequired = NO;

    UIMutableUserNotificationAction *declineCall = [[UIMutableUserNotificationAction alloc] init];
    declineCall.activationMode = UIUserNotificationActivationModeBackground;
    declineCall.title = NSLocalizedString(@"Decline", nil);
    declineCall.identifier = AppDelegateLocalNotificationDeclineCall;
    declineCall.destructive = NO;
    declineCall.authenticationRequired = NO;

    UIMutableUserNotificationCategory *noticationCategory = [[UIMutableUserNotificationCategory alloc] init];
    noticationCategory.identifier = AppDelegateLocalNotificationCategory;
    [noticationCategory setActions:@[acceptCall, declineCall] forContext: UIUserNotificationActionContextDefault];

    NSSet *categories = [NSSet setWithObjects:noticationCategory, nil];
    UIUserNotificationType types = (UIUserNotificationTypeAlert|
                                    UIUserNotificationTypeSound|
                                    UIUserNotificationTypeBadge);

    UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:types categories:categories];

    [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
}

- (void)userLoggedOut:(NSNotification *)notification {
    [SIPUtils removeSIPEndpoint];
}

- (void)managedObjectContextSaved:(NSNotification *)notification {
    [self.managedObjectContext performBlock:^{
        [self.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
    }];
}

- (void)setupCallbackForVoIPNotifications {
    [VialerSIPLib sharedInstance].incomingCallBlock = ^(VSLCall * _Nonnull call) {
        [VialerGAITracker incomingCallRingingEvent];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([VialerSIPLib callKitAvailable]) {
                VialerLogInfo(@"Incoming call block invoked, routing through CallKit.");
                [self.callKitProviderDelegate reportIncomingCall:call];
            } else {
                VialerLogInfo(@"Incoming call block invoked, using own app presentation.");
                [self incomingCallForNonCallKitWithCall:call];
            }
        });
    };
}

- (void)incomingCallForNonCallKitWithCall:(VSLCall *)call {
    __weak AppDelegate *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{

        if ([SIPUtils anotherCallInProgress:call]) {
            VialerLogInfo(@"There is another call in progress. For now declining the call that is incoming.");

            NSError *error;
            [call decline:&error];
            [VialerGAITracker declineIncomingCallBecauseAnotherCallInProgressEvent];
            if (error) {
                VialerLogError(@"Error declining call: %@", error);
            }
        } else {
            if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
                [weakSelf createLocalNotificationForCall:call];
                [weakSelf startVibratingInBackground];
            } else {
                VialerLogDebug(@"Call received with device in foreground. Call: %ld", (long)call.callId);
                NSDictionary *notificationInfo = @{VSLNotificationUserInfoCallKey : call};
                [[NSNotificationCenter defaultCenter] postNotificationName:AppDelegateIncomingCallNotification
                                                                    object:self
                                                                  userInfo:notificationInfo];
            }
        }
    });
}

- (void)createLocalNotificationForCall:(VSLCall *)call {
    // The notification
    self.incomingCallNotification = [[UILocalNotification alloc] init];
    self.incomingCallNotification.userInfo = @{AppDelegateLocalNotificationCallIdKey: [NSNumber numberWithInteger:call.callId]};
    self.incomingCallNotification.alertTitle = NSLocalizedString(@"Incoming call", nil);
    self.incomingCallNotification.alertBody = [NSString stringWithFormat:NSLocalizedString(@"Incoming call from: %1@ <%2@>", @"Incoming call from: 'callerName', <'callerNumber'>"), call.callerName, call.callerNumber];
    self.incomingCallNotification.alertLaunchImage = @"AppIcon";
    self.incomingCallNotification.soundName = @"ringtone.wav";
    self.incomingCallNotification.category = AppDelegateLocalNotificationCategory;

    [[UIApplication sharedApplication] scheduleLocalNotification:self.incomingCallNotification];
}

- (void)removeLocalNotification:(UILocalNotification *)notification {
    VSLCall *call = [[notification userInfo] objectForKey:VSLNotificationUserInfoCallKey];
    if (call.callState == VSLCallStateConnecting || call.callState == VSLCallStateDisconnected) {
        [[UIApplication sharedApplication] cancelLocalNotification:self.incomingCallNotification];
        [self stopVibratingInBackground];
    }
}

- (void)startVibratingInBackground {
    UIApplication *application = [UIApplication sharedApplication];

    // Vibrating
    self.stopVibrating = NO;
    self.vibratingTask = [application beginBackgroundTaskWithExpirationHandler:^{
        self.stopVibrating = YES;
        [application endBackgroundTask:self.vibratingTask];
        self.vibratingTask = UIBackgroundTaskInvalid;
    }];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        for (int i = 0; i < AppDelegateNumberOfVibrations; i++) {
            if (self.stopVibrating) {
                break;
            }
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
            [NSThread sleepForTimeInterval:AppDelegateVibratingTimeInterval];
        }
        [application endBackgroundTask:self.vibratingTask];
        self.vibratingTask = UIBackgroundTaskInvalid;
    });
}

- (void)stopVibratingInBackground {
    self.stopVibrating = YES;
    [[UIApplication sharedApplication] endBackgroundTask:self.vibratingTask];
}

#pragma mark - Core Data

- (void)saveContext {
    NSError *error;
    if (self.managedObjectContext && [self.managedObjectContext hasChanges] && ![self.managedObjectContext save:&error]) {
        VialerLogWarning(@"Unresolved error while saving Context: %@", error);
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
            VialerLogWarning(@"Could not create PersistentStoreCoordinator instance. Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
    return _persistentStoreCoordinator;
}

@end
