//
//  SIPCallingViewController.swift
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

import Contacts
import MediaPlayer

private var myContext = 0

class SIPCallingViewController: UIViewController, KeypadViewControllerDelegate, SegueHandler {
    
    // MARK: - Configuration
    enum SegueIdentifier : String {
        case unwindToVialerRootViewController = "UnwindToVialerRootViewControllerSegue"
        case showKeypad = "ShowKeypadSegue"
        case setupTransfer = "SetupTransferSegue"
    }
    
    fileprivate struct Config {
        struct Timing {
            static let waitingTimeAfterDismissing = 1.0
            static let connectDurationInterval = 1.0
        }
    }
    
    // MARK: - Properties
    
    @objc var activeCall: VSLCall? {
        didSet {
            var numberToClean: String
            if activeCall!.isIncoming {
                numberToClean = activeCall!.callerNumber!
            } else {
                numberToClean = activeCall!.numberToCall
            }
            if let cleanedPhoneNumber = PhoneNumberUtils.cleanPhoneNumber(numberToClean) {
                phoneNumberLabelText = cleanedPhoneNumber
            }
            
            DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive).async {
                PhoneNumberModel.getCallName(self.activeCall!, withCompletion: { (phoneNumberModel) in
                    DispatchQueue.main.async { [weak self] in
                        if !phoneNumberModel.callerInfo.isEmpty {
                            self?.phoneNumberLabelText = phoneNumberModel.callerInfo
                        }
                        self?.diplayNameForOutgoingCall = phoneNumberModel.displayName
                    }
                })
            }
            DispatchQueue.main.async { [weak self] in
                self?.updateUI()
            }
            activeCall?.addObserver(self, forKeyPath: "callState", options: .new, context: &myContext)
            activeCall?.addObserver(self, forKeyPath: "mediaState", options: .new, context: &myContext)
        }
    }
    var callManager = VialerSIPLib.sharedInstance().callManager
    let currentUser = SystemUser.current()!
    // ReachabilityManager, needed for showing notifications.
    fileprivate let reachability = ReachabilityHelper.instance.reachability!
    
    var callGotAnError = false
    
    // The cleaned number that needs to be called.
    var cleanedPhoneNumber: String?
    var diplayNameForOutgoingCall: String?
    var phoneNumberLabelText: String? {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.updateUI()
            }
        }
    }
    fileprivate var dtmfWholeValue: String = ""
    fileprivate var dtmfSingleTimeValue: String = ""
    fileprivate var dtmfSent: String? {
        didSet {
            DispatchQueue.main.async { [weak self] in
                if let unwrappedDtmfSent = self?.dtmfSent {
                    self?.dtmfSingleTimeValue = unwrappedDtmfSent
                }
            }
        }
    }
    fileprivate lazy var dateComponentsFormatter: DateComponentsFormatter = {
        let dateComponentsFormatter = DateComponentsFormatter()
        dateComponentsFormatter.zeroFormattingBehavior = .pad
        dateComponentsFormatter.allowedUnits = [.minute, .second]
        return dateComponentsFormatter
    }()
    fileprivate var connectDurationTimer: Timer?
    
    // MARK: - Outlets
    @IBOutlet weak var muteButton: SipCallingButton!
    @IBOutlet weak var keypadButton: SipCallingButton!
    @IBOutlet weak var speakerButton: SipCallingButton!
    @IBOutlet weak var speakerLabel: UILabel!
    @IBOutlet weak var transferButton: SipCallingButton!
    @IBOutlet weak var holdButton: SipCallingButton!
    @IBOutlet weak var hangupButton: UIButton!
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var statusLabelTopConstraint: NSLayoutConstraint!
    
    deinit {
        activeCall?.removeObserver(self, forKeyPath: "callState")
        activeCall?.removeObserver(self, forKeyPath: "mediaState")
    }
}

// MARK: - Lifecycle
extension SIPCallingViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIDevice.current.isProximityMonitoringEnabled = true
        VialerGAITracker.trackScreenForController(name: controllerName)
        updateUI()
        startConnectDurationTimer()
        
        guard let call = activeCall else {
            setupCall()
            return
        }
        
        if call.callState == .disconnected {
            handleCallEnded()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        connectDurationTimer?.invalidate()
        UIDevice.current.isProximityMonitoringEnabled = false
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.VSLCallErrorDuringSetupCall, object: nil)
    }
}

