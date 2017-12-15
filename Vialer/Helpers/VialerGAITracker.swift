//
//  GAITracker.swift
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

import Foundation

/// Wrapper class that makes tracking within the app easy.
class VialerGAITracker: NSObject {

    /**
     Constants for this class.
     */
    struct GAIConstants {
        static let inbound: String = "Inbound"
        static let outbound: String = "Outbound"

        /**
         Custom Dimensions that will be used for Google Analytics.
         VIALI-3274: index of the dimension should be read from Config.plist.
         */
        struct CustomDimensions {
            static let clientID: UInt = 1
            static let build: UInt = 2
        }

        /**
         Categories used for Google Analytics.
         */
        struct Categories {
            static let call: String = "Call"
            static let middleware: String = "Middleware"
            static let metrics: String = "Metrics"
        }

        /**
         Actions used for Google Analytics.
         */
        struct Actions {
            static let callMetrics: String = "CallMetrics"
        }

        /**
         Names use for tracking webviews.
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
    @objc class func GAStatisticsWebViewTrackingName() -> String {
        return VialerGAITracker.GAIConstants.TrackingNames.statisticsWebView
    }
    @objc class func GAInformationWebViewTrackingName() -> String {
        return VialerGAITracker.GAIConstants.TrackingNames.informationWebView
    }
    @objc class func GADialplanWebViewTrackingName() -> String {
        return VialerGAITracker.GAIConstants.TrackingNames.dialplanWebview
    }
    @objc class func GAUserProfileWebViewTrackingName() -> String {
        return VialerGAITracker.GAIConstants.TrackingNames.userProfileWebView
    }
    @objc class func GAAddFixedDestinationWebViewTrackingName() -> String {
        return VialerGAITracker.GAIConstants.TrackingNames.addFixedDestinationWebView
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
    @objc static func setupGAITracker() {
        #if DEBUG
            let dryRun = false
            let logLevel = GAILogLevel.warning
        #else
            let dryRun = false
            let logLevel = GAILogLevel.warning
        #endif

        _ = setupGAITracker(logLevel:logLevel, isDryRun:dryRun)
    }

    /**
     Configures the shared GA Tracker instance with the parameters provided.

     - parameter logLevel: The GA log level you want to configure the shared instance with.
     - parameter isDryRun: Boolean indicating GA to run in dry run mode or not.
     */
    @objc static func setupGAITracker(logLevel: GAILogLevel, isDryRun: Bool) -> Bool {
        guard let gai = GAI.sharedInstance() else {
            assert(false, "Google Analytics not configured correctly")
            return false
        }
        gai.tracker(withTrackingId: Configuration.default().googleTrackingId());
        gai.trackUncaughtExceptions = true
        gai.logger.logLevel = logLevel
        gai.dryRun = isDryRun

        tracker.set(GAIFields.customDimension(for: GAIConstants.CustomDimensions.build), value: AppInfo.currentAppVersion()!)
        return true
    }

    /**
     Set the client ID as a custom dimension.

     - parameter clientID: The client ID to set as custom dimension.
     */
    static func setCustomDimension(withClientID clientID:String) {
        tracker.set(GAIFields.customDimension(for: GAIConstants.CustomDimensions.clientID), value: clientID)
    }

