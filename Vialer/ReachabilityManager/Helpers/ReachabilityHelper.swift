//
//  ReachabilityHelper.swift
//  Copyright © 2017 VoIPGRID. All rights reserved.
//

import Foundation

@objc public class ReachabilityHelper: NSObject {

    static let instance = ReachabilityHelper()

    @objc var reachability: Reachability!

    private override init () {
        reachability = Reachability(true)
        try! reachability.startNotifier()
    }

    @objc class func sharedInstance() -> ReachabilityHelper {
        return ReachabilityHelper.instance
    }

    @objc func connectionFastEnoughForVoIP() -> Bool {
        let user = SystemUser.current()!
        let reachability = ReachabilityHelper.instance.reachability!

        // If user has disabled VoIP return false.
        if !user.sipEnabled {
            VialerLogDebug("VoIP user is disabled: return false")
            return false
        }

        // Check if the user has high speed i.e. WiFI or 4G
        if reachability.hasHighSpeed {
            VialerLogDebug("Connection is 4g or WiFi: return true")
            return true
        }

        // Check if the user has 3G plus enabled in the settings and that the speed is 3G+
        if user.use3GPlus && reachability.hasHighSpeedWith3GPlus {
            VialerLogDebug("Connection is 3G+ and user has enbaled 3G+ in settings: return true")
            return true
        }

        // Default return false
        VialerLogDebug("VoIP is enabled but connection is not fast enough: return false")
        return false
    }
}
