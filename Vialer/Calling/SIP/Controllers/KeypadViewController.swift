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
    var call: Call?
    var delegate: KeypadViewControllerDelegate?
    
    lazy var sip: Sip = {
        (UIApplication.shared.delegate as! AppDelegate).sip
    }()

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
        guard let call = call, call.simpleState != .finished else { return }
        DispatchQueue.main.async{ [weak self] in
            if let numberPressed = sender.number {
                self?.sip.sendDtmf(session: call.session, dtmf: numberPressed)
                self?.dtmfSent = (self?.dtmfSent ?? "") + numberPressed
            }
        }
    }

    @IBAction func endCallButtonPressed(_ sender: SipCallingButton) {
        guard let call = call, call.simpleState != .finished else { return }
        let success = sip.endCall(for: call.session)
        if success != true {
            VialerLogError("Error ending call with uuid: \(String(describing: call.uuid))")
        }
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
        numberLabel.text = dtmfSent ?? phoneNumberLabelText
        
        if call?.simpleState != .finished && call != nil {
            statusLabel.text = "\(dateComponentsFormatter.string(from: TimeInterval(call!.duration))!)"
        } else {
            statusLabel.text = NSLocalizedString("Call ended", comment: "Statuslabel state text .finished")
        }
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
