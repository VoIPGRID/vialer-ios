//
//  SIPCallingViewController.swift
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

import AVFoundation
import Contacts

private var myContext = 0

class SIPCallingViewController: UIViewController, KeypadViewControllerDelegate {

    // MARK: - Configuration

    fileprivate struct Configuration {
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

    let avAudioSession = AVAudioSession.sharedInstance()

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
        }
    }
    var callManager: VSLCallManager {
        get {
            return VialerSIPLib.sharedInstance().callManager
        }
    }

    var phoneNumberLabelText: String? {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.updateUI()
            }
        }
    }

    fileprivate var dtmfSent: String? {
        didSet {
            numberLabel?.text = dtmfSent
        }
    }

    fileprivate lazy var dateComponentsFormatter: DateComponentsFormatter = {
        let dateComponentsFormatter = DateComponentsFormatter()
        dateComponentsFormatter.zeroFormattingBehavior = .pad
        dateComponentsFormatter.allowedUnits = [.minute, .second]
        return dateComponentsFormatter
    }()
    fileprivate var connectDurationTimer: Timer?

    private var observingCall = false

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        VialerGAITracker.trackScreenForController(name: controllerName)
        updateUI()

        if let call = activeCall, call.callState == .disconnected {
            handleCallEnded()
        }

        if !observingCall {
            activeCall?.addObserver(self, forKeyPath: Configuration.KVO.Call.callState, options: .new, context: &myContext)
            activeCall?.addObserver(self, forKeyPath: Configuration.KVO.Call.mediaState, options: .new, context: &myContext)
            observingCall = true
        }
        startConnectDurationTimer()
    }

    override func viewWillDisappear(_ animated: Bool) {
        if observingCall {
            activeCall?.removeObserver(self, forKeyPath: Configuration.KVO.Call.callState)
            activeCall?.removeObserver(self, forKeyPath: Configuration.KVO.Call.mediaState)
            observingCall = false
        }
        connectDurationTimer?.invalidate()
    }

    // MARK: - Outlets

    @IBOutlet weak var muteButton: SipCallingButton!
    @IBOutlet weak var keypadButton: SipCallingButton!
    @IBOutlet weak var speakerButton: SipCallingButton!
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
                DDLogWrapper.logError("Error muting call: \(error)")
            } else {
                self.updateUI()
            }
        }
    }

    @IBAction func keypadButtonPressed(_ sender: SipCallingButton) {
        performSegue(withIdentifier: Configuration.Segues.ShowKeypad, sender: self)
    }

    @IBAction func speakerButtonPressed(_ sender: SipCallingButton) {
        guard let call = activeCall else { return }
        call.toggleSpeaker()
        updateUI()
    }

    @IBAction func transferButtonPressed(_ sender: SipCallingButton) {
        guard let call = activeCall, call.callState == .confirmed else { return }
        if call.onHold {
            performSegue(withIdentifier: Configuration.Segues.SetupTransfer, sender: self)
        } else {
            do {
                try call.toggleHold()
                performSegue(withIdentifier: Configuration.Segues.SetupTransfer, sender: self)
            } catch let error {
                DDLogWrapper.logError("Error holding current call: \(error)")
            }
        }
    }

    @IBAction func holdButtonPressed(_ sender: SipCallingButton) {
        guard let call = activeCall else { return }
        do {
            try call.toggleHold()
            updateUI()

        } catch let error {
            DDLogWrapper.logError("Error holding call: \(error)")
        }
    }

    @IBAction func hangupButtonPressed(_ sender: UIButton) {
        guard let call = activeCall, call.callState != .disconnected else { return }
        statusLabel.text = NSLocalizedString("Ending call...", comment: "Ending call...")

        callManager.end(call) { error in
            if error != nil {
                DDLogWrapper.logError("Error ending call: \(error)")

            } else {
                self.hangupButton.isEnabled = false
            }
        }
    }

    func handleOutgoingCall(phoneNumber: String, contact: CNContact?) {
        if let contact = contact {
            DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive).async {
                PhoneNumberModel.getCallName(from: contact, andPhoneNumber: phoneNumber, withCompletion: { (phoneNumberModel) in
                    DispatchQueue.main.async { [weak self] in
                        self?.phoneNumberLabelText = phoneNumberModel.callerInfo
                    }
                })
            }
        }

        guard let account = SIPUtils.addSIPAccountToEndpoint() else {
            return
        }

        callManager.startCall(toNumber: phoneNumber, for: account) { (call, error) in
            if error != nil {
                DDLogWrapper.logError("Error setting up call: \(error)")
            } else if let call = call {
                self.activeCall = call
            }
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

        guard let call = activeCall else { return }

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
        speakerButton?.active = call.speaker

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

    fileprivate func handleCallEnded() {
        VialerGAITracker.callMetrics(finishedCall: self.activeCall!)

        hangupButton?.isEnabled = false
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

    fileprivate func startConnectDurationTimer() {
        if connectDurationTimer == nil || !connectDurationTimer!.isValid {
            connectDurationTimer = Timer.scheduledTimer(timeInterval: Configuration.Timing.ConnectDurationInterval, target: self, selector: #selector(updateUI), userInfo: nil, repeats: true)
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
