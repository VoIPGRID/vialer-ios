//
//  AppDelegate.swift
//  Copyright © 2017 VoIPGRID. All rights reserved.
//

import AVFoundation
import CoreData
import Firebase
import UIKit
import UserNotifications
import PhoneLib
import ContactsUI
import Contacts

@UIApplicationMain
@objc class AppDelegate: UIResponder {

    fileprivate struct Configuration {
        struct LaunchArguments {
            static let screenShotRun = "ScreenshotRun"
            static let noAnimations = "NoAnimations"
        }
        struct Notifications {
            struct Identifiers {
                static let category = "IncomingCall"
                static let accept = "AcceptCall"
                static let decline = "DeclineCall"
                static let missed = "MissedCall"
            }
            static let incomingCallIDKey = "CallID"
            static let startConnectABCall = Notification.Name(rawValue: AppDelegateStartConnectABCallNotification)
            static let connectABPhoneNumberUserInfoKey = Notification.Name(rawValue: AppDelegateStartConnectABCallUserInfoKey)
        }
        struct Vibrations {
            static let count = 5
            static let interval: TimeInterval = 2.0
        }

        struct TimerForCall {
            static let maxTimesFiring = 10
            static let interval: TimeInterval = 1.0
        }
    }

    var window: UIWindow?
    let sharedApplication = UIApplication.shared
    @objc var isScreenshotRun = false
    var notificationCenter: UNUserNotificationCenter{
        return UNUserNotificationCenter.current()
    }
    var stopVibrating = false
    var vibratingTask: UIBackgroundTaskIdentifier?
    var callAvailabilityTimer: Timer!
    var callAvailabilityTimesFired: Int = 0
    
    var user = SystemUser.current()!
    let reachability = Reachability(true)!
    private var _callEventMonitor: Any? = nil
    fileprivate var callEventMonitor: CallEventsMonitor {
        if _callEventMonitor == nil {
            _callEventMonitor = CallEventsMonitor()
        }
        return _callEventMonitor as! CallEventsMonitor
    }
    let pushKitManager = PushKitManager()
    let sip = Sip()
}

// MARK: - UIApplicationDelegate
extension AppDelegate: UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        interpretLaunchArguments()
        VialerLogger.setup()

        SAMKeychain.setAccessibilityType(kSecAttrAccessibleAfterFirstUnlock)

        application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)

        setupUI()
        setupObservers()
        setupVoIP()
        setupFirebase()
        setupUNUserNotifications()

        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        DispatchQueue.global(qos: .background).async {
            // No completion necessary, because an update will follow over the "SystemUserSIPCredentialsChangedNotifications".
            if self.user.loggedIn {
                self.sip.register()
                self.user.updateFromVG(completion: nil)
            }
        }
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        return didStartCallFor(userActivity: userActivity)
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        stopVibratingInBackground()

        DispatchQueue.main.async {
            self.sip.register()
            self.pushKitManager.registerForVoIPPushes()
            self.syncUserWithBackend()
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        NotificationCenter.default.post(name: Notification.Name.teardownSip, object: self)
        saveContext()

        DispatchQueue.main.async {
            self.sip.unregister()
            self.pushKitManager.registerForVoIPPushes()
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        removeObservers()
        callEventMonitor.stop()
        
        // Saves changes in the application's managed object context before the application terminates.
        saveContext()
    }
}

// MARK: - Helper methods
extension AppDelegate {

    /// Check if we're in a screenshot run
    fileprivate func interpretLaunchArguments() {
        let arguments = ProcessInfo.processInfo.arguments;
        if arguments.contains(Configuration.LaunchArguments.screenShotRun) {
            isScreenshotRun = true
            let appDomain = Bundle.main.bundleIdentifier!
            UserDefaults.standard.removePersistentDomain(forName: appDomain)
        }
        if arguments.contains(Configuration.LaunchArguments.noAnimations) {
            UIView.setAnimationsEnabled(false)
        }
    }

