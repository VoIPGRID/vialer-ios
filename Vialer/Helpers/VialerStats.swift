//
//  VialerStats.swift
//  Copyright © 2018 VoIPGRID. All rights reserved.
//

import Foundation

@objc class VialerStats : NSObject {

    // The app status.
    public struct Status {
        static let production: String = "Production"
        static let beta: String = "Beta"
        static let custom: String = "Custom"
    }

    // Constants for this class
    struct VialerStatsConstants {
        static let os: String = "iOS"
        static let osVersion: String = UIDevice.current.systemVersion
        static let appVersion: String = AppInfo.currentAppVersion()!
        static let appStatus: String = AppInfo.currentAppStatus()!

        // The direction of the call
        struct Direction {
            static let inbound: String = "Inbound"
            static let outbound: String = "Outbound"
        }

        // Type of network the call was made on
        struct Network {
            static let wifi: String = "WiFi"
            static let highSpeed: String = "4G"
            static let lowSpeed: String = "3G"
            static let unknown: String = "unknown"
        }

        // Connection type of a call
        struct ConnectionType {
            static let tls: String = "TLS"
            static let tcp: String = "TCP"
            static let udp: String = "UDP"
        }

        struct APIKeys : Hashable {
            static let sipUserId: String = "sip_user_id"
            static let os: String = "os"
            static let osVersion: String = "os_version"
            static let appVersion: String = "app_version"
            static let appStatus: String = "app_status"
            static let middlewareUniqueKey: String = "middleware_unique_key"
            static let bluetoothAudio: String = "bluetooth_audio"
            static let bluetoothDevice: String = "bluetooth_device"
            static let network: String = "network"
            static let networkOperator: String = "network_operator"
            static let direction: String = "direction"
            static let connectionType: String = "connection_type"
            static let callSetupSuccessful: String = "call_setup_successful"
            static let countryCode: String = "country_code"
            static let asteriskCallId: String = "call_id"
            static let remoteLogId: String = "log_id"
            static let timeToInitialResponse = "time_to_initial_response"
            static let failedReason = "failed_reason"
            static let attempt = "attempt"
        }
    }

    @objc static let shared = VialerStats()

    @objc var middlewareUniqueKey: String = ""
    @objc var middlewareResponseTime: String = ""
    @objc var callSuccesful: String = ""

    private var defaultData: [String: String] = [:]

    private lazy var reachability: Reachability = {
        return ReachabilityHelper.instance.reachability
    }()

    private lazy var middlewareRequestOperationManager: MiddlewareRequestOperationManager = {
        return MiddlewareRequestOperationManager(baseURLasString: Configuration.default().url(forKey: ConfigurationMiddleWareBaseURLString))!
    }()

    private override init() {
        // Set the default for the dictionary, OS, OS version, app version and what type of release
        defaultData = [
            VialerStatsConstants.APIKeys.sipUserId: SystemUser.current().sipAccount,
            VialerStatsConstants.APIKeys.os: "iOS",
            VialerStatsConstants.APIKeys.osVersion: VialerStatsConstants.osVersion,
            VialerStatsConstants.APIKeys.appVersion: VialerStatsConstants.appVersion,
            VialerStatsConstants.APIKeys.appStatus: VialerStatsConstants.appStatus,
            ] as [String : String]
    }

    @objc func incomingCallSuccess(_ call: VSLCall) {
        guard !VialerStats.shared.middlewareUniqueKey.isEmpty else {
            return
        }

        defaultData[VialerStatsConstants.APIKeys.middlewareUniqueKey] = VialerStats.shared.middlewareUniqueKey
        if reachability.status == .reachableVia4G {
            defaultData[VialerStatsConstants.APIKeys.network] = VialerStatsConstants.Network.highSpeed
            defaultData[VialerStatsConstants.APIKeys.networkOperator] = reachability.carrierName
        } else if reachability.status == .reachableVia3GPlus || reachability.status == .reachableVia3G {
            defaultData[VialerStatsConstants.APIKeys.network] = VialerStatsConstants.Network.lowSpeed
            defaultData[VialerStatsConstants.APIKeys.networkOperator] = reachability.carrierName
        } else if reachability.status == .reachableViaWiFi {
            defaultData[VialerStatsConstants.APIKeys.network] = VialerStatsConstants.Network.wifi
        }

        defaultData[VialerStatsConstants.APIKeys.direction] = VialerStatsConstants.Direction.inbound

        if VialerLogger.remoteLoggingEnabled() {
            defaultData[VialerStatsConstants.APIKeys.remoteLogId] = VialerLogger.remoteIdentifier()
        }

        if VialerSIPLib.sharedInstance().hasTLSTransport {
            defaultData[VialerStatsConstants.APIKeys.connectionType] = VialerStatsConstants.ConnectionType.tls
        } else {
            defaultData[VialerStatsConstants.APIKeys.connectionType] = VialerStatsConstants.ConnectionType.tcp
        }

        defaultData[VialerStatsConstants.APIKeys.callSetupSuccessful] = "true"

        sendMetrics()
    }

    // Send the metrics to the middleware
    private func sendMetrics() {
        middlewareRequestOperationManager.sendMetrics(toMiddleware: defaultData) { (error) in
            if (error != nil) {
                VialerLogDebug("Error sending stats to the middleware: \(String(describing: error))")
            }
        }
    }
    
}
