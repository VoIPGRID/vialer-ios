//
//  SynchronousSipRegistration.swift
//  Vialer
//
//  Created by Jeremy Norman on 08/04/2020.
//  Copyright © 2020 VoIPGRID. All rights reserved.
//

import Foundation
import PushKit

class VoipTaskSynchronizer {

    /**
        Wait for a given condition or until a certain timeout has been reached.
    */
    public static func wait(timeoutInMilliseconds: Int = 10000, until: () -> Bool) -> Bool {
        let TIMEOUT_MILLISECONDS = timeoutInMilliseconds
        let MILLISECONDS_BETWEEN_ITERATION = 5
        var millisecondsTrying = 0

        while (!until() && millisecondsTrying < TIMEOUT_MILLISECONDS) {
            millisecondsTrying += MILLISECONDS_BETWEEN_ITERATION
            usleep(useconds_t(MILLISECONDS_BETWEEN_ITERATION * 1000))
        }

        return until()
    }
}
