//
//  AppDelegate.swift
//  Copyright © 2017 VoIPGRID. All rights reserved.
//

import CoreData
import UIKit
import UserNotifications


@UIApplicationMain
class AppDelegate: UIResponder , UNUserNotificationCenterDelegate {

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
            }
            static let incomingCall = Notification.Name(rawValue: AppDelegateIncomingCallNotification)
            static let incomingCallAccepted = Notification.Name(rawValue: AppDelegateIncomingBackgroundCallAcceptedNotification)
            static let incomingCallIDKey = "CallID"
            static let startConnectABCall = Notification.Name(rawValue: AppDelegateStartConnectABCallNotification)
            static let connectABPhoneNumberUserInfoKey = Notification.Name(rawValue: AppDelegateStartConnectABCallUserInfoKey)
        }
        struct Vibrations {
            static let count = 5
            static let interval: TimeInterval = 2.0
        }
    }

    var window: UIWindow?

    @objc var isScreenshotRun = false
    
    @available(iOS 10.0, *)
    var center: UNUserNotificationCenter{
        return UNUserNotificationCenter.current()
    }
    //how to declare a UNNotification variable - availability problem
    //let incomingCallUNNotification: UNNotification? //orp NO.. use identifier instead?
    
    var incomingCallNotification: UILocalNotification?
    var stopVibrating = false
    var vibratingTask: UIBackgroundTaskIdentifier?
    var callKitProviderDelegate: CallKitProviderDelegate!

    var user = SystemUser.current()!
    lazy var vialerSIPLib = VialerSIPLib.sharedInstance()
}

// MARK: - UIApplicationDelegate
extension AppDelegate: UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        interpretLaunchArguments()
        VialerLogger.setup()

        SAMKeychain.setAccessibilityType(kSecAttrAccessibleAfterFirstUnlock)

        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)

        if #available(iOS 10.0, *) {
            center.delegate = self
        }
        
        setupUI()
        setupObservers()
        setupVoIP()

        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        DispatchQueue.global(qos: .background).async {
            // No completion necessary, because an update will follow over the "SystemUserSIPCredentialsChangedNotifications".
            if self.user.loggedIn {
                self.user.updateFromVG(completion: nil)
            }
            guard let call = SIPUtils.getFirstActiveCall(), call.callState == .incoming else { return }
            let notificationInfo = [VSLNotificationUserInfoCallKey: call]
            NotificationCenter.default.post(name: Configuration.Notifications.incomingCall, object: self, userInfo: notificationInfo)
        }
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        return didStartCallFor(userActivity: userActivity)
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        stopVibratingInBackground()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        saveContext()
        reportCallWhenAppEntersBackground()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        removeObservers()

        // Saves changes in the application's managed object context before the application terminates.
        saveContext()
    }

    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        VialerLogVerbose("Notification clicked without \"Action Identifier\" : \(notification)")
        guard let callID = notification.userInfo?[Configuration.Notifications.incomingCallIDKey] as? Int else { return }
        handleIncomingBackgroundNotification(identifier: nil, callID: callID)
    }

    func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, for notification: UILocalNotification, completionHandler: @escaping () -> Void) {
        stopVibratingInBackground()
        if identifier == Configuration.Notifications.Identifiers.accept || identifier == Configuration.Notifications.Identifiers.decline {
            guard let callID = notification.userInfo?[Configuration.Notifications.incomingCallIDKey] as? Int else { return }
            handleIncomingBackgroundNotification(identifier: identifier, callID: callID)
        } else {
            VialerLogError("Unsupported action for local Notification: \(String(describing: identifier))")
        }
        completionHandler()
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert,.sound, .badge])
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        stopVibratingInBackground()
        // Determine the user action
        switch response.actionIdentifier {
        case UNNotificationDismissActionIdentifier:
            VialerLogDebug("Dismiss Action")
        case UNNotificationDefaultActionIdentifier:
            VialerLogDebug("Default Action")
        case Configuration.Notifications.Identifiers.accept:
            fallthrough
        case Configuration.Notifications.Identifiers.decline:
            guard let callID = response.notification.request.content.userInfo[Configuration.Notifications.incomingCallIDKey] as? Int else { return }
            handleIncomingBackgroundNotification(identifier: response.actionIdentifier, callID: callID)
        default:
            VialerLogDebug("Unknown action")
        }
        completionHandler()
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
        NotificationCenter.default.addObserver(self, selector: #selector(callStateChanged(_:)), name: NSNotification.Name.VSLCallStateChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(callKitCallWasHandled(_:)), name: NSNotification.Name.CallKitProviderDelegateInboundCallAccepted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(callKitCallWasHandled(_:)), name: NSNotification.Name.CallKitProviderDelegateInboundCallRejected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(managedObjectContextSaved(_:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: nil)
        user.addObserver(self, forKeyPath: #keyPath(SystemUser.clientID), options: NSKeyValueObservingOptions(rawValue: 0), context: nil)

        _ = ReachabilityHelper.instance
    }

    /// Remove the observers that the AppDelegate is listening to
    fileprivate func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.SystemUserSIPCredentialsChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.SystemUserSIPDisabled, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.SystemUserLogout, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.VSLCallStateChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSManagedObjectContextDidSave, object: nil)
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
extension AppDelegate {

