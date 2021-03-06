/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information

	Abstract:
	Intents handler principal class

        Copied from Speakerbox example app.
 */

import Intents

class IntentHandler: INExtension, INStartAudioCallIntentHandling {

    func handle(intent: INStartAudioCallIntent, completion: @escaping (INStartAudioCallIntentResponse) -> Void) {
        let response: INStartAudioCallIntentResponse
    
        // Ensure there is a person handle.
        guard intent.contacts?.first?.personHandle != nil else {
            response = INStartAudioCallIntentResponse(code: .failure, userActivity: nil)
            completion(response)
            return
        }

        let userActivity = NSUserActivity(activityType: String(describing: INStartAudioCallIntent.self))

        response = INStartAudioCallIntentResponse(code: .continueInApp, userActivity: userActivity)
        completion(response)
    }

}
