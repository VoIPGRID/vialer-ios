//
//  MiddlewareApi.swift
//  Copyright © 2018 VoIPGRID. All rights reserved.
//

import Foundation

class MiddlewareApi {

}

extension MiddlewareApi {
    static let updateResource = Resource<[JSONDictionary]>(path: "/api/apns-device/", parseJSON: { json in
        guard let dictionaries = json["objects"] as? [JSONDictionary] else { return nil }
        return dictionaries
    })
}

extension MiddlewareApi {

//    // user id used as primary key of the SIP account registered with the currently logged in user.
//    MiddlewareResponseKeySIPUserId: sipAccount,
//
//    // token used to send notifications to this device.
//    MiddlewareResponseKeyToken: apnsToken,
//
//    // The bundle Id of this app, to allow middleware to distinguish between apps
//    MiddlewareResponseKeyApp: [infoDict objectForKey:MiddlewareMainBundleCFBundleIdentifier],
//
//    // Pretty name for a device in middleware.
//    @"name": [[UIDevice currentDevice] name],
//
//    // The version of the OS of this phone. Useful when debugging possible issues in the future.
//    @"os_version": [NSString stringWithFormat:@"iOS %@", [UIDevice currentDevice].systemVersion],
//
//    // The version of this client app. Useful when debugging possible issues in the future.
//    @"client_version": [NSString stringWithFormat:@"%@ (%@)", [infoDict objectForKey:MiddlewareMainBundleCFBundleShortVersionString], [infoDict objectForKey:MiddlewareMainBundleCFBundleVersion]],
//
//    //Sandbox is determined by the provisioning profile used on build, not on a build configuration.
//    //So, this is not the best way of detecting a Sandbox token or not.
//    //If this turns out to be unworkable, have a look at:
//    //https://github.com/blindsightcorp/BSMobileProvision
//    #if SANDBOX_APNS_TOKEN
//    @"sandbox" : [NSNumber numberWithBool:YES]
//    #endif
//};
    @objc static func update(apnsToken: String, sipAccount: String) -> Resource<[JSONDictionary]>? {
        guard let appIdentifier = AppInfo.appIdentifier() else {
            return nil
        }
        guard let appVersion = AppInfo.currentAppVersion() else {
            return nil
        }

        var resource = MiddlewareApi.updateResource
        resource.add(parameters: [
            "sip_user_id": sipAccount,
            "token": apnsToken,
            "app": appIdentifier,
            "name": UIDevice.current.name,
            "os_version": "iOS \(UIDevice.current.systemVersion)",
            "client_version": appVersion,
        ])
        #if SANDBOX_APNS_TOKEN
        resource.add(parameter: ["sandbox": true])
        #endif

        return resource
    }
}
