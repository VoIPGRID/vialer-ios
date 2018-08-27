/*
 Copyright (c) 2014, Ashley Mills, Devhouse Spindle (2017)
 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.

 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 */

import SystemConfiguration
import Foundation
import CoreTelephony

public enum ReachabilityError: Error {
    case FailedToCreateWithAddress(sockaddr_in)
    case FailedToCreateWithHostname(String)
    case UnableToSetCallback
    case UnableToSetDispatchQueue
}

public class Reachability: NSObject {

    // MARK: - Public properties.

    public enum NetworkStatus: CustomStringConvertible {

        case notReachable
        case reachableViaWiFi
        case reachableVia2G
        case reachableVia3G
        case reachableVia3GPlus
        case reachableVia4G

        public var description: String {
            switch self {
            case .reachableVia2G: return "2G"
            case .reachableVia3G: return "3G"
            case .reachableVia3GPlus: return "3G+"
            case .reachableVia4G: return "4G"
            case .reachableViaWiFi: return "Wifi"
            case .notReachable: return "No Connection"
            }
        }
    }

    // Optional Callback.
    public typealias NetworkChanged = (Reachability) -> ()
    public var whenConnectionChanged: NetworkChanged?

    public var onWWAN: Bool
    @objc public var hasHighSpeed: Bool {
        return status == .reachableViaWiFi || status == .reachableVia4G
    }
    
    @objc public var hasHighSpeedWith3GPlus: Bool {
        return hasHighSpeed || status == .reachableVia3GPlus
    }

    @objc public var statusString: String {
        return "\(status)"
    }

    @objc public var carrierName: String? {
        var carrier = networkInfo?.subscriberCellularProvider
        if carrier == nil {
            networkInfo = CTTelephonyNetworkInfo()
            carrier = networkInfo?.subscriberCellularProvider
        }

        if carrier != nil {
            return carrier!.carrierName
        } else {
            return ""
        }
    }

    // Current internet connection type.
    public var status: NetworkStatus {
        guard isReachable else {
            return .notReachable
        }

        if isReachableViaWiFi {
            return .reachableViaWiFi
        }
        guard isRunningOnDevice else {
            return .notReachable
        }

        guard let currentRadio = radioStatus else {
            return .notReachable
        }
        return currentRadio
    }

    public var radioStatus: NetworkStatus? {
        guard let currentRadio = currentRadio else {
            return nil
        }
        if fastInternet.contains(currentRadio) {
            return .reachableVia4G
        } else if mediumFastInternet.contains(currentRadio) {
            return .reachableVia3GPlus
        } else if mediumInternet.contains(currentRadio) {
            return .reachableVia3G
        }
        return .reachableVia2G
    }

    // MARK: - Private properties.

    // NetworkInfo instance, keep reference for notifications.
    fileprivate var networkInfo: CTTelephonyNetworkInfo?

    // The notification center on which "reachability changed" events are being posted
    fileprivate let notificationCenter: NotificationCenter = NotificationCenter.default

    fileprivate var previousconnectionType: NetworkStatus?
    fileprivate var isRunningOnDevice: Bool = {
        #if targetEnvironment(simulator)
            return false
        #else
            return true
        #endif
    }()

    fileprivate var notifierRunning = false
    fileprivate var reachabilityRef: SCNetworkReachability?
    fileprivate let reachabilitySerialQueue = DispatchQueue(label: "uk.co.ashleymills.reachability")
    fileprivate var appEntersForeground: NotificationToken?
    fileprivate var radioChanged: NotificationToken?

    // MARK: - Radioquality sets.
    // 2G.
    fileprivate let slowInternet: Set<String> = [ CTRadioAccessTechnologyGPRS,
                                                  CTRadioAccessTechnologyEdge,
                                                  CTRadioAccessTechnologyCDMA1x
    ]
    // 3G.
    fileprivate let mediumInternet: Set<String> = [ CTRadioAccessTechnologyWCDMA,
                                                    CTRadioAccessTechnologyCDMAEVDORev0,
                                                    CTRadioAccessTechnologyCDMAEVDORevA,
                                                    CTRadioAccessTechnologyCDMAEVDORevB
    ]
    
    fileprivate let mediumFastInternet: Set<String> = [ CTRadioAccessTechnologyHSDPA, // 3.5  G
                                                        CTRadioAccessTechnologyHSUPA, // 3.75 G
                                                        CTRadioAccessTechnologyeHRPD, // 3    G++
    ]
    
    // 4G.
    fileprivate let fastInternet: Set<String> = [ CTRadioAccessTechnologyLTE
    ]


    // MARK: - Initializers
    required public init(reachabilityRef: SCNetworkReachability) {
        onWWAN = true
        self.reachabilityRef = reachabilityRef
        self.networkInfo = CTTelephonyNetworkInfo()
    }

    public convenience init?(hostname: String) {
        guard let ref = SCNetworkReachabilityCreateWithName(nil, hostname) else { return nil }
        self.init(reachabilityRef: ref)
    }

    public convenience init?(_: Bool) {
        var zeroAddress = sockaddr()
        zeroAddress.sa_len = UInt8(MemoryLayout<sockaddr>.size)
        zeroAddress.sa_family = sa_family_t(AF_INET)

        guard let ref: SCNetworkReachability = withUnsafePointer(to: &zeroAddress, {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
        }) else { return nil }
        self.init(reachabilityRef: ref)
    }

    deinit {
        stopNotifier()

        reachabilityRef = nil
        whenConnectionChanged = nil
    }

    override public var description: String {

        let W = isRunningOnDevice ? (isOnWWANFlagSet ? "W" : "-") : "X"
        let R = isReachableFlagSet ? "R" : "-"

        return "\(W)\(R) - \(status)"
    }
}

