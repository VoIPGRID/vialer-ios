//
//  KeypadViewController.swift
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

protocol KeypadViewControllerDelegate {
    func dtmfSent(dtmfSent: String?)
}

private var myContext = 0

class KeypadViewController: UIViewController {

    private struct Configuration {
        struct Timing {
            static let ConnectDurationInterval = 1.0
        }
    }

    // MARK: - Properties

    var call: VSLCall?
    var delegate: KeypadViewControllerDelegate?

    var phoneNumberLabelText: String? {
        didSet {
            numberLabel?.text = phoneNumberLabelText
        }
    }

    var dtmfSent: String? {
        didSet {
            delegate?.dtmfSent(dtmfSent)
            numberLabel.text = dtmfSent
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

        call?.addObserver(self, forKeyPath: "callState", options: .New, context: &myContext)
    }

    override func viewWillDisappear(animated: Bool) {
        call?.removeObserver(self, forKeyPath: "callState")
    }

    // MARK: - Outlets

    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!

    // MARK: - Actions

    @IBAction func numberButtonPressed(sender: NumberPadButton) {
        guard let call = call where call.callState != .Disconnected else { return }
        do {
            try call.sendDTMF(sender.number)
            dtmfSent = (dtmfSent ?? "") + sender.number
        } catch let error {
            DDLogWrapper.logError("Error sending DTMF: \(error)")
        }
    }

    @IBAction func endCallButtonPressed(sender: SipCallingButton) {
        guard let call = call where call.callState != .Disconnected else { return }
        do {
            try call.hangup()
        } catch let error {
            DDLogWrapper.logError("Error ending call: \(error)")
        }
    }

    @IBAction func hideButtonPressed(sender: UIButton) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: - Helper functions

    func updateUI() {

        numberLabel.text = phoneNumberLabelText

        guard let call = call else { return }
        switch call.callState {
        case .Null:
            statusLabel.text = ""
        case .Calling: fallthrough
        case .Early:
            statusLabel.text = NSLocalizedString("Calling...", comment: "Statuslabel state text .Calling")
        case .Incoming:
            statusLabel.text = NSLocalizedString("Incoming call...", comment: "Statuslabel state text .Incoming")
        case .Connecting:
            statusLabel.text = NSLocalizedString("Connecting...", comment: "Statuslabel state text .Connecting")
        case .Confirmed:
            if call.onHold {
                statusLabel?.text = NSLocalizedString("ON HOLD", comment: "On hold")
            } else {
                statusLabel?.text = "\(dateComponentsFormatter.stringFromTimeInterval(call.connectDuration)!)"
            }
        case .Disconnected:
            statusLabel.text = NSLocalizedString("Call ended", comment: "Statuslabel state text .Disconnected")
        }
    }

    private func startConnectDurationTimer() {
        if connectDurationTimer == nil || !connectDurationTimer!.valid {
            connectDurationTimer = NSTimer.scheduledTimerWithTimeInterval(Configuration.Timing.ConnectDurationInterval, target: self, selector: #selector(updateUI), userInfo: nil, repeats: true)
        }
    }


    // MARK: - KVO

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &myContext , let call = object as? VSLCall {
            dispatch_async(dispatch_get_main_queue()) { [weak self] in
                self?.updateUI()
                if call.callState == .Disconnected {
                    self?.dismissViewControllerAnimated(true, completion: nil)
                }
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
}
