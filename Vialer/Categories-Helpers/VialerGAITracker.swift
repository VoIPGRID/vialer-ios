//
//  GAITracker.swift
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

import Foundation

/// Wrapper class that makes tracking within the app easy.
@objc class VialerGAITracker: NSObject {

    /**
     *  Constants for this class.
     */
    struct Constants {
        /**
         *  Custom Dimensions that will be used for Google Analytics.
         */
        struct CustomDimensions {
            static let clientID: UInt = 1
            static let appVersion: UInt = 2
        }
    }

    struct TrackingNames {
        static let statisticsWebView: String = "StatisticsWebView"
        static let informationWebView: String = "InformationWebView"
        static let dialplanWebview: String = "DialplanWebview"
        static let userProfileWebView: String = "UserProfileWebView"
        static let addFixedDestinationWebView: String = "AddFixedDestinationWebView"
    }

    // These constants should be turned into a Struct when the whole project is rewritten in Swift: VIALI-3255
    class func GAStatisticsWebViewTrackingName() -> String {
        return VialerGAITracker.TrackingNames.statisticsWebView
    }
    class func GAInformationWebViewTrackingName() -> String {
        return VialerGAITracker.TrackingNames.informationWebView
    }
    class func GADialplanWebViewTrackingName() -> String {
        return VialerGAITracker.TrackingNames.dialplanWebview
    }
    class func GAUserProfileWebViewTrackingName() -> String {
        return VialerGAITracker.TrackingNames.userProfileWebView
    }
    class func GAAddFixedDestinationWebViewTrackingName() -> String {
        return VialerGAITracker.TrackingNames.addFixedDestinationWebView
    }

    /// The default Google Analytics Tracker.
    static var tracker: GAITracker {
        return GAI.sharedInstance().defaultTracker
    }

    // MARK: - Setup

    /**
     Configures the shared GA Tracker instance with the default info log level
     and sets dry run according to DEBUG being set or not.
     */
    static func setupGAITracker() {
        #if DEBUG
        let dryRun = true
        #else
        let dryRun = false
        #endif

        let logLevel = GAILogLevel.Info

        setupGAITracker(logLevel:logLevel, isDryRun:dryRun)
    }

    /**
     Configures the shared GA Tracker instance with the parameters provided.

     - parameter logLevel: The GA log level you want to configure the shared instance with.
     - parameter isDryRun: Boolean indicating GA to run in dry run mode or not.
     */
    static func setupGAITracker(logLevel logLevel: GAILogLevel, isDryRun: Bool) {
        var configureError: NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        if let error = configureError {
            assertionFailure("Error configuring Google Services: \(error)")
        }
        let gai = GAI.sharedInstance()
        gai.trackUncaughtExceptions = true
        gai.logger.logLevel = logLevel
        gai.dryRun = isDryRun

        tracker.set(GAIFields.customDimensionForIndex(Constants.CustomDimensions.clientID), value: AppInfo.currentAppVersion()!)
    }

    /**
     Set the client ID as a custom dimension.

     - parameter clientID: The client ID to set as custom dimension.
     */
    static func setCustomDimension(withClientID clientID:String) {
        tracker.set(GAIFields.customDimensionForIndex(Constants.CustomDimensions.appVersion), value: clientID)
    }

    /**
     Tracks a screen with the given name.

     If the name contains "ViewController" this is removed.

     - parameter name: The name of the screen name to track.
     */
    static func trackScreenForController(name name:String) {
        tracker.set(kGAIScreenName, value: name.stringByReplacingOccurrencesOfString("ViewController", withString: ""))
        tracker.send(GAIDictionaryBuilder.createScreenView().build() as [NSObject: AnyObject])
    }

    // MARK: - Events

    /**
     Create an Event and send it to Google Analytics.

     - parameter category: The Category of the Event
     - parameter action:   The Action of the Event
     - parameter label:    The Label of the Event
     - parameter value:    The value of the Event
     */
    static func sendEvent(withCategory category: String, action: String, label: String, value: NSNumber?) {
        let event = GAIDictionaryBuilder.createEventWithCategory(category, action: action, label: label, value: value).build() as [NSObject: AnyObject]
        tracker.send(event)
    }

    /**
     Indication a call event is received from the SIP Proxy and the app is ringing.
     */
    static func incomingCallRingingEvent() {
        sendEvent(withCategory: "call", action: "Inbound", label: "Ringing", value: nil)
    }

    /**
     The incoming call is accepted.
     */
    static func acceptIncomingCallEvent() {
        sendEvent(withCategory: "call", action: "Inbound", label: "Accepted", value: nil)
    }

    /**
     The incoming call is rejected.
     */
    static func declineIncomingCallEvent() {
        sendEvent(withCategory: "call", action: "Inbound", label: "Declined", value: nil)
    }

    /**
     The incoming call is rejected because there is another call in progress.
     */
    static func declineIncomingCallBecauseAnotherCallInProgressEvent() {
        sendEvent(withCategory: "call", action: "Inbound", label: "Declined - Another call in progress", value: nil)
    }

    /**
     Event to track an outbound SIP call.
     */
    static func setupOutgoingSIPCallEvent() {
        sendEvent(withCategory: "call", action: "Outbound", label: "SIP", value: nil)
    }

    /**
     Event to track an outbound ConnectAB (aka two step) call.
     */
    static func setupOutgoingConnectABCallEvent() {
        sendEvent(withCategory: "call", action: "Outbound", label: "ConnectAB", value: nil)
    }

    /**
     Incoming VoIPPush notification was responded with available to middleware.

     - parameter connectionType: A string indicating the current connection type, as described in the "Google Analytics events for all Mobile apps" document.
     - parameter isAccepted:     Boolean indicating if we can accept the incoming VoIP call.
     */
    static func pushNotification(isAccepted isAccepted: Bool, connectionType: String ) {
        let action = isAccepted ? "accepted" : "rejected"
        sendEvent(withCategory: "middleware", action: action, label: connectionType, value: nil)
    }

    // MARK: - Exceptions

    /**
     Exception when the registration failed on the middleware.
     */
    static func registrationFailedWithMiddleWareException() {
        let exception = GAIDictionaryBuilder.createExceptionWithDescription("Failed middleware registration", withFatal: false).build() as [NSObject: AnyObject]
        tracker.send(exception)
    }

    // MARK: - Timings

    /**
     This method will log the time it took to respond to the incoming push notification and respond to the middleware.

     - parameter responseTime: NSTimeInterval with the time it took to respond.
     */
    static func respondedToIncomingPushNotification(withResponseTime responseTime: NSTimeInterval) {
        let timing = GAIDictionaryBuilder.createTimingWithCategory("middleware", interval: responseTime * 1000, name: "response", label: nil).build() as [NSObject: AnyObject]
        tracker.send(timing)
    }
}
