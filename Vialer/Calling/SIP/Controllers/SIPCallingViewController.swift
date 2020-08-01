//
//  SIPCallingViewController.swift
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

import Contacts
import MediaPlayer
import PhoneLib
import CallKit

private var myContext = 0

class SIPCallingViewController: UIViewController, KeypadViewControllerDelegate, SegueHandler {

    private lazy var sip: Sip = {
        (UIApplication.shared.delegate as! AppDelegate).sip
    }()

    private lazy var phone: PhoneLib = {
        PhoneLib.shared
    }()

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

    private var call: Call? {
        get { sip.call }
    }

    private var user: SystemUser {
        get { SystemUser.current()}
    }

    private var dtmf: String = ""

    /**
        The remote number that has been called with the dialed dtmf
        appended.
    */
    private var displayedNumber: String {
        get {
            "\(call?.remoteNumber ?? "") \(dtmf))"
        }
    }

    private lazy var dateComponentsFormatter: DateComponentsFormatter = {
        let dateComponentsFormatter = DateComponentsFormatter()
        dateComponentsFormatter.zeroFormattingBehavior = .pad
        dateComponentsFormatter.allowedUnits = [.minute, .second]
        return dateComponentsFormatter
    }()

    private var connectDurationTimer: Timer?
    
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
}

// MARK: - Lifecycle
extension SIPCallingViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleCallUpdate), name: NSNotification.Name(rawValue: "call-update"), object: nil)

        UIDevice.current.isProximityMonitoringEnabled = true
        updateUI()
        startConnectDurationTimer()

        if call?.simpleState == .finished {
            VialerLogInfo("Ending as state is ended")
            handleCallEnded()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)

        connectDurationTimer?.invalidate()
        UIDevice.current.isProximityMonitoringEnabled = false
    }
}

// MARK: - Actions
extension SIPCallingViewController {

    func performCallAction(action: (_: UUID) -> CXCallAction) {
        guard let uuid = sip.call?.uuid else {
            VialerLogError("Unable to perform action on call as there is no active call")
            return
        }

        let controller = CXCallController()
        let action = action(uuid)

        controller.request(CXTransaction(action: action)) { error in
            if error != nil {
                VialerLogError("Failed to perform \(action.description) \(error?.localizedDescription)")
                self.dismiss(animated: true)
            }
        }
    }

    @IBAction func muteButtonPressed(_ sender: SipCallingButton) {
        performCallAction { uuid in
            CXSetMutedCallAction(call: uuid, muted: true)
        }
    }
    
    @IBAction func keypadButtonPressed(_ sender: SipCallingButton) {
//        dtmfWholeValue += dtmfSingleTimeValue
//        dtmfSingleTimeValue = ""
//        DispatchQueue.main.async {
//            self.performSegue(segueIdentifier: .showKeypad)
//        }
    }
    
    @IBAction func speakerButtonPressed(_ sender: SipCallingButton) {
        phone.setSpeaker(phone.isSpeakerOn ? false : true)
        updateUI()
    }
    
    @IBAction func transferButtonPressed(_ sender: SipCallingButton) {
//        guard let call = activeCall, call.callState == .confirmed else { return }
//        if call.onHold {
//            DispatchQueue.main.async {
//                self.performSegue(segueIdentifier: .setupTransfer)
//            }
//            return
//        }
//        callManager.toggleHold(for: call) { error in
//            if error != nil {
//                VialerLogError("Error holding current call: \(String(describing: error))")
//            } else {
//                DispatchQueue.main.async {
//                    self.performSegue(segueIdentifier: .setupTransfer)
//                }
//            }
//        }
    }
    
    @IBAction func holdButtonPressed(_ sender: SipCallingButton) {
        performCallAction { uuid in
            CXSetHeldCallAction(call: uuid, onHold: true)
        }
    }
    
    @IBAction func hangupButtonPressed(_ sender: UIButton) {
        performCallAction { uuid in
            CXEndCallAction(call: uuid)
        }
    }
}

// MARK: - Call setup
extension SIPCallingViewController {

    fileprivate func dismissView() {
        let waitingTimeAfterDismissing = Config.Timing.waitingTimeAfterDismissing
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(waitingTimeAfterDismissing * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) { [weak self] in
            if self?.sip.call?.direction == Direction.inbound {
                DispatchQueue.main.async {
                    self?.performSegue(segueIdentifier: .unwindToVialerRootViewController)
                }
            } else {
                UIDevice.current.isProximityMonitoringEnabled = false
                self?.presentingViewController?.dismiss(animated: false, completion: nil)
            }
        }
    }
    
    fileprivate func handleCallEnded() {
        VialerLogInfo("handleCallEnded")
        hangupButton?.isEnabled = false
        dismissView()
    }
}

