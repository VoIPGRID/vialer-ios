//
//  SetupCallTransferViewController.swift
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

private var myContext = 0

class SetupCallTransferViewController: UIViewController {

    // MARK: - Configuration

    private struct Configuration {
        struct Segues {
            static let UnwindToFirstCall = "UnwindToFirstCallSegue"
            static let SecondCallActive = "SecondCallActiveSegue"
        }
        struct KVO {
            struct Call {
                static let callState = "callState"
            }
        }
    }

    // Properties

    var firstCall: VSLCall? {
        didSet {
            updateUI()
        }
    }

    var firstCallPhoneNumberLabelText: String? {
        didSet {
            updateUI()
        }
    }

    var currentCall: VSLCall?
    var currentCallPhoneNumberLabelText: String?

    var number: String {
        set {
            numberToDialLabel?.text = newValue
            callButton?.enabled = newValue != ""
            deleteButton?.enabled = newValue != ""
        }
        get {
            return numberToDialLabel.text!
        }

    }

    // MARK: - Lifecycle

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        VialerGAITracker.trackScreenForController(name: controllerName)
        updateUI()
        firstCall?.addObserver(self, forKeyPath: Configuration.KVO.Call.callState, options: .New, context: &myContext)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        firstCall?.removeObserver(self, forKeyPath: Configuration.KVO.Call.callState)
    }

    // MARK: - Outlets
    @IBOutlet weak var firstCallNumberLabel: UILabel!
    @IBOutlet weak var firstCallStatusLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var numberToDialLabel: UILabel! {
        didSet {
            numberToDialLabel.text = ""
        }
    }


    // MARK: - Actions

    @IBAction func backButtonPressed(sender: AnyObject) {
        do {
            try currentCall?.hangup()
            performSegueWithIdentifier(Configuration.Segues.UnwindToFirstCall, sender: self)
        } catch let error {
            DDLogWrapper.logError("Could not hangup call: \(error)")
        }
    }

    @IBAction func deleteButtonPressed(sender: UIButton) {
        number = number.substringToIndex(number.endIndex.advancedBy(-1))
    }

    @IBAction func keypadButtonPressed(sender: NumberPadButton) {
        number = number + sender.number
    }

    @IBAction func callButtonPressed(sender: UIButton) {
        callButton.enabled = false
        if let number = numberToDialLabel.text where number != "" {
            let cleanedPhoneNumber = PhoneNumberUtils.cleanPhoneNumber(number)!
            currentCallPhoneNumberLabelText = cleanedPhoneNumber
            firstCall?.account.callNumber(cleanedPhoneNumber) { (error, call) in
                dispatch_async(dispatch_get_main_queue()) { [weak self] in
                    self?.currentCall = call
                    self?.performSegueWithIdentifier(Configuration.Segues.SecondCallActive, sender: nil)
                }
            }
        }
    }

    // MARK: - Helper functions

    private func updateUI() {
        firstCallNumberLabel?.text = firstCallPhoneNumberLabelText

        guard let call = firstCall else { return }

        if call.callState == .Disconnected {
            firstCallStatusLabel?.text = NSLocalizedString("Disconnected", comment: "Disconnected phone state")
        } else {
            firstCallStatusLabel?.text = NSLocalizedString("ON HOLD", comment: "On hold phone state")
        }
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // First check if the destinationVC is SecondCallVC, because SecondCallVC is also subtype of SIPCallingVC.
        if let secondCallVC = segue.destinationViewController as? SecondCallViewController {
            secondCallVC.activeCall = currentCall
            secondCallVC.firstCall = firstCall
            secondCallVC.phoneNumberLabelText = currentCallPhoneNumberLabelText
            secondCallVC.firstCallPhoneNumberLabelText = firstCallPhoneNumberLabelText
        } else if let callVC = segue.destinationViewController as? SIPCallingViewController {
            if let call = currentCall where call.callState != .Null && call.callState != .Disconnected {
                callVC.activeCall = call
            } else if let call = firstCall where call.callState != .Null && call.callState != .Disconnected {
                callVC.activeCall = call
            }
        }
    }

    // MARK: - KVO

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &myContext {
            dispatch_async(dispatch_get_main_queue()) { [weak self] in
                self?.updateUI()
                if let call = self?.firstCall where call.callState == .Disconnected {
                    self?.performSegueWithIdentifier(Configuration.Segues.UnwindToFirstCall, sender: nil)
                }
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }

}