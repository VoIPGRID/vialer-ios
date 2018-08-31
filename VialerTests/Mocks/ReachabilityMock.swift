//
//  ReachabilityMock.swift
//  VialerTests
//
//  Created by Redmer Loen on 8/29/18.
//  Copyright © 2018 VoIPGRID. All rights reserved.
//

import Foundation
@testable import Vialer

class ReachabilityMock: Reachability {
    var statusToReturn: NetworkStatus = .notReachable

    override var status: NetworkStatus {
        return statusToReturn
    }
}