// MARK: - Notifier methods
public extension Reachability {


    /// Start listening to network changes.
    ///
    /// - Throws: If start listening fails.
    func startNotifier() throws {

        guard let reachabilityRef = reachabilityRef, !notifierRunning else { return }

        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        context.info = UnsafeMutableRawPointer(Unmanaged<Reachability>.passUnretained(self).toOpaque())
        if !SCNetworkReachabilitySetCallback(reachabilityRef, callback, &context) {
            stopNotifier()
            throw ReachabilityError.UnableToSetCallback
        }

        if !SCNetworkReachabilitySetDispatchQueue(reachabilityRef, reachabilitySerialQueue) {
            stopNotifier()
            throw ReachabilityError.UnableToSetDispatchQueue
        }

        // Perform an intial check
        reachabilitySerialQueue.async {
            self.reachabilityChanged()
        }

        // Listen to the Application will enter foreground to check the internet connection again.
        appEntersForeground = notificationCenter.addObserver(descriptor: Reachability.appEntersForeground) { [weak self] _ in
            self?.reachabilitySerialQueue.async {
                self?.reachabilityChanged()
            }
        }

        // When the Radio connection type changes, we need to check again.
        radioChanged = notificationCenter.addObserver(descriptor: Reachability.radioChanged) { [weak self] _ in
            self?.reachabilitySerialQueue.async {
                self?.reachabilityChanged()
            }
        }
        notifierRunning = true
    }

    /// Stop listening to network changes.
    func stopNotifier() {
        guard notifierRunning else { return }
        defer { notifierRunning = false }

        networkInfo = nil
        radioChanged = nil
        appEntersForeground = nil

        guard let reachabilityRef = reachabilityRef else { return }
        SCNetworkReachabilitySetCallback(reachabilityRef, nil, nil)
        SCNetworkReachabilitySetDispatchQueue(reachabilityRef, nil)
    }
}

// MARK: - Connection test methods
extension Reachability {

    /// Is there a network connection?
    @objc var isReachable: Bool {

        guard isReachableFlagSet else { return false }
        if isConnectionRequiredAndTransientFlagSet {
            return false
        }

        if isRunningOnDevice {
            if isOnWWANFlagSet && !onWWAN {
                // We don't want to connect when on 3G.
                return false
            }
        }
        return true
    }

    // Check we're not on the simulator, we're REACHABLE and check we're on WWAN.
    var isReachableViaWWAN: Bool {
        return isRunningOnDevice && isReachableFlagSet && isOnWWANFlagSet
    }

    var isReachableViaWiFi: Bool {

        // Check we're reachable
        guard isReachableFlagSet else { return false }

        // If reachable we're reachable, but not on an iOS device (i.e. simulator), we must be on WiFi
        guard isRunningOnDevice else { return true }

        // Check we're NOT on WWAN
        return !isOnWWANFlagSet
    }
}

fileprivate extension Reachability {

    /// Function called when notifiers pick up network changes.
    func reachabilityChanged() {

        let newReachabilityStatus = status
        guard previousconnectionType != newReachabilityStatus else { return }

        VialerLogInfo("Network changed")

        whenConnectionChanged?(self)
        notificationCenter.post(descriptor: Reachability.changed, object:self)
        previousconnectionType = newReachabilityStatus
    }
}

// MARK: - Check current connection type.
fileprivate extension Reachability {
    var isOnWWANFlagSet: Bool {
        #if os(iOS)
            return reachabilityFlags.contains(.isWWAN)
        #else
            return false
        #endif
    }
    var isReachableFlagSet: Bool {
        return reachabilityFlags.contains(.reachable)
    }
    var isConnectionRequiredAndTransientFlagSet: Bool {
        return reachabilityFlags.intersection([.connectionRequired, .transientConnection]) == [.connectionRequired, .transientConnection]
    }

    var reachabilityFlags: SCNetworkReachabilityFlags {

        guard let reachabilityRef = reachabilityRef else { return SCNetworkReachabilityFlags() }

        var flags = SCNetworkReachabilityFlags()
        let gotFlags = withUnsafeMutablePointer(to: &flags) {
            SCNetworkReachabilityGetFlags(reachabilityRef, UnsafeMutablePointer($0))
        }

        if gotFlags {
            return flags
        } else {
            return SCNetworkReachabilityFlags()
        }
    }
}

extension Reachability {
    // The current Radio access technology.
    fileprivate var currentRadio: String? {
        var currentRadio = networkInfo?.currentRadioAccessTechnology
        if currentRadio == nil {
            networkInfo = CTTelephonyNetworkInfo()
            currentRadio = networkInfo?.currentRadioAccessTechnology
        }
        if currentRadio == nil {
            return ""
        } else {
            return currentRadio!
        }
    }
}

// MARK: - Callback for SCNetworkReachability.
func callback(reachability:SCNetworkReachability, flags: SCNetworkReachabilityFlags, info: UnsafeMutableRawPointer?) {
    guard let info = info else { return }
    let reachability = Unmanaged<Reachability>.fromOpaque(info).takeUnretainedValue()
    DispatchQueue.main.async {
        reachability.reachabilityChanged()
    }
}

extension Reachability {
    static var changed = NotificationDescriptor<Any>(name: NSNotification.Name(rawValue: ReachabilityChangedNotification))
    static var appEntersForeground = NotificationDescriptor<Any>(name: Notification.Name.UIApplicationWillEnterForeground)
    static var radioChanged = NotificationDescriptor<Any>(name: Notification.Name.CTRadioAccessTechnologyDidChange)
}
