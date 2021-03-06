//
//  VialerStats.swift
//  Copyright © 2018 VoIPGRID. All rights reserved.
//

import Foundation
import AVFoundation

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
            static let incoming: String = "incoming"
            static let outgoing: String = "outgoing"
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

        struct FailedReason {
            static let noCallAfterRegistration = "OK_MIDDLEWARE_NO_CALL"
            static let declined: String = "DECLINED"
            static let insufficientNetwork: String = "INSUFFICIENT_NETWORK"
            static let completedElsewhere: String = "CALL_COMPLETED_ELSEWHERE"
            static let originatorCanceled: String = "ORIGINATOR_CANCELED"
            static let anotherCallInProgress: String = "DECLINED_ANOTHER_CALL_IN_PROGRESS"
        }

        struct APIKeys : Hashable {
            static let sipUserId: String = "sip_user_id"
            static let os: String = "os"
            static let osVersion: String = "os_version"
            static let deviceManufacturer = "device_manufacturer"
            static let deviceModel = "device_model"
            static let appVersion: String = "app_version"
            static let appStatus: String = "app_status"
            static let middlewareUniqueKey: String = "middleware_unique_key"
            static let bluetoothAudio: String = "bluetooth_audio"
            static let bluetoothDevice: String = "bluetooth_device"
            static let network: String = "network"
            static let networkOperator: String = "network_operator"
            static let direction: String = "direction"
            static let connectionType: String = "connection_type"
            static let accountConnectionType: String = "account_connection_type"
            static let callSetupSuccessful: String = "call_setup_successful"
            static let clientCountry: String = "client_country"
            static let asteriskCallId: String = "call_id"
            static let remoteLogId: String = "log_id"
            static let timeToInitialResponse: String = "time_to_initial_response"
            static let failedReason: String = "failed_reason"
            static let attempt: String = "attempt"
            static let callDuration: String = "call_duration"
            static let hangupReason: String = "hangup_reason"
            static let codec: String = "codec"
            static let mos: String = "mos"
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
        return MiddlewareRequestOperationManager(baseURLasString: UrlsConfiguration.shared.middlewareBaseUrl())!
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
            VialerStatsConstants.APIKeys.deviceManufacturer: "Apple",
            VialerStatsConstants.APIKeys.deviceModel: UIDevice.current.modelName.replacingOccurrences(of: UIDevice.current.model, with: ""),
            VialerStatsConstants.APIKeys.osVersion: VialerStatsConstants.osVersion,
            VialerStatsConstants.APIKeys.appVersion: VialerStatsConstants.appVersion,
            VialerStatsConstants.APIKeys.appStatus: VialerStatsConstants.appStatus,
        ] as! [String : String]
    }
    
    private func setNetworkData(){
        // Set the network_operator, network for the dictionary
        if reachability.status == .reachableVia4G {
            defaultData[VialerStatsConstants.APIKeys.network] = VialerStatsConstants.Network.highSpeed
            defaultData[VialerStatsConstants.APIKeys.networkOperator] = reachability.carrierName
        } else if reachability.status == .reachableVia3G {
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

        if SystemUser.current().useTLS && SystemUser.current().sipUseEncryption {
            defaultData[VialerStatsConstants.APIKeys.accountConnectionType] = VialerStatsConstants.ConnectionType.tls
        } else {
            defaultData[VialerStatsConstants.APIKeys.accountConnectionType] = VialerStatsConstants.ConnectionType.tcp
        }
    }

    private func setCallDirection(_ incoming: Bool) {
        if incoming {
            defaultData[VialerStatsConstants.APIKeys.direction] = VialerStatsConstants.Direction.incoming
        } else {
            defaultData[VialerStatsConstants.APIKeys.direction] = VialerStatsConstants.Direction.outgoing
        }
    }
    
    private func setCallInformation(_ call: VSLCall) {
        if (call.mos > 0.0) {
            defaultData[VialerStatsConstants.APIKeys.mos] = call.mos.description;
        }
        
        if (!call.activeCodec.isEmpty) {
            defaultData[VialerStatsConstants.APIKeys.codec] = call.activeCodec;
        }
    }
    
    private func setMiddlewareData(){
        guard !VialerStats.sharedInstance.middlewareUniqueKey.isEmpty else {
            return
        }
        defaultData[VialerStatsConstants.APIKeys.middlewareUniqueKey] = VialerStats.sharedInstance.middlewareUniqueKey

        guard !VialerStats.sharedInstance.middlewareResponseTime.isEmpty else {
            return
        }
        defaultData[VialerStatsConstants.APIKeys.timeToInitialResponse] = VialerStats.sharedInstance.middlewareResponseTime
    }
    
    private func setBluetoothAudioDeviceAndState() {
        // Set the bluetooth device state and name only in case it is a bluetooth audio device with both input and output
        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        defaultData[VialerStatsConstants.APIKeys.bluetoothAudio] = VialerStatsConstants.BluetoothAudio.disabled
        if currentRoute.outputs.count != 0 {
            for output in currentRoute.outputs{
                if output.portType.rawValue == AVAudioSession.Port.bluetoothHFP.rawValue {
                    defaultData[VialerStatsConstants.APIKeys.bluetoothDevice] = output.portName
                    defaultData[VialerStatsConstants.APIKeys.bluetoothAudio] = VialerStatsConstants.BluetoothAudio.enabled
                }
            }
        }
    }

    @objc func callSuccess(_ call: VSLCall) {
        initDefaultData()
        setBluetoothAudioDeviceAndState()

        if call.isIncoming {
            setMiddlewareData()
        }
        setNetworkData()
        setTransportData()
        setCallDirection(call.isIncoming)
        setCallInformation(call)
        
        defaultData[VialerStatsConstants.APIKeys.asteriskCallId] = call.messageCallId
        defaultData[VialerStatsConstants.APIKeys.clientCountry] = SystemUser.current().country
        defaultData[VialerStatsConstants.APIKeys.callSetupSuccessful] = "true"

        sendMetrics()
    }
    
    @objc func incomingCallFailedAfterEightPushNotifications() {
        initDefaultData()
        setBluetoothAudioDeviceAndState()
        
        setMiddlewareData()
        setNetworkData()
        setTransportData()
        setCallDirection(true)

        defaultData[VialerStatsConstants.APIKeys.callSetupSuccessful] = "false"
        defaultData[VialerStatsConstants.APIKeys.failedReason] = VialerStatsConstants.FailedReason.insufficientNetwork
        defaultData[VialerStatsConstants.APIKeys.clientCountry] = SystemUser.current().country

        sendMetrics()
    }
    
    @objc func incomingCallFailedDeclinedBecauseAnotherCallInProgress(call: VSLCall){
        initDefaultData()
        setBluetoothAudioDeviceAndState()
        
        setMiddlewareData()
        setNetworkData()
        setTransportData()
        setCallDirection(call.isIncoming)
        setCallInformation(call)
        
        defaultData[VialerStatsConstants.APIKeys.callSetupSuccessful] = "false"
        defaultData[VialerStatsConstants.APIKeys.clientCountry] = SystemUser.current().country
        defaultData[VialerStatsConstants.APIKeys.asteriskCallId] = call.messageCallId
        defaultData[VialerStatsConstants.APIKeys.failedReason] = "DECLINED_ANOTHER_CALL_IN_PROGRESS"
        
        sendMetrics()
    }
    
    @objc func incomingCallFailedDeclined(call: VSLCall){
        initDefaultData()
        setBluetoothAudioDeviceAndState()
            
        setMiddlewareData()
        setNetworkData()
        setTransportData()
        setCallDirection(call.isIncoming)
        setCallInformation(call)
        
        defaultData[VialerStatsConstants.APIKeys.callSetupSuccessful] = "false"
        defaultData[VialerStatsConstants.APIKeys.asteriskCallId] = call.messageCallId
        defaultData[VialerStatsConstants.APIKeys.clientCountry] = SystemUser.current().country

        switch call.terminateReason {
        case .callCompletedElsewhere:
            defaultData[VialerStatsConstants.APIKeys.failedReason] = VialerStatsConstants.FailedReason.completedElsewhere
        case .originatorCancel:
            defaultData[VialerStatsConstants.APIKeys.failedReason] = VialerStatsConstants.FailedReason.originatorCanceled
        case .unknown:
            defaultData[VialerStatsConstants.APIKeys.failedReason] = VialerStatsConstants.FailedReason.declined
        @unknown default:
            defaultData[VialerStatsConstants.APIKeys.failedReason] = VialerStatsConstants.FailedReason.declined
        }
        
        sendMetrics()
    }
    
    @objc func logStatementForReceivedPushNotification(attempt: Int){
        initDefaultData()
        setMiddlewareData()
        setNetworkData()

        defaultData[VialerStatsConstants.APIKeys.clientCountry] = SystemUser.current().country
        defaultData[VialerStatsConstants.APIKeys.attempt] = String(attempt)
        
        sendMetrics()
    }
    
    @objc func callFailedNoAudio(_ call: VSLCall) {
        initDefaultData()
        setBluetoothAudioDeviceAndState()

        if call.isIncoming {
            setMiddlewareData()
        }
        setNetworkData()
        setTransportData()
        setCallDirection(call.isIncoming)
        setCallInformation(call)
        
        defaultData[VialerStatsConstants.APIKeys.callSetupSuccessful] = "false"
        defaultData[VialerStatsConstants.APIKeys.asteriskCallId] = call.messageCallId
        defaultData[VialerStatsConstants.APIKeys.clientCountry] = SystemUser.current().country

        switch call.callAudioState {
            case .noAudioReceiving:
                defaultData[VialerStatsConstants.APIKeys.failedReason] = VialerStatsConstants.NoAudioReason.audioReceiving
            case .noAudioTransmitting:
                defaultData[VialerStatsConstants.APIKeys.failedReason] = VialerStatsConstants.NoAudioReason.audioTransmitting
            case .noAudioBothDirections:
                defaultData[VialerStatsConstants.APIKeys.failedReason] = VialerStatsConstants.NoAudioReason.audioBothDirections
            case .OK: break
        @unknown default:
            defaultData[VialerStatsConstants.APIKeys.failedReason] = VialerStatsConstants.NoAudioReason.audioBothDirections
        }

        sendMetrics()
    }

    @objc func callHangupReason(_ call: VSLCall) {
        initDefaultData()
        setBluetoothAudioDeviceAndState()
        setNetworkData()
        setTransportData()
        setCallDirection(call.isIncoming)
        setCallInformation(call)
        
        if call.isIncoming {
            setMiddlewareData()
        }

        if call.userDidHangUp {
            defaultData[VialerStatsConstants.APIKeys.hangupReason] = VialerStatsConstants.HangupReason.userHangup
        } else {
            defaultData[VialerStatsConstants.APIKeys.hangupReason] = VialerStatsConstants.HangupReason.remoteHangup
        }

        defaultData[VialerStatsConstants.APIKeys.callDuration] = String(format: "\(call.connectDuration)")
        defaultData[VialerStatsConstants.APIKeys.asteriskCallId] = call.messageCallId
        defaultData[VialerStatsConstants.APIKeys.clientCountry] = SystemUser.current().country

        sendMetrics()
    }

    func noIncomingCallReceived() {
        initDefaultData()
        setBluetoothAudioDeviceAndState()
        setNetworkData()
        setTransportData()
        setMiddlewareData()
        setCallDirection(true)

        defaultData[VialerStatsConstants.APIKeys.direction] = VialerStatsConstants.Direction.incoming
        defaultData[VialerStatsConstants.APIKeys.callSetupSuccessful] = "false"
        defaultData[VialerStatsConstants.APIKeys.clientCountry] = SystemUser.current().country
        defaultData[VialerStatsConstants.APIKeys.failedReason] = VialerStatsConstants.FailedReason.noCallAfterRegistration

        sendMetrics()
    }

    func callFailed(callId: String, incoming: Bool, statusCode: String) {
        initDefaultData()
        setNetworkData()
        setTransportData()
        setBluetoothAudioDeviceAndState()

        if incoming {
            setMiddlewareData()
        }

        setCallDirection(incoming)
        defaultData[VialerStatsConstants.APIKeys.callSetupSuccessful] = "false"
        defaultData[VialerStatsConstants.APIKeys.asteriskCallId] = callId
        defaultData[VialerStatsConstants.APIKeys.failedReason] = statusCode
        defaultData[VialerStatsConstants.APIKeys.clientCountry] = SystemUser.current().country

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