// MARK: - Actions
extension SIPCallingViewController {
    @IBAction func muteButtonPressed(_ sender: SipCallingButton) {
        guard let call = activeCall, call.callState != .disconnected else { return }
        
        callManager.toggleMute(for: call) { error in
            if error != nil {
                VialerLogError("Error muting call: \(String(describing: error))")
            } else {
                DispatchQueue.main.async {
                    self.updateUI()
                }
            }
        }
    }
    
    @IBAction func keypadButtonPressed(_ sender: SipCallingButton) {
        dtmfWholeValue += dtmfSingleTimeValue
        dtmfSingleTimeValue = ""
        performSegue(segueIdentifier: .showKeypad)
    }
    
    @IBAction func speakerButtonPressed(_ sender: SipCallingButton) {
        guard activeCall != nil else { return }
        if callManager.audioController.hasBluetooth {
            // We add the MPVolumeView to the view without any size, we just need it so we can push the button in code.
            let volumeView = MPVolumeView(frame: CGRect.zero)
            volumeView.alpha = 0.0
            view.addSubview(volumeView)
            for view in volumeView.subviews {
                if let button = view as? UIButton {
                    button.sendActions(for: .touchUpInside)
                }
            }
        } else {
            callManager.audioController.output = callManager.audioController.output == .speaker ? .other : .speaker
            updateUI()
        }
    }
    
    @IBAction func transferButtonPressed(_ sender: SipCallingButton) {
        guard let call = activeCall, call.callState == .confirmed else { return }
        if call.onHold {
            performSegue(segueIdentifier: .setupTransfer)
            return
        }
        callManager.toggleHold(for: call) { error in
            if error != nil {
                VialerLogError("Error holding current call: \(String(describing: error))")
            } else {
                self.performSegue(segueIdentifier: .setupTransfer)
            }
        }
    }
    
    @IBAction func holdButtonPressed(_ sender: SipCallingButton) {
        guard let call = activeCall else { return }
        callManager.toggleHold(for: call) { error in
            if error != nil {
                VialerLogError("Error holding current call: \(String(describing: error))")
            } else {
                DispatchQueue.main.async {
                    self.updateUI()
                }
            }
        }
    }
    
    @IBAction func hangupButtonPressed(_ sender: UIButton) {
        #if DEBUG
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate, appDelegate.isScreenshotRun {
            dismissView()
            return
        }
        #endif
        guard let call = activeCall, call.callState != .disconnected else { return }
        statusLabel.text = NSLocalizedString("Ending call...", comment: "Ending call...")
        
        callManager.end(call) { error in
            if error != nil {
                VialerLogError("Error ending call: \(String(describing: error))")
            } else {
                DispatchQueue.main.async {
                    self.hangupButton.isEnabled = false
                }
            }
        }
    }
}

// MARK: - Call setup
extension SIPCallingViewController {
    @objc func handleOutgoingCall(phoneNumber: String, contact: CNContact?) {
        NotificationCenter.default.addObserver(self, selector: #selector(errorDuringCallSetup(_:)), name: NSNotification.Name.VSLCallErrorDuringSetupCall, object: nil)
        
        cleanedPhoneNumber = PhoneNumberUtils.cleanPhoneNumber(phoneNumber) ?? ""
        phoneNumberLabelText = cleanedPhoneNumber
        
        if let unwrappedContact = contact {
            DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive).async {
                PhoneNumberModel.getCallName(from: unwrappedContact, andPhoneNumber: phoneNumber, withCompletion: { (phoneNumberModel) in
                    DispatchQueue.main.async { [weak self] in
                        if !phoneNumberModel.callerInfo.isEmpty {
                            self?.phoneNumberLabelText = phoneNumberModel.callerInfo
                        }
                        self?.diplayNameForOutgoingCall = phoneNumberModel.displayName
                    }
                })
            }
        }
        updateUI()
    }
    
    func handleOutgoingCallForScreenshot(phoneNumber: String){
        if let unwrappedCleanedPhoneNumber = PhoneNumberUtils.cleanPhoneNumber(phoneNumber){
            cleanedPhoneNumber = unwrappedCleanedPhoneNumber
            phoneNumberLabelText = cleanedPhoneNumber
        }
    }
    
    /// Check 2 things before setting up a call:
    ///
    /// - Microphone permission
    /// - WiFi Notification
    fileprivate func setupCall() {
        guard !(UIApplication.shared.delegate as! AppDelegate).isScreenshotRun else {
            return
        }
        
        // Check microphone
        checkMicrophonePermission { startCalling in
            if startCalling {
                // Mic good, WiFi?
                if self.shouldPresentWiFiNotification() {
                    self.presentWiFiNotification()
                } else {
                    self.startCalling()
                }
            } else {
                // No Mic, present alert
                self.presentEnableMicrophoneAlert()
            }
        }
    }
    
