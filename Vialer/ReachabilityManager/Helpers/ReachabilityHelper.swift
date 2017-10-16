//
//  ReachabilityHelper.swift
//  Copyright © 2017 VoIPGRID. All rights reserved.
//

import Foundation

@objc class ReachabilityHelper: NSObject {

    static let instance = ReachabilityHelper()

    @objc var reachability: Reachability!

    private override init () {
        reachability = Reachability(true)
        try! reachability.startNotifier()
    }

    @objc class func sharedInstance() -> ReachabilityHelper {
        return ReachabilityHelper.instance
    }
}
 
