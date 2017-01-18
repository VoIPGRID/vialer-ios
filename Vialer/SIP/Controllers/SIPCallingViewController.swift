//
//  SIPCallingViewController.swift
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

import Contacts
import MediaPlayer

private var myContext = 0

class SIPCallingViewController: UIViewController, KeypadViewControllerDelegate {

    // MARK: - Configuration

    private struct Configuration {
        struct Timing {
            static let WaitingTimeAfterDismissing = 1.0
            static let ConnectDurationInterval = 1.0
        }
        struct Segues {
            static let UnwindToVialerRootViewController = "UnwindToVialerRootViewControllerSegue"
            static let ShowKeypad = "ShowKeypadSegue"
            static let SetupTransfer = "SetupTransferSegue"
        }
        struct KVO {
            struct Call {
                static let callState = "callState"
                static let mediaState = "mediaState"
            }
        }
    }

    // MARK: - Properties

    var activeCall: VSLCall? {
        didSet {
            var numberToClean: String
            if activeCall!.isIncoming {
                numberToClean = activeCall!.callerNumber!
            } else {
                numberToClean = activeCall!.numberToCall
            }
            let cleanedPhoneNumber = PhoneNumberUtils.cleanPhoneNumber(numberToClean)!
            phoneNumberLabelText = cleanedPhoneNumber

            DispatchQueue.main.async { [weak self] in
                self?.updateUI()
            }
            activeCall!.addObserver(self, forKeyPath: Configuration.KVO.Call.callState, options: .new, context: &myContext)
            activeCall!.addObserver(self, forKeyPath: Configuration.KVO.Call.mediaState, options: .new, context: &myContext)
        }
    }
    var callManager: VSLCallManager {
        get {
            return VialerSIPLib.sharedInstance().callManager
        }
    }

    let currentUser = SystemUser.current()!

    // ReachabilityManager, needed for showing notifications.
    let reachabilityManager = ReachabilityManager()

    // Keep track if there are notification needed for disabling/enabling WiFi.
    var shouldPresentWiFiNotification = false
    var didOpenSettings = false

    // The cleaned number that need to be called.
    var cleanedPhoneNumber: String?