    /**
     Tracks a screen with the given name.

     If the name contains "ViewController" this is removed.

     - parameter name: The name of the screen name to track.
     */
    @objc static func trackScreenForController(name:String) {
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
    @objc static func incomingCallRingingEvent() {
        sendEvent(withCategory: GAIConstants.Categories.call, action: GAIConstants.inbound, label: "Ringing", value: 0)
    }

    /**
     The incoming call is accepted.
     */
    @objc static func acceptIncomingCallEvent() {
        sendEvent(withCategory: GAIConstants.Categories.call, action: GAIConstants.inbound, label: "Accepted", value: 0)
    }

    /**
     The incoming call is rejected.
     */
    @objc static func declineIncomingCallEvent() {
        sendEvent(withCategory: GAIConstants.Categories.call, action: GAIConstants.inbound, label: "Declined", value: 0)
    }

    static func missedIncomingCallCompletedElsewhereEvent() {
        sendEvent(withCategory: GAIConstants.Categories.call, action: GAIConstants.inbound, label: "Missed - Call completed elsewhere", value: 0)
    }

    static func missedIncomingCallOriginatorCancelledEvent() {
        sendEvent(withCategory: GAIConstants.Categories.call, action: GAIConstants.inbound, label: "Missed - Originator cancel", value: 0)
    }

    /**
     The incoming call is rejected because there is another call in progress.
     */
    static func declineIncomingCallBecauseAnotherCallInProgressEvent() {
        sendEvent(withCategory: GAIConstants.Categories.call, action: GAIConstants.inbound, label: "Declined - Another call in progress", value: nil)
    }

    /**
     Event to track an outbound SIP call.
     */
    @objc static func setupOutgoingSIPCallEvent() {
        sendEvent(withCategory: GAIConstants.Categories.call, action: GAIConstants.outbound, label: "SIP", value: nil)
    }

    /**
     Event to track an outbound ConnectAB (aka two step) call.
     */
    @objc static func setupOutgoingConnectABCallEvent() {
        sendEvent(withCategory: GAIConstants.Categories.call, action: GAIConstants.outbound, label: "ConnectAB", value: nil)
    }

    /**
     Incoming VoIPPush notification was responded with available to middleware.

     - parameter connectionType: A string indicating the current connection type, as described in the "Google Analytics events for all Mobile apps" document.
     - parameter isAccepted:     Boolean indicating if we can accept the incoming VoIP call.
     */
    @objc static func pushNotification(isAccepted: Bool, connectionType: String ) {
        let action = isAccepted ? "Accepted" : "Rejected"
        sendEvent(withCategory: GAIConstants.Categories.middleware, action: action, label: connectionType, value: nil)
    }

    /**
     Event to be sent when a call tranfer was successfull.
     */
    static func callTranferEvent(withSuccess success:Bool) {
        let labelString = success ? "Success" : "Fail";
        sendEvent(withCategory: GAIConstants.Categories.call, action: "Transfer", label: labelString, value: nil)
    }

    // MARK: - Exceptions

    /**
     Exception when the registration failed on the middleware.
     */
    @objc static func registrationFailedWithMiddleWareException() {
        let exception = GAIDictionaryBuilder.createException(withDescription: "Failed middleware registration", withFatal: false).build() as [NSObject : AnyObject]
        tracker.send(exception)
    }

    // MARK: - Timings

    /**
     This method will log the time it took to respond to the incoming push notification and respond to the middleware.

     - parameter responseTime: NSTimeInterval with the time it took to respond.
     */
    @objc static func respondedToIncomingPushNotification(withResponseTime responseTime: TimeInterval) {
        let timing = GAIDictionaryBuilder.createTiming(withCategory: GAIConstants.Categories.metrics,
                                                       interval: Int(round(responseTime * 1000)) as NSInteger as NSNumber,
                                                       name: GAIConstants.Categories.middleware,
                                                       label: "Response Time")
            .build() as [NSObject : AnyObject]
        tracker.send(timing)
    }

    // MARK: - After call Metrics

    /**
     After a call is finished, sent call metrics to GA.

     - parameter call: the call that was finished
     */
    @objc static func callMetrics(finishedCall call: VSLCall) {
        // Only sent call statistics when the call duration was longer than 10 seconds
        // to prevent large rounding errors.
        guard call.connectDuration > 10 else {
            VialerLogInfo("Not sending metrics")
            return
        }
        VialerLogInfo("Sending metrics")
        let audioCodec = "AudioCodec:\(call.activeCodec)"
        sendMOSValue(call: call, forCodec: audioCodec)
        sendBandwidth(call: call, forCodec: audioCodec)
    }

    /**
     Helper function for sending the MOS value for a call.

     - parameter call: The call
     - parameter codec: The Codec used for the call
     */
    private static func sendMOSValue(call: VSLCall, forCodec codec:String) {
        // Get the current connection type for the call.
        let reachability = ReachabilityHelper.instance.reachability!

        let labelString = "MOS for \(codec) on Networktype: \(reachability.status)"
        let value = Int(call.mos * 100.0) as NSNumber

        sendEvent(withCategory: GAIConstants.Categories.metrics, action: GAIConstants.Actions.callMetrics, label: labelString, value: value)
    }

    /**
     Helper function for sending the Bandwidth used for a call.

     - parameter call: The call
     - parameter codec: The Codec used for the call
     */
    private static func sendBandwidth(call: VSLCall, forCodec codec:String) {
        let mbPerMinute = call.totalMBsUsed / (Float)(call.connectDuration / 60)
        let value = Int(mbPerMinute * 1024.0) as NSNumber
        let labelString = "Bandwidth for \(codec)"

        sendEvent(withCategory: GAIConstants.Categories.metrics, action: GAIConstants.Actions.callMetrics, label: labelString, value: value)
    }
}