    /// We need to setup the local notification settings for pre CallKit app users
    fileprivate func registerForLocalNotifications() {
        VialerLogDebug("There is not CallKit available setup local notifications")
        if #available(iOS 10, *) {
            let acceptCallAction = UNNotificationAction(identifier: Configuration.Notifications.Identifiers.accept, title: NSLocalizedString("Accept", comment: "Accept"), options: [.foreground])
            let declineCallAction = UNNotificationAction(identifier: Configuration.Notifications.Identifiers.decline, title: NSLocalizedString("Decline", comment: "Decline"), options: [])
            let notificationCategory = UNNotificationCategory(identifier: Configuration.Notifications.Identifiers.category, actions: [acceptCallAction, declineCallAction], intentIdentifiers: [], options: [])
            let center = UNUserNotificationCenter.current()
            center.setNotificationCategories([notificationCategory])
            let options: UNAuthorizationOptions = [.alert, .sound, .badge]
            center.requestAuthorization(options: options) {
                (granted, error) in
                if !granted {
                    VialerLogDebug("Authorization for using UNUserNotificationCenter is denied.")
                }
                // In case we want to make the user grant permission to continue..
                //            center.getNotificationSettings { (settings) in
                //                if settings.authorizationStatus != .authorized {
                //                    VialerLogDebug("Authorization for using UNUserNotificationCenter is denied.")
                //                }
                //            }
            }
        } else {
            let acceptCallAction = UIMutableUserNotificationAction()
            acceptCallAction.activationMode = .foreground
            acceptCallAction.title = NSLocalizedString("Accept", comment: "Accept")
            acceptCallAction.identifier = Configuration.Notifications.Identifiers.accept
            acceptCallAction.isDestructive = false
            acceptCallAction.isAuthenticationRequired = false
            
            let declineCallAction = UIMutableUserNotificationAction()
            declineCallAction.activationMode = .background
            declineCallAction.title = NSLocalizedString("Decline", comment: "Decline")
            declineCallAction.identifier = Configuration.Notifications.Identifiers.decline
            declineCallAction.isDestructive = false
            declineCallAction.isAuthenticationRequired = false
            
            let notificationCategory = UIMutableUserNotificationCategory()
            notificationCategory.identifier = Configuration.Notifications.Identifiers.category
            notificationCategory.setActions([acceptCallAction, declineCallAction], for: .default)
            
            let settings = UIUserNotificationSettings(types: [.alert, .sound, .badge], categories: Set([notificationCategory]))
            UIApplication.shared.registerUserNotificationSettings(settings)
        }
    }
    
    @objc fileprivate func callKitCallWasHandled(_ notification: NSNotification) {
        if notification.name == NSNotification.Name.CallKitProviderDelegateInboundCallAccepted {
            VialerGAITracker.acceptIncomingCallEvent()
        } else if notification.name == NSNotification.Name.CallKitProviderDelegateInboundCallRejected {
            VialerGAITracker.declineIncomingCallEvent()
        }
    }
}

// MARK: - VoIP
extension AppDelegate {

    /// Make sure the VoIP parts are up and running
    fileprivate func setupVoIP() {
        if VialerSIPLib.callKitAvailable() {
            VialerLogDebug("Setup VoIP with CallKit support")
            callKitProviderDelegate = CallKitProviderDelegate(callManager: vialerSIPLib.callManager)
        }
        if user.sipEnabled {
            VialerLogDebug("VoIP is enabled start the endpoint.")
            updatedSIPCredentials()
        }
        setupIncomingCallBack()
        setupMissedCallBack()
    }

    /// Register a callback to the sip library so that the app can handle incoming calls
    private func setupIncomingCallBack() {
        VialerLogDebug("Setup the listener for incoming calls through VoIP");
        vialerSIPLib.setIncomingCall { call in
            VialerGAITracker.incomingCallRingingEvent()
            DispatchQueue.main.async {
                if VialerSIPLib.callKitAvailable() {
                    VialerLogInfo("Incoming call block invoked, routing through CallKit.")
                    self.callKitProviderDelegate.reportIncomingCall(call)
                } else {
                    VialerLogInfo("Incoming call block invoked, using own app presentation.")
                    self.reportIncomingCallForNonCallKit(withCall: call)
                }
            }
        }
    }

