//
//  APNSHandler.swift
//  Vialer
//
//  Created by Chris Kontos on 05/06/2019.
//  Copyright © 2019 VoIPGRID. All rights reserved.
//

import Foundation
import PushKit
import UIKit //orp

// To make the singleton pattern testable.
//var _sharedAPNSHandler: APNSHandler? = nil //orp WTF

@objc class APNSHandler: NSObject {
    
    // MARK: - Properties
    // Singleton instance of APNSHandler
    //@objc static let sharedAPNSHandler = APNSHandler() //orp
    @objc static let shared = APNSHandler(voipRegistry: <#T##PKPushRegistry#>, middleware: <#T##Middleware#>)
    
//    @objc var voipRegistry: PKPushRegistry { //orp
//        get {
//            // Nil for the queue, so that the delegate methods will be done on the main queue.
//            let voipRegistry = PKPushRegistry(queue: nil)
//            return voipRegistry
//        }
//    }
    @objc var voipRegistry: PKPushRegistry
    
//    @objc var middleware: Middleware { //orp
//        get {
//            let middleware = Middleware()
//            return middleware
//        }
//    }
    @objc var middleware: Middleware
    
    // MARK: - Lifecyrcle
    @objc init(voipRegistry: PKPushRegistry, middleware: Middleware) {
        self.voipRegistry = voipRegistry
        self.middleware = middleware
    }
    
//    private override init() {
//        super.init()
//    }
    
    // MARK: - Actions
    @objc func registerForVoIPNotifications() {
        // Only register once, if delegate is set, registration has been done before:
        if voipRegistry.delegate == nil {
            voipRegistry.delegate = self as? PKPushRegistryDelegate
            
            VialerLogVerbose("Initiating VoIP push registration")
            voipRegistry.desiredPushTypes = Set([.voIP])
        }
    }
    
    @objc class func storedAPNSToken() -> String? {
        let sharedHandler: APNSHandler? = self.shared //orp self.sharedAPNSHandler
        let token: Data? = sharedHandler?.voipRegistry.pushToken(for: .voIP)
        //return sharedHandler?.nsString(fromNSData: token) //orp
        return sharedHandler?.nsString(fromNSData: token) as String?
    }
    
    // MARK: - PKPushRegistry
    @objc func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        VialerLogWarning("APNS Token became invalid")
    }
    
    @objc func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) {
        VialerLogDebug("Incoming push notification of type: \(type)")
        middleware.handleReceivedAPSNPayload(payload.dictionaryPayload)
    }
    
    @objc func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        VialerLogInfo("Type:\(type). APNS registration successful. Token: \(credentials.token)")
        //middleware.sentAPNSToken(nsString(fromNSData: credentials.token) ?? "" as String) //orp
        middleware.sentAPNSToken(nsString(fromNSData: credentials.token) as String? ?? "" as String)
    }
    
    // MARK: - Token conversion
    /*
     * Returns hexadecimal string of NSData. Empty string if data is empty.
     * http://stackoverflow.com/questions/1305225/best-way-to-serialize-a-nsdata-into-an-hexadeximal-string
     */
    //orp there is a better and faster waY TO ACHIEVE THIS, create a ticket and follow that link
//    func nsString(fromNSData data: Data?) -> String? {
//        guard let data = data else { return "" }
//        //let dataBuffer = UInt8(data.bytes)
//        let dataBuffer = UnsafeBufferPointer<UInt8>(start: UnsafePointer(data.bytes),count: data.length)
//
////        let tempData: NSMutableData = NSMutableData(length: 26)!
////        data.withUnsafeBytes {
////            tempData.replaceBytes(in: NSMakeRange(0, data.count), withBytes: $0)
////        }
////        let dataBuffer = UnsafeBufferPointer<UInt8>(start: UnsafePointer(data),count: data.length)
//
//        if dataBuffer == nil {
//            return ""
//        }
//
//        let dataLength: Int = data.count
//        var hexString = String(repeating: "\0", count: dataLength * 2)
//
//        for i in 0..<dataLength {
//            hexString += String(format: "%02lx", UInt(dataBuffer[i]))
//        }
//        return hexString
//    }
    
    @objc func nsString(fromNSData data: Data?) -> NSString? { //no error
        guard let data = data else { return "" }
        let token = data.map { String(format: "%02.2hhx", $0 as CVarArg) }.joined()
        return NSString(utf8String: token)
    }
    
//    @objc func nsString(fromNSData data: Data?) -> String? { //no error
//        guard let data = data else { return "" }
//        let token = data.map { String(format: "%02.2hhx", $0 as CVarArg) }.joined()
//        return token
//    }
    
 
}
