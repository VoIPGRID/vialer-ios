//
//  SIPCallingViewController.swift
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

import AVFoundation
import Contacts

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

    let avAudioSession = AVAudioSession.sharedInstance()

    var activeCall: VSLCall?

    private var previousAVAudioSessionCategory: String?
    var phoneNumberLabelText: String? {
        didSet {
            dispatch_async(dispatch_get_main_queue()) { [weak self] in
                self?.updateUI()
            }
        }
    }

    private var dtmfSent: String? {
        didSet {
            numberLabel?.text = dtmfSent
        }
    }

    private lazy var dateComponentsFormatter: NSDateComponentsFormatter = {
        let dateComponentsFormatter = NSDateComponentsFormatter()
        dateComponentsFormatter.zeroFormattingBehavior = .Pad
        dateComponentsFormatter.allowedUnits = [.Minute, .Second]
        return dateComponentsFormatter
    }()
    private var connectDurationTimer: NSTimer?

    // MARK: - Lifecycle

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        VialerGAITracker.trackScreenForController(name: controllerName)
        updateUI()

        if let call = activeCall where call.callState == .Disconnected {
            handleCallEnded()
        }

        activeCall?.addObserver(self, forKeyPath: Configuration.KVO.Call.callState, options: .New, context: &myContext)
        activeCall?.addObserver(self, forKeyPath: Configuration.KVO.Call.mediaState, options: .New, context: &myContext)
        startConnectDurationTimer()
    }

    override func viewWillDisappear(animated: Bool) {
        activeCall?.removeObserver(self, forKeyPath: Configuration.KVO.Call.callState)
        activeCall?.removeObserver(self, forKeyPath: Configuration.KVO.Call.mediaState)
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

    @IBAction func muteButtonPressed(sender: SipCallingButton) {
        guard let call = activeCall else { return }
        do {
            try call.toggleMute()
            updateUI()
        } catch let error {
            DDLogWrapper.logError("Error muting call: \(error)")
        }
    }

    @IBAction func keypadButtonPressed(sender: SipCallingButton) {
        performSegueWithIdentifier(Configuration.Segues.ShowKeypad, sender: self)
    }

    @IBAction func speakerButtonPressed(sender: SipCallingButton) {
        guard let call = activeCall else { return }
        call.toggleSpeaker()
        updateUI()
    }

    @IBAction func transferButtonPressed(sender: SipCallingButton) {
        guard let call = activeCall where call.callState == .Confirmed else { return }
        if call.onHold {
            performSegueWithIdentifier(Configuration.Segues.SetupTransfer, sender: self)
        } else {
            do {
                try call.toggleHold()
                performSegueWithIdentifier(Configuration.Segues.SetupTransfer, sender: self)
            } catch let error {
                DDLogWrapper.logError("Error holding current call: \(error)")
            }
        }
    }

    @IBAction func holdButtonPressed(sender: SipCallingButton) {
        guard let call = activeCall else { return }
        do {
            try call.toggleHold()
            updateUI()
        } catch let error {
            DDLogWrapper.logError("Error holding call: \(error)")
        }
    }

    @IBAction func hangupButtonPressed(sender: UIButton) {
        guard let call = activeCall where call.callState != .Disconnected else { return }

        statusLabel.text = NSLocalizedString("Ending call...", comment: "Ending call...")

        do {
            try call.hangup()
            hangupButton.enabled = false
        } catch let error {
            DDLogWrapper.logError("Error ending call: \(error)")
        }
    }

    func handleOutgoingCall(phoneNumber phoneNumber: String, contact: CNContact?) {
        let cleanedPhoneNumber = PhoneNumberUtils.cleanPhoneNumber(phoneNumber)!
        previousAVAudioSessionCategory = avAudioSession.category
        phoneNumberLabelText = cleanedPhoneNumber

        if let contact = contact {
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)) {
                PhoneNumberModel.getCallNameFromContact(contact, andPhoneNumber: phoneNumber, withCompletion: { (phoneNumberModel) in
                    dispatch_async(dispatch_get_main_queue()) { [weak self] in
                        self?.phoneNumberLabelText = phoneNumberModel.callerInfo
                    }
                })
            }
        }

        let account = SIPUtils.addSIPAccountToEndpoint()
        account?.callNumber(cleanedPhoneNumber) { (error, call) in
            UIDevice.currentDevice().proximityMonitoringEnabled = true
            if let error = error, let category = self.previousAVAudioSessionCategory {
                DDLogWrapper.logError("Error setting up call: \(error)")
                do {
                    try self.avAudioSession.setCategory(category)
                } catch let error {
                    DDLogWrapper.logError("Error restoring previous AudioSession: \(error)")
                }
            } else if let call = call {
                self.activeCall = call
            }
        }
    }

    func handleIncomingCall(call: VSLCall) {
        self.previousAVAudioSessionCategory = self.avAudioSession.category
        self.activeCall = call
        phoneNumberLabelText = call.callerNumber

        do {
            try call.answer()
            UIDevice.currentDevice().proximityMonitoringEnabled = true
        } catch let error {
            DDLogWrapper.logError("Error answering call: \(error)")
            do {
                try self.avAudioSession.setCategory(self.previousAVAudioSessionCategory!)
            } catch let error {
                DDLogWrapper.logError("Error restoring previous AudioSession: \(error)")
            }
        }

        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)) {
            PhoneNumberModel.getCallName(call) { (phoneNumberModel) in
                self.phoneNumberLabelText = phoneNumberModel.callerInfo
            }
        }
    }

    // MARK: - Helper functions

    func updateUI() {

        guard let call = activeCall else { return }

        switch call.callState {
        case .Null: fallthrough
        case .Calling: fallthrough
        case .Incoming: fallthrough
        case .Early: fallthrough
        case .Connecting:
            holdButton?.enabled = false
            muteButton?.enabled = false
            transferButton?.enabled = false
            speakerButton?.enabled = true
            hangupButton?.enabled = true
        case .Confirmed:
            holdButton?.enabled = true
            muteButton?.enabled = true
            transferButton?.enabled = true
            speakerButton?.enabled = true
            hangupButton?.enabled = true
        case .Disconnected:
            holdButton?.enabled = false
            muteButton?.enabled = false
            transferButton?.enabled = false
            speakerButton?.enabled = false
            hangupButton?.enabled = false
        }

        // If call is active and not on hold, enable the button.
        keypadButton?.enabled = !call.onHold && call.callState == .Confirmed
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
        case .Null:
            statusLabel?.text = ""
        case .Calling: fallthrough
        case .Early:
            statusLabel?.text = NSLocalizedString("Calling...", comment: "Statuslabel state text .Calling")
        case .Incoming:
            statusLabel?.text = NSLocalizedString("Incoming call...", comment: "Statuslabel state text .Incoming")
        case .Connecting:
            statusLabel?.text = NSLocalizedString("Connecting...", comment: "Statuslabel state text .Connecting")
        case .Confirmed:
            if call.onHold {
                statusLabel?.text = NSLocalizedString("ON HOLD", comment: "On hold")
            } else {
                statusLabel?.text = "\(dateComponentsFormatter.stringFromTimeInterval(call.connectDuration)!)"
            }
        case .Disconnected:
            statusLabel?.text = NSLocalizedString("Call ended", comment: "Statuslabel state text .Disconnected")
            connectDurationTimer?.invalidate()
        }
    }

    private func handleCallEnded() {
        if let category = previousAVAudioSessionCategory {
            do {
                try avAudioSession.setCategory(category)
            } catch let error {
                DDLogWrapper.logError("Error restoring previous AudioSession: \(error)")
            }
        }

        hangupButton?.enabled = false

        var timeToWaitBeforeDismissing = Configuration.Timing.WaitingTimeAfterDismissing

        #if DEBUG
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate where appDelegate.isScreenshotRun {
            timeToWaitBeforeDismissing = 5.0
        }
        #endif

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(timeToWaitBeforeDismissing * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
            if self.activeCall!.incoming {
                self.performSegueWithIdentifier(Configuration.Segues.UnwindToVialerRootViewController, sender: self)
            } else {
                UIDevice.currentDevice().proximityMonitoringEnabled = false
                self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
            }
        }
    }

    private func startConnectDurationTimer() {
        if connectDurationTimer == nil || !connectDurationTimer!.valid {
            connectDurationTimer = NSTimer.scheduledTimerWithTimeInterval(Configuration.Timing.ConnectDurationInterval, target: self, selector: #selector(updateUI), userInfo: nil, repeats: true)
        }
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let keypadVC = segue.destinationViewController as? KeypadViewController {
            keypadVC.call = activeCall
            keypadVC.delegate = self
            keypadVC.phoneNumberLabelText = phoneNumberLabelText
        } else if let navVC = segue.destinationViewController as? UINavigationController, let setupCallTransferVC = navVC.viewControllers[0] as? SetupCallTransferViewController {
            setupCallTransferVC.firstCall = activeCall
            setupCallTransferVC.firstCallPhoneNumberLabelText = phoneNumberLabelText
        }
    }

    @IBAction func unwindToFirstCallSegue(segue: UIStoryboardSegue) {}

    // MARK: - KVO

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &myContext {
            if let call = object as? VSLCall {
                dispatch_async(dispatch_get_main_queue()) { [weak self] in
                    self?.updateUI()
                    if call.callState == .Disconnected {
                        self?.handleCallEnded()
                    }
                }
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }

    // MARK: - KeypadViewControllerDelegate

    func dtmfSent(dtmfSent: String?) {
        self.dtmfSent = dtmfSent
    }
}