    fileprivate func setupFirebase() {
        if let filePath = Bundle.main.path(forResource: "FirebaseService-Info", ofType: "plist") {
            guard let fileopts = FirebaseOptions(contentsOfFile: filePath)
                else {
                    assert(false, "Couldn't load config file")
                    return
                }
            FirebaseApp.configure(options: fileopts)
        }
    }

    /// Set global UI settings
    fileprivate func setupUI() {
        SVProgressHUD.setDefaultStyle(.dark)
        #if DEBUG
        if isScreenshotRun {
            SDStatusBarManager.sharedInstance().timeString = "09:41"
            SDStatusBarManager.sharedInstance().enableOverrides()

            CNContactStore().requestAccess(for: .contacts) { granted, error in
                VialerLogDebug(granted ? "Contacts access granted" : "Contact access denied")
            }
        }
        #endif
    }
}

// MARK: - Observers
extension AppDelegate {

    /// Hook up the observers that AppDelegate should listen to
    fileprivate func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(updatedSIPCredentials), name: NSNotification.Name.SystemUserSIPCredentialsChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sipDisabledNotification), name: NSNotification.Name.SystemUserSIPDisabled, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sipDisabledNotification), name: NSNotification.Name.SystemUserLogout, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(userLoggedIn), name: NSNotification.Name.SystemUserLogin, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(managedObjectContextSaved(_:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(receivedApnsToken(_:)), name: Notification.Name.receivedApnsToken, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(receivedApnsToken(_:)), name: Notification.Name.remoteLoggingStateChanged, object: nil)
        user.addObserver(self, forKeyPath: #keyPath(SystemUser.clientID), options: NSKeyValueObservingOptions(rawValue: 0), context: nil)
        _ = ReachabilityHelper.instance
    }

    /// Remove the observers that the AppDelegate is listening to
    fileprivate func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.SystemUserSIPCredentialsChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.SystemUserSIPDisabled, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.SystemUserLogin, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.SystemUserLogout, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.MiddlewareAccountRegistrationIsDone, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSManagedObjectContextDidSave, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.teardownSip, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.receivedApnsToken, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.remoteLoggingStateChanged, object: nil)
        user.removeObserver(self, forKeyPath: #keyPath(SystemUser.clientID))
    }
}

// MARK: - KVO
extension AppDelegate {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(SystemUser.clientID) && user.clientID != nil {
            VialerGAITracker.setCustomDimension(withClientID: user.clientID)
        }
    }
}

