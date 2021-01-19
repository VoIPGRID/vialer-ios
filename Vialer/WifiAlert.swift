//
//  WifiAlert.swift
//  Vialer
//
//  Created by Chris Kontos on 19/01/2021.
//  Copyright © 2021 VoIPGRID. All rights reserved.
//

import Foundation

@objc public class WifiAlert: NSObject {
    
    @objc public static func shouldBePresented(result: @escaping ((_ startCalling: Bool) -> Void)) {
        let reachability = ReachabilityHelper.instance.reachability!
        guard let currentUser = SystemUser.current() else {
            result(false)
            return
        }
        
        result(currentUser.showWiFiNotification && reachability.status == .reachableViaWiFi && reachability.radioStatus == .reachableVia4G)
    }
    
    /**
     Create alert if the user is on WiFi and has 4G connection.
     Optional parameters: The blocks to be executed for each action. 
     */
    @objc public static func create(onContinue: (() -> ())? = nil, onCancelCall: (() -> ())? = nil) -> UIAlertController {
        let alertController = UIAlertController(title: NSLocalizedString("Tip: Disable WiFi for better audio", comment: "Tip: Disable WiFi for better audio"),
                                                message: NSLocalizedString("With mobile internet (4G) you get a more stable connection and that should improve the audio quality.\n\n To disable WiFi go to Settings -> WiFi and disable WiFi.",
                                                                           comment: "With mobile internet (4G) you get a more stable connection and that should improve the audio quality.\n\n Disable Wifi? To disable WiFi go to Settings -> WiFi and disable WiFi."),
                                                preferredStyle: .alert)
        
        // User wants to use the WiFi connection.
        let continueAction = UIAlertAction(title: NSLocalizedString("Continue calling", comment: "Continue calling"), style: .default) { action in
            (onContinue ?? {})()
        }
        alertController.addAction(continueAction)
        
        // Add option to cancel the call.
        let cancelCall = UIAlertAction(title: NSLocalizedString("Cancel call", comment: "Cancel call"), style: .default) { action in
            (onCancelCall ?? {})()
        }
        alertController.addAction(cancelCall)
        
        return alertController
    }
}
