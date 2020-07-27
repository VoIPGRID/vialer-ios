//
//  KeypadViewController.swift
//  Copyright © 2016 VoIPGRID. All rights reserved.
//
import PhoneLib

protocol KeypadViewControllerDelegate {
    func dtmfSent(_ dtmfSent: String?)
}

private var myContext = 0

class KeypadViewController: UIViewController {

    private struct Configuration {
        struct Timing {
            static let ConnectDurationInterval = 1.0
        }
    }

    // MARK: - Properties
    var call: Session?
    var delegate: KeypadViewControllerDelegate?
//    var callManager: VSLCallManager {
//        get {
//            return VialerSIPLib.sharedInstance().callManager
//        }
//    }

    var phoneNumberLabelText: String? {
        didSet {
            numberLabel?.text = phoneNumberLabelText
        }
    }

    var dtmfSent: String? {
        didSet {
            delegate?.dtmfSent(dtmfSent)
            DispatchQueue.main.async { [weak self] in
                self?.numberLabel.text = self?.dtmfSent
            }
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        VialerGAITracker.trackScreenForController(name: controllerName)
        updateUI()

//        call?.addObserver(self, forKeyPath: "callState", options: .new, context: &myContext)
        startConnectDurationTimer()
    }

    override func viewWillDisappear(_ animated: Bool) {
//        call?.removeObserver(self, forKeyPath: "callState")

        dtmfSent = nil
        self.updateUI()
    }

    // MARK: - Outlets

    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!

    // MARK: - Actions

    @IBAction func numberButtonPressed(_ sender: NumberPadButton) {
//        guard let call = call, call.callState != .disconnected else { return }
//        DispatchQueue.main.async{ [weak self] in
//            if let numberPressed = sender.number {
//                self?.callManager.sendDTMF(for: call, character: numberPressed) { error in
//                    if error != nil {
//                        VialerLogError("Error sending DTMF: \(String(describing: error))")
//                    } else {
//                        self?.dtmfSent = (self?.dtmfSent ?? "") + numberPressed
//                    }
//                }
//            }
//        }
    }

    @IBAction func endCallButtonPressed(_ sender: SipCallingButton) {
//        guard let call = call, call.callState != .disconnected else { return }
//        callManager.end(call) { error in
//            if error != nil {
//                VialerLogError("Error ending call: \(String(describing: error))")
//            }
//        }
    }

    @IBAction func hideButtonPressed(_ sender: UIButton) {
        if let navController = self.navigationController {
            navController.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }

    // MARK: - Helper functions

    @objc func updateUI() {

//        numberLabel.text = dtmfSent ?? phoneNumberLabelText
//
//        guard let call = call else { return }
//        switch call.callState {
//        case .null:
//            statusLabel.text = ""
//        case .calling: fallthrough
//        case .early:
//            statusLabel.text = NSLocalizedString("Calling...", comment: "Statuslabel state text .Calling")
//        case .incoming:
//            statusLabel.text = NSLocalizedString("Incoming call...", comment: "Statuslabel state text .Incoming")
//        case .connecting:
//            statusLabel.text = NSLocalizedString("Connecting...", comment: "Statuslabel state text .Connecting")
//        case .confirmed:
//            if call.onHold {
//                statusLabel?.text = NSLocalizedString("On hold", comment: "On hold")
//            } else {
//                statusLabel?.text = "\(dateComponentsFormatter.string(from: call.connectDuration)!)"
//            }
//        case .disconnected:
//            statusLabel.text = NSLocalizedString("Call ended", comment: "Statuslabel state text .Disconnected")
//        }
    }

    private func startConnectDurationTimer() {
        if connectDurationTimer == nil || !connectDurationTimer!.isValid {
            connectDurationTimer = Timer.scheduledTimer(timeInterval: Configuration.Timing.ConnectDurationInterval, target: self, selector: #selector(updateUI), userInfo: nil, repeats: true)
        }
    }

    // MARK: - KVO

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
//        if context == &myContext , let call = object as? VSLCall {
//            DispatchQueue.main.async { [weak self] in
//                self?.updateUI()
//                if call.callState == .disconnected {
//                    if let navController = self?.navigationController {
//                        navController.popViewController(animated: true)
//                    } else {
//                        self?.dismiss(animated: true, completion: nil)
//                    }
//                }
//            }
//        } else {
//            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
//        }
    }
}
