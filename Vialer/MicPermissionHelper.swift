//
//  MicPermissionAlerter.swift
//  
//
//  Created by Chris Kontos on 07/12/2020.
//

import Foundation
import AVFoundation

@objc public class MicPermissionHelper: NSObject {

    @objc public static func createMicPermissionAlert() -> UIAlertController {
        let alertController = UIAlertController(title: NSLocalizedString("Access to microphone denied", comment: "Access to microphone denied"),
                message: NSLocalizedString("Give permission to use your microphone.\nGo to",
                        comment: "Give permission to use your microphone.\nGo to"),
                preferredStyle: .alert)

        // Call has not started because mic permission was not given. No further action is needed.
        let noAction = UIAlertAction(title: NSLocalizedString("Cancel call", comment: "Cancel call"), style: .cancel) { action in }
        
        alertController.addAction(noAction)

        // User wants to open the settings to enable microphone permission. This will restart the app.
        let settingsAction = UIAlertAction(title: NSLocalizedString("Settings", comment: "Settings"), style: .default) { action in
            UIApplication.shared.open(URL(string:UIApplication.openSettingsURLString)!)
        }
        alertController.addAction(settingsAction)

        return alertController
    }
    
    @objc public static func requestMicrophonePermission(completion: @escaping ((_ startCalling: Bool) -> Void)) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
}