    /// Register a callback to the sip library so that the app can handle missed calls
    private func setupMissedCallBack() {
        VialerLogDebug("Setup the listener for missing calls.");
        vialerSIPLib.setMissedCall { (call) in
            switch call.terminateReason {
            case .callCompletedElsewhere:
                VialerLogDebug("Call completed elsewhere")
                VialerGAITracker.missedIncomingCallCompletedElsewhereEvent()
            case .originatorCancel:
                VialerLogDebug("Originator cancelled")
                VialerGAITracker.missedIncomingCallOriginatorCancelledEvent()
            case .unknown:
                break
            }
        }
    }

    /// Handle the incoming call
    ///
    /// This function is only used for non CallKit app users.
    ///
    /// - Parameter call: VSL call instance of the incoming call
    private func reportIncomingCallForNonCallKit(withCall call: VSLCall) {
        DispatchQueue.main.async { [unowned self] in
            if SIPUtils.anotherCall(inProgress: call) {
                VialerLogInfo("There is another call in progress. For now declining the call that is incoming.")
                do {
                    try call.decline()
                    VialerGAITracker.declineIncomingCallBecauseAnotherCallInProgressEvent()
                } catch let error {
                    VialerLogError("Error declining call: \(error)")
                }
            } else {
                if UIApplication.shared.applicationState == .background {
                    self.createLocalNotification(forCall: call)
                    self.startVibratingInBackground()
                } else {
                    VialerLogDebug("Call received with device in foreground. Call: \(call.callId)")
                    let notificationInfo = [VSLNotificationUserInfoCallKey: call]
                    NotificationCenter.default.post(name: Configuration.Notifications.incomingCall, object: self, userInfo: notificationInfo)
                }
            }
        }
    }

    /// Setup the endpoint if user has SIP enabled
    @objc fileprivate func updatedSIPCredentials() {
        VialerLogInfo("SIP Credentials have changed")
        if !user.sipEnabled { return }
        if !user.loggedIn { return }
            
        DispatchQueue.main.async {
            SIPUtils.setupSIPEndpoint()
            APNSHandler.shared().registerForVoIPNotifications()
            if !VialerSIPLib.callKitAvailable() {
                self.registerForLocalNotifications()
            }
        }
    }

    /// SIP was disabled, remove the endpoint
    @objc fileprivate func sipDisabledNotification() {
        VialerLogInfo("SIP has been disabled")
        DispatchQueue.main.async {
            SIPUtils.removeSIPEndpoint()
        }
    }