    var phoneNumberLabelText: String? {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.updateUI()
            }
        }
    }

    private var dtmfSent: String? {
        didSet {
            numberLabel?.text = dtmfSent
        }
    }

    private lazy var dateComponentsFormatter: DateComponentsFormatter = {
        let dateComponentsFormatter = DateComponentsFormatter()
        dateComponentsFormatter.zeroFormattingBehavior = .pad
        dateComponentsFormatter.allowedUnits = [.minute, .second]
        return dateComponentsFormatter
    }()
    private var connectDurationTimer: Timer?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIDevice.current.isProximityMonitoringEnabled = true
        VialerGAITracker.trackScreenForController(name: controllerName)
        updateUI()

        if let call = activeCall, call.callState == .disconnected {
            handleCallEnded()
        }

        startConnectDurationTimer()

        if shouldPresentWiFiNotification {
            presentWiFiNotification()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        connectDurationTimer?.invalidate()
        UIDevice.current.isProximityMonitoringEnabled = false
    }

    deinit {
        activeCall?.removeObserver(self, forKeyPath: Configuration.KVO.Call.callState)
        activeCall?.removeObserver(self, forKeyPath: Configuration.KVO.Call.mediaState)
    }

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

    // MARK: - Actions

    @IBAction func muteButtonPressed(_ sender: SipCallingButton) {
        guard let call = activeCall, call.callState != .disconnected else { return }

        callManager.toggleMute(for: call) { error in
            if error != nil {
                VialerLogError("Error muting call: \(error)")
            } else {
                DispatchQueue.main.async {
                    self.updateUI()
                }
            }
        }
    }

    @IBAction func keypadButtonPressed(_ sender: SipCallingButton) {
        performSegue(withIdentifier: Configuration.Segues.ShowKeypad, sender: self)
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
            performSegue(withIdentifier: Configuration.Segues.SetupTransfer, sender: self)
            return
        }
        callManager.toggleHold(for: call) { error in
            if error != nil {
                VialerLogError("Error holding current call: \(error)")
            } else {
                self.performSegue(withIdentifier: Configuration.Segues.SetupTransfer, sender: self)
            }
        }
    }

    @IBAction func holdButtonPressed(_ sender: SipCallingButton) {
        guard let call = activeCall else { return }
        callManager.toggleHold(for: call) { error in
            if error != nil {
                VialerLogError("Error holding current call: \(error)")
            } else {
                DispatchQueue.main.async {
                    self.updateUI()
                }
            }
        }
    }

    @IBAction func hangupButtonPressed(_ sender: UIButton) {
        guard let call = activeCall, call.callState != .disconnected else { return }
        statusLabel.text = NSLocalizedString("Ending call...", comment: "Ending call...")

        callManager.end(call) { error in
            if error != nil {
                VialerLogError("Error ending call: \(error)")
            } else {
                DispatchQueue.main.async {
                    self.hangupButton.isEnabled = false
                }
            }
        }
    }

    func handleOutgoingCall(phoneNumber: String, contact: CNContact?) {
        cleanedPhoneNumber = PhoneNumberUtils.cleanPhoneNumber(phoneNumber)!
        phoneNumberLabelText = cleanedPhoneNumber
        if let contact = contact {
            DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive).async {
                PhoneNumberModel.getCallName(from: contact, andPhoneNumber: phoneNumber, withCompletion: { (phoneNumberModel) in
                    DispatchQueue.main.async { [weak self] in
                        self?.phoneNumberLabelText = phoneNumberModel.callerInfo
                    }
                })
            }
        }

        updateUI()
        if !currentUser.noWiFiNotification && reachabilityManager.onWiFi() && reachabilityManager.on4g() {
            shouldPresentWiFiNotification = true
        } else {
            setupCall()
        }
    }

    func handleOutgoingCallForScreenshot(phoneNumber: String){
        phoneNumberLabelText = phoneNumber
    }

    // MARK: - Helper functions

    func updateUI() {
        #if DEBUG
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate, appDelegate.isScreenshotRun {
                holdButton?.isEnabled = true
                muteButton?.isEnabled = true
                transferButton?.isEnabled = true
                speakerButton?.isEnabled = true
                hangupButton?.isEnabled = true
                statusLabel?.text = "09:41"
                numberLabel?.text = phoneNumberLabelText
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
            numberLabel?.text = cleanedPhoneNumber
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

        // When dtmf is sent, use that as text, otherwise phone number.
        if let dtmf = dtmfSent {
            numberLabel?.text = dtmf
        } else {
            numberLabel?.text = phoneNumberLabelText
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
                statusLabel?.text = NSLocalizedString("ON HOLD", comment: "On hold")
            } else {
                statusLabel?.text = "\(dateComponentsFormatter.string(from: call.connectDuration)!)"
            }
        case .disconnected:
            statusLabel?.text = NSLocalizedString("Call ended", comment: "Statuslabel state text .Disconnected")
            connectDurationTimer?.invalidate()
        }
    }

    private func handleCallEnded() {
        VialerGAITracker.callMetrics(finishedCall: self.activeCall!)

        hangupButton?.isEnabled = false

        if didOpenSettings && !self.reachabilityManager.onWiFi() {
            presentEnableWifiAlert()
        } else {
            dismissView()
        }
    }

    private func startConnectDurationTimer() {
        if connectDurationTimer == nil || !connectDurationTimer!.isValid {
            connectDurationTimer = Timer.scheduledTimer(timeInterval: Configuration.Timing.ConnectDurationInterval, target: self, selector: #selector(updateUI), userInfo: nil, repeats: true)
        }
    }

    /**
     Show alert to user if the user is on WiFi and has 4G connection.
    */
    private func presentWiFiNotification() {
        shouldPresentWiFiNotification = false
        let alertController = UIAlertController(title: NSLocalizedString("Tip: Disable WiFi for better audio", comment: "Tip: Disable WiFi for better audio"),
                                                message: NSLocalizedString("With mobile internet (4G) you get a more stable connection and that should improve the audio quality.\n\n Disable Wifi?",
                                                                           comment: "With mobile internet (4G) you get a more stable connection and that should improve the audio quality.\n\n Disable Wifi?"),
                                                preferredStyle: .alert)

        // User wants to use the WiFi connection.
        let noAction = UIAlertAction(title: NSLocalizedString("No", comment: "No"), style: .default) { action in
            self.setupCall()
        }
        alertController.addAction(noAction)

        // User wants to open the settings to disable WiFi.
        let settingsAction = UIAlertAction(title: NSLocalizedString("Settings", comment: "Settings"), style: .default) { action in
            self.presentSettingsAndContinueCallingAlert()
        }
        alertController.addAction(settingsAction)

        present(alertController, animated: true, completion: nil)
    }

    /**
     Show the settings from the phone and make sure there is a notification to continue calling.
    */
    private func presentSettingsAndContinueCallingAlert() {
        let alertController = UIAlertController(title: NSLocalizedString("Continue calling", comment: "Continue calling"), message: nil, preferredStyle: .alert)

        // Make it possible to cancel the call
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel call", comment: "Cancel call"), style: .default) { action in
            self.performSegue(withIdentifier: Configuration.Segues.UnwindToVialerRootViewController, sender: self)
        }
        alertController.addAction(cancelAction)

        // Continue the call
        let continueAction = UIAlertAction(title: NSLocalizedString("Start calling", comment: "Start calling"), style: .default) { action in
            self.setupCall()
        }
        alertController.addAction(continueAction)

        present(alertController, animated: true, completion: nil)

        // Open the settings. Opening the WiFi settings is not longer possible, settings open on Vialer settings.
        didOpenSettings = true
        UIApplication.shared.openURL(URL(string:UIApplicationOpenSettingsURLString)!)
    }

    private func presentEnableWifiAlert() {
        didOpenSettings = false
        let alertController = UIAlertController(title: NSLocalizedString("Call has Ended, enable WiFi?", comment: "Call has Ended, enable WiFi?"), message: nil, preferredStyle: .alert)

        let noAction = UIAlertAction(title: NSLocalizedString("No", comment: "No"), style: .default) { action in
            self.dismissView()
        }
        alertController.addAction(noAction)

        // User wants to open the settings to disable WiFi.
        let settingsAction = UIAlertAction(title: NSLocalizedString("Settings", comment: "Settings"), style: .default) { action in
            DispatchQueue.global().async {
                DispatchQueue.main.async {
                    UIApplication.shared.openURL(URL(string:UIApplicationOpenSettingsURLString)!)
                }
            }
            self.dismissView()
        }
        alertController.addAction(settingsAction)

        present(alertController, animated: true, completion: nil)
    }

    private func dismissView() {
        let waitingTimeAfterDismissing = Configuration.Timing.WaitingTimeAfterDismissing
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(waitingTimeAfterDismissing * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
            if self.activeCall!.isIncoming {
                self.performSegue(withIdentifier: Configuration.Segues.UnwindToVialerRootViewController, sender: self)
            } else {
                UIDevice.current.isProximityMonitoringEnabled = false
                self.presentingViewController?.dismiss(animated: true, completion: nil)
            }
        }
    }

    private func setupCall() {
        guard let account = SIPUtils.addSIPAccountToEndpoint() else {
            return
        }

        callManager.startCall(toNumber: cleanedPhoneNumber!, for: account) { (call, error) in
            if error != nil {
                VialerLogError("Error setting up call: \(error)")
            } else if let call = call {
                self.activeCall = call
            }
        }
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let keypadVC = segue.destination as? KeypadViewController {
            keypadVC.call = activeCall
            keypadVC.delegate = self
            keypadVC.phoneNumberLabelText = phoneNumberLabelText
        } else if let navVC = segue.destination as? UINavigationController, let setupCallTransferVC = navVC.viewControllers[0] as? SetupCallTransferViewController {
            setupCallTransferVC.firstCall = activeCall
            setupCallTransferVC.firstCallPhoneNumberLabelText = phoneNumberLabelText
        }
    }

    @IBAction func unwindToFirstCallSegue(_ segue: UIStoryboardSegue) {}

    // MARK: - KVO

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

    // MARK: - KeypadViewControllerDelegate

    func dtmfSent(_ dtmfSent: String?) {
        self.dtmfSent = dtmfSent
    }
}
