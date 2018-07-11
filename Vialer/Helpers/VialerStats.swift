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

        struct NoAudioReason {
            static let audioReceiving: String = "AUDIO_RX"
            static let audioTransmitting: String = "AUDIO_TX"
            static let audioBothDirections: String = "AUDIO_RX_TX"
        }

        struct HangupReason {
            static let userHangup: String = "user"
            static let remoteHangup: String = "remote"
        }
        
        struct BluetoothAudio {
            static let enabled: String = "yes"
            static let disabled: String = "no"
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
            static let timeToInitialResponse: String = "time_to_initial_response"
            static let failedReason: String = "failed_reason"
            static let attempt: String = "attempt"
            static let callDuration: String = "call_duration"
            static let hangupReason: String = "hangup_reason"
        }
    }

    @objc static let sharedInstance = VialerStats()
    
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
        super.init()
        initDefaultData()
    }

    private func initDefaultData() {
        // Set the default for the dictionary, OS, OS version, app version and what type of release
        defaultData = [
            VialerStatsConstants.APIKeys.sipUserId: SystemUser.current().sipAccount,
            VialerStatsConstants.APIKeys.os: "iOS",
            VialerStatsConstants.APIKeys.osVersion: VialerStatsConstants.osVersion,
            VialerStatsConstants.APIKeys.appVersion: VialerStatsConstants.appVersion,
            VialerStatsConstants.APIKeys.appStatus: VialerStatsConstants.appStatus,
        ] as [String : String]
    }
    
    private func setNetworkData(){
        // Set the network_operator, network for the dictionary
        if reachability.status == .reachableVia4G {
            defaultData[VialerStatsConstants.APIKeys.network] = VialerStatsConstants.Network.highSpeed
            defaultData[VialerStatsConstants.APIKeys.networkOperator] = reachability.carrierName
        } else if reachability.status == .reachableVia3GPlus || reachability.status == .reachableVia3G {
            defaultData[VialerStatsConstants.APIKeys.network] = VialerStatsConstants.Network.lowSpeed
            defaultData[VialerStatsConstants.APIKeys.networkOperator] = reachability.carrierName
        } else if reachability.status == .reachableViaWiFi {
            defaultData[VialerStatsConstants.APIKeys.network] = VialerStatsConstants.Network.wifi
        }
    }

    private func setTransportData() {
        if VialerSIPLib.sharedInstance().hasTLSTransport {
            defaultData[VialerStatsConstants.APIKeys.connectionType] = VialerStatsConstants.ConnectionType.tls
        } else {
            defaultData[VialerStatsConstants.APIKeys.connectionType] = VialerStatsConstants.ConnectionType.tcp
        }
    }

    private func setCallDirection(_ incoming: Bool) {
        if incoming {
            defaultData[VialerStatsConstants.APIKeys.direction] = VialerStatsConstants.Direction.inbound
        } else {
            defaultData[VialerStatsConstants.APIKeys.direction] = VialerStatsConstants.Direction.outbound
        }
    }
    
    private func setBluetoothAudioDeviceAndState() {
        // Set the bluetooth device state and name only in case it is a bluetooth audio device with both input and output
        let currentRoute = AVAudioSession.sharedInstance().currentRoute

        if currentRoute.outputs.count != 0 {
            for output in currentRoute.outputs{
                if output.portType == AVAudioSessionPortBluetoothHFP {  // it is a bluetooth audio device with both input and output
                    defaultData[VialerStatsConstants.APIKeys.bluetoothDevice] = output.portName
                    defaultData[VialerStatsConstants.APIKeys.bluetoothAudio] = VialerStatsConstants.BluetoothAudio.enabled
                }
            }
        } else {
            defaultData[VialerStatsConstants.APIKeys.bluetoothDevice] = "no_bluetooth_headset_used"
            defaultData[VialerStatsConstants.APIKeys.bluetoothAudio] = VialerStatsConstants.BluetoothAudio.disabled
        }
    }

    @objc func callSuccess(_ call: VSLCall) {
        initDefaultData()
        setBluetoothAudioDeviceAndState()

        if call.isIncoming {
            guard !VialerStats.sharedInstance.middlewareUniqueKey.isEmpty else {
                return
            }
            defaultData[VialerStatsConstants.APIKeys.middlewareUniqueKey] = VialerStats.sharedInstance.middlewareUniqueKey
        }
        setNetworkData()
        setTransportData()
        setCallDirection(call.isIncoming)
        
        defaultData[VialerStatsConstants.APIKeys.asteriskCallId] = call.messageCallId

        defaultData[VialerStatsConstants.APIKeys.callSetupSuccessful] = "true"

        sendMetrics()
    }
    
    @objc func incomingCallFailedAfterEightPushNotifications(timeToInitialReport: Double){
        initDefaultData()
        setBluetoothAudioDeviceAndState()
        
        guard !VialerStats.sharedInstance.middlewareUniqueKey.isEmpty else {
            return
        }
        defaultData[VialerStatsConstants.APIKeys.middlewareUniqueKey] = VialerStats.sharedInstance.middlewareUniqueKey
        
        setNetworkData()
        setTransportData()
        setCallDirection(true)

        defaultData[VialerStatsConstants.APIKeys.callSetupSuccessful] = "false"
        defaultData[VialerStatsConstants.APIKeys.failedReason] = "INSUFFICIENT_NETWORK"
        defaultData[VialerStatsConstants.APIKeys.timeToInitialResponse] = String(timeToInitialReport)
        
        sendMetrics()
    }
    
    @objc func incomingCallFailedOriginatorCanceled(call: VSLCall){
        initDefaultData()
        setBluetoothAudioDeviceAndState()
        
        guard !VialerStats.sharedInstance.middlewareUniqueKey.isEmpty else {
            return
        }
        defaultData[VialerStatsConstants.APIKeys.middlewareUniqueKey] = VialerStats.sharedInstance.middlewareUniqueKey
        
        self.setNetworkData()
        setTransportData()
        self.setCallDirection(true)
        
        defaultData[VialerStatsConstants.APIKeys.callSetupSuccessful] = "false"
        defaultData[VialerStatsConstants.APIKeys.failedReason] = "ORIGINATOR_CANCELED"
        defaultData[VialerStatsConstants.APIKeys.asteriskCallId] = call.messageCallId
        
        sendMetrics()
    }
    
    @objc func incomingCallFailedCallCompletedElsewhere(){
        guard !VialerStats.shared.middlewareUniqueKey.isEmpty else {
            return
        }
        self.setNetworkDataAndUniqueKey()
        
        defaultData[VialerStatsConstants.APIKeys.direction] = VialerStatsConstants.Direction.inbound
        defaultData[VialerStatsConstants.APIKeys.callSetupSuccessful] = "false"
        defaultData[VialerStatsConstants.APIKeys.failedReason] = "CALL_COMPLETED_ELSEWHERE"
        defaultData.removeValue(forKey: VialerStatsConstants.APIKeys.attempt)
        
        sendMetrics()
    }

    @objc func logStatementForReceivedPushNotification(attempt: Int){
        initDefaultData()

        guard !VialerStats.sharedInstance.middlewareUniqueKey.isEmpty else {
            return
        }
        defaultData[VialerStatsConstants.APIKeys.middlewareUniqueKey] = VialerStats.sharedInstance.middlewareUniqueKey

        setNetworkData()
        
        defaultData[VialerStatsConstants.APIKeys.attempt] = String(attempt)
        
        sendMetrics()
    }
    
    @objc func callFailedNoAudio(_ call: VSLCall) {
        initDefaultData()
        setBluetoothAudioDeviceAndState()

        if call.isIncoming {
            guard !VialerStats.sharedInstance.middlewareUniqueKey.isEmpty else {
                return
            }
            defaultData[VialerStatsConstants.APIKeys.middlewareUniqueKey] = VialerStats.sharedInstance.middlewareUniqueKey
        }
        setNetworkData()
        setTransportData()
        setCallDirection(call.isIncoming)

        defaultData[VialerStatsConstants.APIKeys.callSetupSuccessful] = "false"
        defaultData[VialerStatsConstants.APIKeys.asteriskCallId] = call.messageCallId

        switch call.callAudioState {
            case .noAudioReceiving:
                defaultData[VialerStatsConstants.APIKeys.failedReason] = VialerStatsConstants.NoAudioReason.audioReceiving
            case .noAudioTransmitting:
                defaultData[VialerStatsConstants.APIKeys.failedReason] = VialerStatsConstants.NoAudioReason.audioTransmitting
            case .noAudioBothDirections:
                defaultData[VialerStatsConstants.APIKeys.failedReason] = VialerStatsConstants.NoAudioReason.audioBothDirections
            case .OK: break
        }

        sendMetrics()
    }

    @objc func callHangupReason(_ call: VSLCall) {
        initDefaultData()
        setBluetoothAudioDeviceAndState()
        setNetworkData()
        setTransportData()

        if call.userDidHangUp {
            defaultData[VialerStatsConstants.APIKeys.hangupReason] = VialerStatsConstants.HangupReason.userHangup
        } else {
            defaultData[VialerStatsConstants.APIKeys.hangupReason] = VialerStatsConstants.HangupReason.remoteHangup
        }

        defaultData[VialerStatsConstants.APIKeys.callDuration] = String(format: "\(call.connectDuration)")
        defaultData[VialerStatsConstants.APIKeys.asteriskCallId] = call.messageCallId

        sendMetrics()
    }

    // Send the metrics to the middleware
    private func sendMetrics() {
        // Add the remote logging id to the data if it is present
        if VialerLogger.remoteLoggingEnabled() {
            defaultData[VialerStatsConstants.APIKeys.remoteLogId] = VialerLogger.remoteIdentifier()
        }
        
        middlewareRequestOperationManager.sendMetrics(toMiddleware: defaultData) { (error) in
            if (error != nil) {
                VialerLogDebug("Error sending stats to the middleware: \(String(describing: error))")
            }
        }
    }

}