    fileprivate func startCalling() {
        SIPUtils.registerSIPAccountWithEndpoint { (success, account) in
            guard account != nil else {
                return
            }

            if let unwrappedCleanedPhoneNumber = self.cleanedPhoneNumber {
                self.startConnectDurationTimer()
                self.callManager.startCall(toNumber: unwrappedCleanedPhoneNumber, for: account!) { (call, error) in
                    if error != nil {
                        VialerLogError("Error setting up call: \(String(describing: error))")
                    } else if let call = call {
                        self.activeCall = call
                    }
                }
            }
        }
    }
    
    fileprivate func dismissView() {
        let waitingTimeAfterDismissing = Config.Timing.waitingTimeAfterDismissing
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(waitingTimeAfterDismissing * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) { [weak self] in
            if self?.activeCall?.isIncoming ?? false {
                self?.performSegue(segueIdentifier: .unwindToVialerRootViewController)
            } else {
                UIDevice.current.isProximityMonitoringEnabled = false
                self?.presentingViewController?.dismiss(animated: false, completion: nil)
            }
        }
    }
    
    fileprivate func handleCallEnded() {
        VialerGAITracker.callMetrics(finishedCall: self.activeCall!)
        
        hangupButton?.isEnabled = false
        
        if !self.callGotAnError {
            switch self.activeCall!.callAudioState {
            // There was no audio when the call was hungup.
            case .noAudioReceiving: fallthrough
            case .noAudioTransmitting: fallthrough
            case .noAudioBothDirections:
                VialerStats.sharedInstance.callFailedNoAudio(self.activeCall!)
            // There was audio during the call.
            case .OK: fallthrough
            default:
                VialerStats.sharedInstance.callSuccess(self.activeCall!)
            }
        }
        
        VialerStats.sharedInstance.callHangupReason(self.activeCall!)
        dismissView()
    }
}

