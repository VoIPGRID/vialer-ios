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

    var currentCall: VSLCall? {
        didSet {
            updateUI()
        }
    }

    var phoneNumberLabelText: String? {
        didSet {
            updateUI()
        }
    }

    var newCall: VSLCall?
    var newPhoneNumberLabelText: String?

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
        currentCall?.addObserver(self, forKeyPath: Configuration.KVO.Call.callState, options: .New, context: &myContext)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        currentCall?.removeObserver(self, forKeyPath: Configuration.KVO.Call.callState)
    }

    // MARK: - Outlets
    @IBOutlet weak var currentCallNumberLabel: UILabel!
    @IBOutlet weak var currentCallStatusLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var numberToDialLabel: UILabel! {
        didSet {
            numberToDialLabel.text = ""
        }
    }


    // MARK: - Actions

    @IBAction func backButtonPressed(sender: AnyObject) {
        performSegueWithIdentifier(Configuration.Segues.UnwindToFirstCall, sender: self)
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
            newPhoneNumberLabelText = cleanedPhoneNumber
            currentCall?.account.callNumber(cleanedPhoneNumber) { (error, call) in
                dispatch_async(dispatch_get_main_queue()) { [weak self] in
                    self?.newCall = call
                    self?.performSegueWithIdentifier(Configuration.Segues.SecondCallActive, sender: nil)
                }
            }
        }
    }

    // MARK: - Helper functions

    private func updateUI() {
        currentCallNumberLabel?.text = phoneNumberLabelText

        guard let call = currentCall else { return }

        if call.callState == .Disconnected {
            currentCallStatusLabel?.text = NSLocalizedString("Disconnected", comment: "Disconnected phone state")
        } else {
            currentCallStatusLabel?.text = NSLocalizedString("ON HOLD", comment: "On hold phone state")
        }
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // First check if the destinationVC is SecondCallVC, because SecondCallVC is also subtype of SIPCallingVC.
        if let secondCallVC = segue.destinationViewController as? SecondCallViewController {
            secondCallVC.activeCall = newCall
            secondCallVC.firstCall = currentCall
            secondCallVC.phoneNumberLabelText = newPhoneNumberLabelText
            secondCallVC.firstCallPhoneNumberLabelText = phoneNumberLabelText
        } else if let callVC = segue.destinationViewController as? SIPCallingViewController {
            if let call = newCall where call.callState != .Null && call.callState != .Disconnected {
                callVC.activeCall = call
            } else if let call = currentCall where call.callState != .Null && call.callState != .Disconnected {
                callVC.activeCall = call
            }
        }
    }

    // MARK: - KVO

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &myContext {
            dispatch_async(dispatch_get_main_queue()) { [weak self] in
                self?.updateUI()
                if let call = self?.currentCall where call.callState == .Disconnected {
                    self?.performSegueWithIdentifier(Configuration.Segues.UnwindToFirstCall, sender: nil)
                }
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }

}