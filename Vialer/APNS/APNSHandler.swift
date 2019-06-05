//
//  APNSHandler.swift
//  Vialer
//
//  Created by Chris Kontos on 05/06/2019.
//  Copyright © 2019 VoIPGRID. All rights reserved.
//

import Foundation

// To make the singleton pattern testable.
var _sharedAPNSHandler: APNSHandler? = nil

class APNSHandler {
    
    private var voipRegistry: PKPushRegistry?
    private var middleware: Middleware?


}
