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
        static let inbound: String = "Inbound"
        static let outbound: String = "Outbound"

        /**
         *  Custom Dimensions that will be used for Google Analytics.
         */
        struct CustomDimensions {
            static let clientID: UInt = 1
            static let appVersion: UInt = 2
        }

        /**
         *  Categories used for Google Analytics.
         */
        struct Categories {
            static let call: String = "call"
            static let middleware: String = "middleware"
            static let metrics: String = "metrics"
        }

        /**
         *  Names use for tracking webviews.
         */
        struct TrackingNames {
            static let statisticsWebView: String = "StatisticsWebView"
            static let informationWebView: String = "InformationWebView"
            static let dialplanWebview: String = "DialplanWebview"
            static let userProfileWebView: String = "UserProfileWebView"
            static let addFixedDestinationWebView: String = "AddFixedDestinationWebView"
        }
    }

    // These constants should be turned into a Struct when the whole project is rewritten in Swift: VIALI-3255
    class func GAStatisticsWebViewTrackingName() -> String {
        return VialerGAITracker.Constants.TrackingNames.statisticsWebView
    }
    class func GAInformationWebViewTrackingName() -> String {
        return VialerGAITracker.Constants.TrackingNames.informationWebView
    }
    class func GADialplanWebViewTrackingName() -> String {
        return VialerGAITracker.Constants.TrackingNames.dialplanWebview
    }
    class func GAUserProfileWebViewTrackingName() -> String {
        return VialerGAITracker.Constants.TrackingNames.userProfileWebView
    }
    class func GAAddFixedDestinationWebViewTrackingName() -> String {
        return VialerGAITracker.Constants.TrackingNames.addFixedDestinationWebView
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

        let logLevel = GAILogLevel.info

        setupGAITracker(logLevel:logLevel, isDryRun:dryRun)
    }

    /**
     Configures the shared GA Tracker instance with the parameters provided.

     - parameter logLevel: The GA log level you want to configure the shared instance with.
     - parameter isDryRun: Boolean indicating GA to run in dry run mode or not.
     */
    static func setupGAITracker(logLevel: GAILogLevel, isDryRun: Bool) {
        var configureError: NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        if let error = configureError {
            assertionFailure("Error configuring Google Services: \(error)")
        }
        let gai = GAI.sharedInstance()
        gai?.trackUncaughtExceptions = true
        gai?.logger.logLevel = logLevel
        gai?.dryRun = isDryRun

        tracker.set(GAIFields.customDimension(for: Constants.CustomDimensions.clientID), value: AppInfo.currentAppVersion()!)
    }

    /**
     Set the client ID as a custom dimension.

     - parameter clientID: The client ID to set as custom dimension.
     */
    static func setCustomDimension(withClientID clientID:String) {
        tracker.set(GAIFields.customDimension(for: Constants.CustomDimensions.appVersion), value: clientID)
    }

    /**
     Tracks a screen with the given name.

     If the name contains "ViewController" this is removed.

     - parameter name: The name of the screen name to track.
     */
    static func trackScreenForController(name:String) {
        tracker.set(kGAIScreenName, value: name.replacingOccurrences(of: "ViewController", with: ""))
        tracker.send(GAIDictionaryBuilder.createScreenView().build() as [NSObject : AnyObject])
    }

    // MARK: - Events

    /**
     Create an Event and send it to Google Analytics.

     - parameter category: The Category of the Event
     - parameter action:   The Action of the Event
     - parameter label:    The Label of the Event
     - parameter value:    The value of the Event
     */
    static func sendEvent(withCategory category: String, action: String, label: String, value: NSNumber!) {
        let event = GAIDictionaryBuilder.createEvent(withCategory: category, action: action, label: label, value: value).build() as [NSObject : AnyObject]
        tracker.send(event)
    }

    /**
     Indication a call event is received from the SIP Proxy and the app is ringing.
     */
    static func incomingCallRingingEvent() {
        sendEvent(withCategory: Constants.Categories.call, action: Constants.inbound, label: "Ringing", value: 0)
    }

    /**
     The incoming call is accepted.
     */
    static func acceptIncomingCallEvent() {
        sendEvent(withCategory: Constants.Categories.call, action: Constants.inbound, label: "Accepted", value: 0)
    }

    /**
     The incoming call is rejected.
     */
    static func declineIncomingCallEvent() {
        sendEvent(withCategory: Constants.Categories.call, action: Constants.inbound, label: "Declined", value: 0)
    }

    /**
     The incoming call is rejected because there is another call in progress.
     */
    static func declineIncomingCallBecauseAnotherCallInProgressEvent() {
        sendEvent(withCategory: Constants.Categories.call, action: Constants.inbound, label: "Declined - Another call in progress", value: nil)
    }

    /**
     Event to track an outbound SIP call.
     */
    static func setupOutgoingSIPCallEvent() {
        sendEvent(withCategory: Constants.Categories.call, action: Constants.outbound, label: "SIP", value: nil)
    }

    /**
     Event to track an outbound ConnectAB (aka two step) call.
     */
    static func setupOutgoingConnectABCallEvent() {
        sendEvent(withCategory: Constants.Categories.call, action: Constants.outbound, label: "ConnectAB", value: nil)
    }

    /**
     Incoming VoIPPush notification was responded with available to middleware.

     - parameter connectionType: A string indicating the current connection type, as described in the "Google Analytics events for all Mobile apps" document.
     - parameter isAccepted:     Boolean indicating if we can accept the incoming VoIP call.
     */
    static func pushNotification(isAccepted: Bool, connectionType: String ) {
        let action = isAccepted ? "accepted" : "rejected"
        sendEvent(withCategory: Constants.Categories.middleware, action: action, label: connectionType, value: nil)
    }

    // MARK: - Exceptions

    /**
     Exception when the registration failed on the middleware.
     */
    static func registrationFailedWithMiddleWareException() {
        let exception = GAIDictionaryBuilder.createException(withDescription: "Failed middleware registration", withFatal: false).build() as [NSObject : AnyObject]
        tracker.send(exception)
    }

    // MARK: - Timings

    /**
     This method will log the time it took to respond to the incoming push notification and respond to the middleware.

     - parameter responseTime: NSTimeInterval with the time it took to respond.
     */
    static func respondedToIncomingPushNotification(withResponseTime responseTime: TimeInterval) {
        let timing = GAIDictionaryBuilder.createTiming(withCategory: Constants.Categories.middleware, interval: (responseTime * 1000) as NSNumber, name: "response", label: nil).build() as [NSObject : AnyObject]
        tracker.send(timing)
    }

    /**
     After a call is finished, sent call metrics to GA.

     - parameter call: the call that was finished
     */
    static func callMetrics(finishedCall call: VSLCall) {
        // Only sent call statistics when the call duration was longer than 10 seconds
        // to prevent large rounding errors.
        if (call.connectDuration > 10) {
            let mbPerMinute = call.totalMBsUsed / (Float)(call.connectDuration / 60)

            var labelString = "MOS:\(call.mos)"
            labelString += ",Bandwidth:\(mbPerMinute)"

            //VIALI-3258: get the audio codec from the call.
            labelString += ",AudioCodec:unknown"

            let dict:NSDictionary = [kGAIHitType : "event",
                                     kGAIEventCategory : Constants.Categories.metrics,
                                     kGAIEventAction : "CallMetrics",
                                     kGAIEventLabel : labelString]

            tracker.send(dict as! [AnyHashable: Any])
        }
    }
}