// MARK: - Notifications
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    fileprivate func setupUNUserNotifications() {
        let options: UNAuthorizationOptions = [.alert, .sound]
        
        notificationCenter.delegate = self
        
        notificationCenter.requestAuthorization(options: options) {
            (granted, error) in
            if !granted {
                VialerLogInfo("User has declined notifications")
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Called when the app receives a notification.
        completionHandler([.alert, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        // The user taps on the missed call notification.
        if response.notification.request.identifier == Configuration.Notifications.Identifiers.missed {
            // Present the RecentsViewController.
            if let vialerRootVC = self.window?.rootViewController as? VailerRootViewController,
                let vialerDrawerVC = vialerRootVC.presentedViewController as? VialerDrawerViewController,
                let mainTabBarVC = vialerDrawerVC.centerViewController as? UITabBarController {
                // Make the app open on the recent calls screen.
                mainTabBarVC.selectedIndex = 2
            }
        }
        completionHandler()
    }

    fileprivate func registerForLocalNotifications() {
        VialerLogDebug("Starting registration with UNNotification for local notifications.")
        let acceptCallAction = UNNotificationAction(identifier: Configuration.Notifications.Identifiers.accept, title: NSLocalizedString("Accept", comment: "Accept"), options: [.foreground])
        let declineCallAction = UNNotificationAction(identifier: Configuration.Notifications.Identifiers.decline, title: NSLocalizedString("Decline", comment: "Decline"), options: [])
        let notificationCategory = UNNotificationCategory(identifier: Configuration.Notifications.Identifiers.category, actions: [acceptCallAction, declineCallAction], intentIdentifiers: [], options: [])
        notificationCenter.setNotificationCategories([notificationCategory])
        let options: UNAuthorizationOptions = [.alert, .sound]
        notificationCenter.requestAuthorization(options: options) {
            (granted, error) in
            if !granted {
                VialerLogDebug("Authorization for using UNUserNotificationCenter is denied.")
            }
        }
    }
}

// MARK: - VoIP
extension AppDelegate {

    /// Make sure the VoIP parts are up and running
    fileprivate func setupVoIP() {
        VialerLogDebug("Setting up VoIP")
        callEventMonitor.start()
        if user.sipEnabled {
            VialerLogDebug("VoIP is enabled start the endpoint.")
            updatedSIPCredentials()
        }

    }

    /// Register a callback to the sip library so that the app can handle missed calls
    private func setupMissedCallBack() {
        //@TODO - Reimplement when library supports
    }

    /// Setup the endpoint if user has SIP enabled
    @objc fileprivate func updatedSIPCredentials() {
        VialerLogInfo("SIP Credentials have changed")
        if !user.loggedIn {
            VialerLogWarning("User is not logged in")
            return
        }
        if !user.sipEnabled {
            VialerLogWarning("SIP not enabled")
            return
        }
            
        DispatchQueue.main.async {
            self.refreshMiddlewareRegistration()
            self.registerForLocalNotifications()
            self.syncUserWithBackend()
        }
    }

    @objc fileprivate func userLoggedIn() {
        VialerLogInfo("User has been logged in register for push notifications")

        DispatchQueue.main.async {
            self.refreshMiddlewareRegistration()
            self.syncUserWithBackend()
        }
    }

    /**
        Ensures we have opus enabled on the backend for users.
    */
    private func syncUserWithBackend() {
        if self.user.isOpusEnabledViaApi { return }

        if self.user.currentAudioQuality == 0 { return }

        self.user.updateUseOpus(1) { success, error in
            if success {
                VialerLogInfo("OPUS has been enabled for this user")
            } else {
                VialerLogError("Unable to enable OPUS for this user")
            }

            if error != nil {
                VialerLogError("Failed to enable OPUS for user: \(error)")
            }
        }
    }

    /// SIP was disabled, remove the endpoint
    @objc fileprivate func sipDisabledNotification() {
        VialerLogInfo("SIP has been disabled")
        DispatchQueue.main.async {
            if let token = self.pushKitManager.token {
                Middleware().deleteDeviceRegistration(token)
            } else {
                VialerLogWarning("Unable to delete device from middleware as we have no token")
            }
        }
    }

    /// Listen for call state change notifications
    ///
    /// If call is no longer running, we stop the vibrations and remove the local notification.
    ///
    /// - Parameter notification: Notification instance with VSLCall
    @objc fileprivate func callStateChanged(_ notification: Notification) {
//        resetCallAvailabilityTimer()
//
//        guard let call = notification.userInfo![VSLNotificationUserInfoCallKey] as? VSLCall,
//            call.callState == .connecting || call.callState == .disconnected else { return }
//
//        notificationCenter.removePendingNotificationRequests(withIdentifiers: [notification.name.rawValue])
//        stopVibratingInBackground()
    }

    /// Call was initiated from recents, addressbook or via call back on the native call kit ui. This will try to setup a call.
    ///
    /// - Parameter userActivity: NSUseractivity instance
    /// - Returns: success or failure of setting up call
    fileprivate func didStartCallFor(userActivity: NSUserActivity) -> Bool {
        guard let phoneNumber = userActivity.startCallHandle else { return false }

        // When there is no connection for VoIP or VoIP is disabled in the settings setup a connectAB call.
        if !ReachabilityHelper.instance.connectionFastEnoughForVoIP() {
            let notificationInfo = [Configuration.Notifications.connectABPhoneNumberUserInfoKey: phoneNumber]
            NotificationCenter.default.post(name: Configuration.Notifications.startConnectABCall, object: self, userInfo: notificationInfo)

            return true;
        }

        let session = sip.call(number: phoneNumber)

        return true
    }
    
//    private func createLocalNotificationMissedCall(forCall call: VSLCall) {
//        let content = UNMutableNotificationContent()
//        let callerNumber = call.callerNumber! // Possible options: a phone number or "anonymous".
//        var displayName = callerNumber
//
//        // If the call isn't anonymous try to look up the number for a known contact.
//        if callerNumber != "anonymous" {
//            let digits = PhoneNumberUtils.removePrefix(fromPhoneNumber: callerNumber)
//
//            if let phoneNumber = ContactModel.defaultModel.phoneNumbersToContacts[digits] {
//                displayName = phoneNumber.callerName!
//            }
//        } else {
//            displayName = NSLocalizedString("Anonymous", comment: "Anonymous")
//        }
//
//        content.title = displayName
//        content.body = NSLocalizedString("Missed call", comment: "Missed call")
//        content.sound = UNNotificationSound.default
//
//        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
//        let identifier = Configuration.Notifications.Identifiers.missed
//        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
//
//        notificationCenter.add(request) { (error) in
//            if let error = error {
//                print("Could not add missed call notification: \(error.localizedDescription)")
//            }
//        }
//    }

    /// Create a background task that will vibrate the phone.
    private func startVibratingInBackground() {
        stopVibrating = false
        vibratingTask = sharedApplication.beginBackgroundTask {
            self.stopVibrating = true
            if let task = self.vibratingTask {
                self.sharedApplication.endBackgroundTask(task)
            }
            self.vibratingTask = UIBackgroundTaskIdentifier(rawValue: UIBackgroundTaskIdentifier.invalid.rawValue)
        }

        DispatchQueue.global(qos: .userInteractive).async {
            for _ in 0...Configuration.Vibrations.count {
                if self.stopVibrating {
                    break
                }
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                Thread.sleep(forTimeInterval: Configuration.Vibrations.interval)
            }
            if let task = self.vibratingTask {
                self.sharedApplication.endBackgroundTask(task)
            }
            self.vibratingTask = UIBackgroundTaskIdentifier(rawValue: UIBackgroundTaskIdentifier.invalid.rawValue)
        }
    }

    /// Stop the vibrations
    fileprivate func stopVibratingInBackground() {
        stopVibrating = true
        guard let task = vibratingTask else { return }
        sharedApplication.endBackgroundTask(task)
    }
}

// MARK: - Core Data
extension AppDelegate {
    fileprivate func saveContext() {
        guard CoreDataStackHelper.instance.managedObjectContext.hasChanges else { return }
        do {
            try CoreDataStackHelper.instance.managedObjectContext.save()
        } catch let error {
            VialerLogWarning("Unresolved error while saving Context: \(error)");
            abort()
        }
    }

    @objc fileprivate func managedObjectContextSaved(_ notification: Notification) {
        CoreDataStackHelper.instance.managedObjectContext.perform {
            CoreDataStackHelper.instance.managedObjectContext.mergeChanges(fromContextDidSave: notification)
        }
    }
}

// MARK: - Middleware
extension AppDelegate {

    /**
        This can be called, regardless of the current state, and it will properly set the correct middleware
        registration status.
    */
    func refreshMiddlewareRegistration() {
        guard let token = self.pushKitManager.token else {
            VialerLogInfo("Unable to perform any middleware updates as we do not have a valid APNS token.")
            self.pushKitManager.registerForVoIPPushes()
            return
        }

        let middleware = Middleware()

        if user.loggedIn && user.sipEnabled {
            VialerLogInfo("Registering user with the middleware.")
            middleware.sentAPNSToken(token)
        } else {
            VialerLogInfo("Deleting user from the middleware.")
            middleware.deleteDeviceRegistration(token)
        }
    }

    @objc fileprivate func receivedApnsToken(_ notification: NSNotification) {
        refreshMiddlewareRegistration()
    }
}

extension Notification.Name {
    /**
        A notification that is emitted when a token has been received from the apns
        servers.
    */
    static let remoteLoggingStateChanged = Notification.Name("remote-logging-state-changed")
}