// MARK: - Handling UI updating
extension SIPCallingViewController {
    @objc func updateUI() {
        guard let call = sip.call else {
            VialerLogError("There is no call, dismissing the UI.")
            handleCallEnded()
            return
        }

        if call.simpleState == .finished {
            VialerLogInfo("Ending from UpdateUI as state is \(String(reflecting: call.state)) and UUID  is \(call.uuid)")
            handleCallEnded()
            return
        }

        updateButtons(call: call)
        updateLabels(call: call)
    }

    func updateButtons(call: Call) {
        //        keypadButton?.isEnabled = !PhoneLib.shared.setHold(session: <#T##Session##PhoneLib.Session#>, onHold: <#T##Bool##Swift.Bool#>) && call.session.state == .connected
//        holdButton?.active = call.onHold
        muteButton?.active = phone.isMicrophoneMuted
        speakerButton?.active = phone.isSpeakerOn

        //        if callManager.audioController.hasBluetooth {
//            speakerButton?.buttonImage = "CallButtonBluetooth"
//            speakerLabel?.text = NSLocalizedString("audio", comment: "audio")
//        } else {
        speakerButton?.buttonImage = "CallButtonSpeaker"
        speakerLabel?.text = NSLocalizedString("speaker", comment: "speaker")
//        }

        switch call.simpleState {
        case .initializing, .ringing:
            holdButton?.isEnabled = false
            muteButton?.isEnabled = false
            transferButton?.isEnabled = false
            speakerButton?.isEnabled = true
            hangupButton?.isEnabled = true
        case .inProgress:
            holdButton?.isEnabled = true
            muteButton?.isEnabled = true
            transferButton?.isEnabled = true
            speakerButton?.isEnabled = true
            hangupButton?.isEnabled = true
        case .finished:
            holdButton?.isEnabled = false
            muteButton?.isEnabled = false
            transferButton?.isEnabled = false
            speakerButton?.isEnabled = false
            hangupButton?.isEnabled = false
        }
    }

    func updateLabels(call: Call) {
        numberLabel.text = "Hello"
        nameLabel.text = "Hi there"

        switch call.simpleState {
        case .initializing:
            statusLabel?.text = ""
        case .ringing:
            if call.isIncoming {
                statusLabel?.text = NSLocalizedString("Incoming call...", comment: "Statuslabel state text .Incoming")
            } else {
                statusLabel?.text = NSLocalizedString("Calling...", comment: "Statuslabel state text .Calling")
            }
        case .inProgress:
            //statusLabel?.text = NSLocalizedString("On hold", comment: "On hold")
            statusLabel?.text = "\(dateComponentsFormatter.string(from: TimeInterval(call.duration))!)"
        case .finished:
            statusLabel?.text = NSLocalizedString("Call ended", comment: "Statuslabel state text .Disconnected")
        }
    }
    
    func startConnectDurationTimer() {
        if connectDurationTimer == nil || !connectDurationTimer!.isValid {
            VialerLogInfo("Starting timer..")
            connectDurationTimer = Timer.scheduledTimer(timeInterval: Config.Timing.connectDurationInterval, target: self, selector: #selector(updateUI), userInfo: nil, repeats: true)
        } else {
            VialerLogError("Failed to start timer")
        }
    }
}

// MARK: - Segues
extension SIPCallingViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(segue: segue) {
        case .showKeypad:
            let keypadVC = segue.destination as! KeypadViewController
            keypadVC.call = call
            keypadVC.delegate = self
            keypadVC.phoneNumberLabelText = displayedNumber
        case .setupTransfer:
            let tabBarC = segue.destination as! UITabBarController
            let transferContactListNavC = tabBarC.viewControllers![0] as! UINavigationController
            let transferDialPadNavC = tabBarC.viewControllers![1] as! UINavigationController
            let setupCallTransferContactsVC = transferContactListNavC.viewControllers[0] as! SetupCallTransferContactsViewController
            let setupCallTransferDialPadVC = transferDialPadNavC.viewControllers[0] as! SetupCallTransferDialPadViewController
            setupCallTransferDialPadVC.firstCall = call
            setupCallTransferDialPadVC.firstCallPhoneNumberLabelText = displayedNumber
            
            setupCallTransferContactsVC.firstCall = call
            setupCallTransferContactsVC.firstCallPhoneNumberLabelText = displayedNumber
        case .unwindToVialerRootViewController:
            break
        }
    }
    
    @IBAction func unwindToFirstCallSegue(_ segue: UIStoryboardSegue) {}

    @IBAction func unwindToActiveCallSegue(_ segue: UIStoryboardSegue) {} // Seque used to make the second call the active one when the first call is ended during a transfer setup.

}


// MARK: - KeypadViewControllerDelegate
extension SIPCallingViewController {
    func dtmfSent(_ dtmfSent: String?) {
        self.dtmf += dtmfSent ?? ""
    }
}

extension SIPCallingViewController {
    @objc func handleCallUpdate(_: NSNotification) {
        updateUI()

        VialerLogInfo("State \(String(reflecting: call?.state))")
    }
}