    /// Listen for call state change notifications
    ///
    /// If call is no longer running, we stop the vibrations and remove the local notification.
    ///
    /// - Parameter notification: Notification instance with VSLCall
    @objc fileprivate func callStateChanged(_ notification: Notification) {
        guard let call = notification.userInfo![VSLNotificationUserInfoCallKey] as? VSLCall,
            call.callState == .connecting || call.callState == .disconnected,
            let localNotification = incomingCallNotification else { return }
        if #available(iOS 10.0, *){
            center.removePendingNotificationRequests(withIdentifiers: [notification.name.rawValue]) //orp: not sure about this identifier
        } else {
            UIApplication.shared.cancelLocalNotification(localNotification)
        }
        
        
        stopVibratingInBackground()
    }

    /// Call was initiated from recents or addressbook. This will try to setup a call.
    ///
    /// - Parameter userActivity: NSUseractivity instance
    /// - Returns: success or failure of setting up call
    fileprivate func didStartCallFor(userActivity: NSUserActivity) -> Bool {
        if !VialerSIPLib.callKitAvailable() {
            return false
        }

        guard #available(iOS 10.0, *), let phoneNumber = userActivity.startCallHandle else { return false }

        // When there is no connection for VoIP or VoIP is disabled in the settings setup a connectAB call.
        if !ReachabilityHelper.instance.connectionFastEnoughForVoIP() {
            let notificationInfo = [Configuration.Notifications.connectABPhoneNumberUserInfoKey: phoneNumber]
            NotificationCenter.default.post(name: Configuration.Notifications.startConnectABCall, object: self, userInfo: notificationInfo)

            return true;
        }

        guard let account = SIPUtils.addSIPAccountToEndpoint() else {
            VialerLogError("Couldn't add account to endpoint, not setting up call to: \(phoneNumber)")
            return false
        }
        VialerGAITracker.setupOutgoingSIPCallEvent()
        vialerSIPLib.callManager.startCall(toNumber: phoneNumber, for: account) { _, error in
            if error != nil {
                VialerLogError("Error starting call through User activity. Error: \(String(describing: error))")
            }
        }
        return true
    }

    /// When the app leave foreground and the call is still ringing, we create a local notification for that call
    fileprivate func reportCallWhenAppEntersBackground() {
        guard let call = SIPUtils.getFirstActiveCall(), call.callState == .incoming else { return }
        createLocalNotification(forCall: call)
    }

    /// Create a local notification for the given call.
    ///
    /// This will give the user the possibility to answer or decline the call from within the notification.
    ///
    /// - Parameter call: VSLCall instance
    private func createLocalNotification(forCall call: VSLCall) {
        let callerName = call.callerName!
        let callerNumber = call.callerNumber!
        
        if #available(iOS 10, *) {
            let content = UNMutableNotificationContent()
            content.userInfo = [Configuration.Notifications.incomingCallIDKey: call.callId]
            content.title = NSLocalizedString("Incoming call", comment: "Incoming call")
            content.body = NSLocalizedString("Incoming call from: \(callerName) \(callerNumber)",
                comment: "Incoming call from: \(callerName) \(callerNumber)")
            content.launchImageName = "AppIcon"
            content.sound = UNNotificationSound(named:"ringtone.wav")
            content.categoryIdentifier = Configuration.Notifications.Identifiers.category
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0, repeats: false) //orp: is this trigger how we want it?
            let identifier = Configuration.Notifications.incomingCall.rawValue  //orp: Is this the intetifier we want here ????? or maybe this one: Configuration.Notifications.Identifiers.category?
            let request = UNNotificationRequest(identifier: identifier,
                                                content: content, trigger: trigger)
            //incomingCallNotification = notification //orp: UNNotification object as class var is not available to do something similar with below..cause of ios10
            center.add(request, withCompletionHandler: { (error) in
                if let error = error {
                   VialerLogError("Error on creating UNNotificationRequest: \(error)")
                }
            })
        } else {
            let notification = UILocalNotification()
            notification.userInfo = [Configuration.Notifications.incomingCallIDKey: call.callId]
            notification.alertTitle = NSLocalizedString("Incoming call", comment: "Incoming call")
            notification.alertBody = NSLocalizedString("Incoming call from: \(callerName) \(callerNumber)",
                comment: "Incoming call from: \(callerName) \(callerNumber)")
            notification.alertLaunchImage = "AppIcon"
            notification.soundName = "ringtone.wav"
            notification.category = Configuration.Notifications.Identifiers.category

            incomingCallNotification = notification

            UIApplication.shared.scheduleLocalNotification(notification)
        }
    }

    /// Handle the local notification.
    ///
    /// If the user accepted or rejected the call, the app will respond accordingly, otherwise it will show a incoming call screen
    ///
    /// - Parameters:
    ///   - identifier: String with the user action on the local notification
    ///   - callID: Int with the callID of the VSLCall
    fileprivate func handleIncomingBackgroundNotification(identifier: String?, callID: Int) {
        guard let call = vialerSIPLib.callManager.call(withCallId: callID), call.callState != .null else { return }

        let notificationInfo = [VSLNotificationUserInfoCallKey: call]
        if identifier == Configuration.Notifications.Identifiers.decline {
            // Call is declined through the button on the local notification.
            do {
                try call.decline()
                VialerGAITracker.declineIncomingCallEvent()
            } catch let error {
                VialerLogError("Error declining call: \(error)")
            }
        } else if identifier == Configuration.Notifications.Identifiers.accept {
            // Call is accepted through the button on the local notification.
            NotificationCenter.default.post(name: Configuration.Notifications.incomingCallAccepted, object: self, userInfo: notificationInfo)
        } else {
            // The local notification was just tapped, not declined, not answered.
            NotificationCenter.default.post(name: Configuration.Notifications.incomingCall, object: self, userInfo: notificationInfo)
        }
    }

    /// Create a background task that will vibrate the phone.
    private func startVibratingInBackground() {
        let application = UIApplication.shared

        stopVibrating = false
        vibratingTask = application.beginBackgroundTask {
            self.stopVibrating = true
            if let task = self.vibratingTask {
                application.endBackgroundTask(task)
            }
            self.vibratingTask = UIBackgroundTaskInvalid
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
                application.endBackgroundTask(task)
            }
            self.vibratingTask = UIBackgroundTaskInvalid
        }
    }

    /// Stop the vibrations
    fileprivate func stopVibratingInBackground() {
        stopVibrating = true
        guard let task = vibratingTask else { return }
        UIApplication.shared.endBackgroundTask(task)
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