// MARK: - Helper functions
extension SIPCallingViewController {
    @objc func updateUI() {
        #if DEBUG
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate, appDelegate.isScreenshotRun {
            holdButton?.isEnabled = true
            muteButton?.isEnabled = true
            transferButton?.isEnabled = true
            speakerButton?.isEnabled = true
            hangupButton?.isEnabled = true
            statusLabel?.text = "09:41"
            numberLabel?.isHidden = true
            if statusLabelTopConstraint != nil {
                statusLabelTopConstraint.constant = -(numberLabel?.frame.size.height ?? 0)
            }
            nameLabel?.text = phoneNumberLabelText
            return
        }
        #endif
        
        if callManager.audioController.hasBluetooth {
            speakerButton?.buttonImage = "CallButtonBluetooth"
            speakerLabel?.text = NSLocalizedString("audio", comment: "audio")
        } else {
            speakerButton?.buttonImage = "CallButtonSpeaker"
            speakerLabel?.text = NSLocalizedString("speaker", comment: "speaker")
        }
        
        guard let call = activeCall else {
            // if there is only a number then show it on the nameLabel
            numberLabel?.text = " "
            nameLabel?.text = cleanedPhoneNumber
            statusLabel?.text = ""
            return
        }
        
        switch call.callState {
        case .null: fallthrough
        case .calling: fallthrough
        case .incoming: fallthrough
        case .early: fallthrough
        case .connecting:
            holdButton?.isEnabled = false
            muteButton?.isEnabled = false
            transferButton?.isEnabled = false
            speakerButton?.isEnabled = true
            hangupButton?.isEnabled = true
        case .confirmed:
            holdButton?.isEnabled = true
            muteButton?.isEnabled = true
            transferButton?.isEnabled = true
            speakerButton?.isEnabled = true
            hangupButton?.isEnabled = true
        case .disconnected:
            holdButton?.isEnabled = false
            muteButton?.isEnabled = false
            transferButton?.isEnabled = false
            speakerButton?.isEnabled = false
            hangupButton?.isEnabled = false
        }
        
        // If call is active and not on hold, enable the button.
        keypadButton?.isEnabled = !call.onHold && call.callState == .confirmed
        holdButton?.active = call.onHold
        muteButton?.active = call.muted
        speakerButton?.active = callManager.audioController.output == .bluetooth || callManager.audioController.output == .speaker
        
        // When dtmf is sent, add that to the numberLabel
        if dtmfSingleTimeValue != "" || dtmfWholeValue != "" {
            if nameLabel?.text == phoneNumberLabelText {
                numberLabel?.text = dtmfWholeValue + dtmfSingleTimeValue
                numberLabel?.isHidden = false
                if statusLabelTopConstraint != nil {
                    statusLabelTopConstraint.constant = 20
                }
            } else {
                numberLabel?.text = (phoneNumberLabelText ?? "") + " " + dtmfWholeValue + dtmfSingleTimeValue
            }
        } else {
            if !call.isIncoming {
                if let unwrappedDiplayNameForOutgoingCall = diplayNameForOutgoingCall{
                    if unwrappedDiplayNameForOutgoingCall.isEmpty {
                        nameLabel?.text = phoneNumberLabelText
                    } else {
                        nameLabel?.text = unwrappedDiplayNameForOutgoingCall
                    }
                } else {
                    if nameLabel?.text?.isEmpty ?? false {
                        nameLabel?.text = phoneNumberLabelText
                    }
                }
                numberLabel?.text = phoneNumberLabelText
            } else {
                numberLabel?.text = PhoneNumberUtils.cleanPhoneNumber(call.callerNumber ?? "")
                nameLabel?.text = call.callerName
                if (nameLabel?.text ?? "").isEmpty {
                    nameLabel?.text = numberLabel?.text
                }
            }

            if (numberLabel?.text != nameLabel?.text && CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: numberLabel?.text ?? "false it"))) || (numberLabel?.text ?? "").isEmpty {
                numberLabel?.isHidden = false
                if statusLabelTopConstraint != nil {
                    statusLabelTopConstraint.constant = 20
                }
            } else {
                numberLabel?.isHidden = true
                if statusLabelTopConstraint != nil {
                    statusLabelTopConstraint.constant = -(numberLabel?.frame.size.height ?? 0)
                }
            }
        }
        
        switch call.callState {
        case .null:
            statusLabel?.text = ""
        case .calling: fallthrough
        case .early:
            statusLabel?.text = NSLocalizedString("Calling...", comment: "Statuslabel state text .Calling")
        case .incoming:
            statusLabel?.text = NSLocalizedString("Incoming call...", comment: "Statuslabel state text .Incoming")
        case .connecting:
            statusLabel?.text = NSLocalizedString("Connecting...", comment: "Statuslabel state text .Connecting")
        case .confirmed:
            if call.onHold {
                statusLabel?.text = NSLocalizedString("On hold", comment: "On hold")
            } else {
                statusLabel?.text = "\(dateComponentsFormatter.string(from: call.connectDuration)!)"
            }
        case .disconnected:
            statusLabel?.text = NSLocalizedString("Call ended", comment: "Statuslabel state text .Disconnected")
            connectDurationTimer?.invalidate()
        }
    }
    
    func startConnectDurationTimer() {
        if connectDurationTimer == nil || !connectDurationTimer!.isValid {
            connectDurationTimer = Timer.scheduledTimer(timeInterval: Config.Timing.connectDurationInterval, target: self, selector: #selector(updateUI), userInfo: nil, repeats: true)
        }
    }
}

// MARK: - WiFi notification
extension SIPCallingViewController {
    @objc func shouldPresentWiFiNotification() -> Bool {
        return currentUser.showWiFiNotification && reachability.status == .reachableViaWiFi && reachability.radioStatus == .reachableVia4G
    }
    
    /**
     Show alert to user if the user is on WiFi and has 4G connection.
     */
    fileprivate func presentWiFiNotification() {
        let alertController = UIAlertController(title: NSLocalizedString("Tip: Disable WiFi for better audio", comment: "Tip: Disable WiFi for better audio"),
                                                message: NSLocalizedString("With mobile internet (4G) you get a more stable connection and that should improve the audio quality.\n\n To disable WiFi go to Settings -> WiFi and disable WiFi.",
                                                                           comment: "With mobile internet (4G) you get a more stable connection and that should improve the audio quality.\n\n Disable Wifi? To disable WiFi go to Settings -> WiFi and disable WiFi."),
                                                preferredStyle: .alert)
        
        // User wants to use the WiFi connection.
        let continueAction = UIAlertAction(title: NSLocalizedString("Continue calling", comment: "Continue calling"), style: .default) { action in
            self.startCalling()
        }
        alertController.addAction(continueAction)
        
        // Add option to cancel the call.
        let cancelCall = UIAlertAction(title: NSLocalizedString("Cancel call", comment: "Cancel call"), style: .default) { action in
            self.performSegue(segueIdentifier: .unwindToVialerRootViewController)
        }
        alertController.addAction(cancelCall)
        
        present(alertController, animated: true, completion: nil)
    }
    
    
    /**
     Show the settings from the phone and make sure there is a notification to continue calling.
     */
    fileprivate func presentContinueCallingAlert() {
        let alertController = UIAlertController(title: NSLocalizedString("Continue calling", comment: "Continue calling"), message: nil, preferredStyle: .alert)
        
        // Make it possible to cancel the call
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel call", comment: "Cancel call"), style: .cancel) { action in
            self.performSegue(segueIdentifier: .unwindToVialerRootViewController)
        }
        alertController.addAction(cancelAction)
        
        // Continue the call
        let continueAction = UIAlertAction(title: NSLocalizedString("Start calling", comment: "Start calling"), style: .default) { action in
            self.startCalling()
        }
        alertController.addAction(continueAction)
        
        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - Microphone permission
extension SIPCallingViewController {
    fileprivate func checkMicrophonePermission(completion: @escaping ((_ startCalling: Bool) -> Void)) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    /// Show a notification that makes it possible to open the settings and enable the microphone
    ///
    /// Activating the microphone permission will terminate the app.
    fileprivate func presentEnableMicrophoneAlert() {
        let alertController = UIAlertController(title: NSLocalizedString("Access to microphone denied", comment: "Access to microphone denied"),
                                                message: NSLocalizedString("Give permission to use your microphone.\nGo to",
                                                                           comment: "Give permission to use your microphone.\nGo to"),
                                                preferredStyle: .alert)
        
        // Cancel the call, without audio, calling isn't possible.
        let noAction = UIAlertAction(title: NSLocalizedString("Cancel call", comment: "Cancel call"), style: .cancel) { action in
            self.performSegue(segueIdentifier: .unwindToVialerRootViewController)
        }
        alertController.addAction(noAction)
        
        // User wants to open the settings to enable microphone permission.
        let settingsAction = UIAlertAction(title: NSLocalizedString("Settings", comment: "Settings"), style: .default) { action in
            UIApplication.shared.openURL(URL(string:UIApplication.openSettingsURLString)!)
        }
        alertController.addAction(settingsAction)
        
        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - Segues
extension SIPCallingViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(segue: segue) {
        case .showKeypad:
            let keypadVC = segue.destination as! KeypadViewController
            keypadVC.call = activeCall
            keypadVC.delegate = self
            keypadVC.phoneNumberLabelText = phoneNumberLabelText
        case .setupTransfer:
            let tabBarC = segue.destination as! UITabBarController
            let transferContactListNavC = tabBarC.viewControllers![0] as! UINavigationController
            let transferDialPadNavC = tabBarC.viewControllers![1] as! UINavigationController
            let setupCallTransferContactsVC = transferContactListNavC.viewControllers[0] as! SetupCallTransferContactsViewController
            let setupCallTransferDialPadVC = transferDialPadNavC.viewControllers[0] as! SetupCallTransferDialPadViewController
            setupCallTransferDialPadVC.firstCall = activeCall
            setupCallTransferDialPadVC.firstCallPhoneNumberLabelText = phoneNumberLabelText
            setupCallTransferContactsVC.firstCall = activeCall
            setupCallTransferContactsVC.firstCallPhoneNumberLabelText = phoneNumberLabelText
        case .unwindToVialerRootViewController:
            break
        }
    }
    
    @IBAction func unwindToFirstCallSegue(_ segue: UIStoryboardSegue) {}
    
}

// MARK: - KVO
extension SIPCallingViewController {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &myContext {
            if let call = object as? VSLCall {
                DispatchQueue.main.async { [weak self] in
                    self?.updateUI()
                    if call.callState == .disconnected {
                        self?.handleCallEnded()
                    }
                }
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}

// MARK: - KeypadViewControllerDelegate
extension SIPCallingViewController {
    func dtmfSent(_ dtmfSent: String?) {
        self.dtmfSent = dtmfSent
    }
}

extension SIPCallingViewController {
    @objc func errorDuringCallSetup(_ notification: NSNotification) {
        let statusCode = notification.userInfo![VSLNotificationUserInfoErrorStatusCodeKey] as! String
        
        if statusCode != "407" {
            self.callGotAnError = true
        }
    }
}
