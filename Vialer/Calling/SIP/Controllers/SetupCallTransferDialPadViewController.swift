//
//  SetupCallTransferViewController.swift
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

private var myContext = 0

class SetupCallTransferDialPadViewController: SetupCallTransfer, SegueHandler {
    var currentCallPhoneNumberLabelText: String?
    var number: String {
        set {
            numberToDialLabel?.text = newValue
            updateUI()
        }
        get {
            return numberToDialLabel.text!
        }
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
    
    override func updateUI() {
        firstCallNumberLabel?.text = firstCallPhoneNumberLabelText
        
        callButton?.isEnabled = number != ""
        deleteButton?.isEnabled = number != ""
        toggleDeleteButton()
        
        guard let call = firstCall else { return }        
        if call.callState == .disconnected {
            firstCallStatusLabel?.text = NSLocalizedString("Disconnected", comment: "Disconnected phone state")
        } else {
            firstCallStatusLabel?.text = NSLocalizedString("On hold", comment: "On hold")
        }
    }
}

// MARK: - Lifecycle
extension SetupCallTransferDialPadViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        firstCall?.addObserver(self, forKeyPath: "callState", options: .new, context: &myContext)
        firstCall?.addObserver(self, forKeyPath: "mediaState", options: .new, context: &myContext)
        callObserversSet = true

        VialerGAITracker.trackScreenForController(name: controllerName)
        updateUI()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if callObserversSet {
            firstCall?.removeObserver(self, forKeyPath: "callState")
            firstCall?.removeObserver(self, forKeyPath: "mediaState")
            callObserversSet = false
        }
    }
}

// MARK: - Actions
extension SetupCallTransferDialPadViewController {
    @IBAction func backButtonPressed(_ sender: AnyObject) {
        guard let call = currentCall else {
            performSegue(segueIdentifier: .unwindToFirstCall)
            return
        }
        callManager.end(call) { error in
            if error != nil {
                VialerLogError("Could not hangup call: \(String(describing: error))")
            } else {
                self.performSegue(segueIdentifier: .unwindToFirstCall)
            }
        }
    }

    @IBAction func deleteButtonPressed(_ sender: UIButton) {
        number = String(number.dropLast())
    }

    @IBAction func deleteButtonLongPress(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            number = ""
        }
    }

    @IBAction func keypadButtonPressed(_ sender: NumberPadButton) {
        number = number + sender.number
    }

    @IBAction func callButtonPressed(_ sender: UIButton) {
        callButton.isEnabled = false
        guard let number = numberToDialLabel.text, number != "" else {
            callButton.isEnabled = true
            return
        }
        let cleanedPhoneNumber = PhoneNumberUtils.cleanPhoneNumber(number) ?? ""
        currentCallPhoneNumberLabelText = cleanedPhoneNumber
        callManager.startCall(toNumber: cleanedPhoneNumber, for: firstCall!.account!) { call, error in
            DispatchQueue.main.async { [weak self] in
                self?.currentCall = call
                self?.performSegue(segueIdentifier: .secondCallActive)
            }
        }
    }

    @IBAction func zeroButtonLongPress(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            number = number + "+"
        }
    }
}

// MARK: - Helper functions
extension SetupCallTransferDialPadViewController {
    private func toggleDeleteButton () {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
            self.deleteButton?.alpha = self.number.count == 0 ? 0.0 : 1.0
        }, completion:nil)
    }
}

// MARK: - Segues
extension SetupCallTransferDialPadViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // First check if the destinationVC is SecondCallVC, because SecondCallVC is also subtype of SIPCallingVC. TODO: Where is this done?
        switch segueIdentifier(segue: segue) {
        case .secondCallActive:
            let secondCallVC = segue.destination as! SecondCallViewController
            secondCallVC.activeCall = currentCall
            secondCallVC.firstCall = firstCall
            secondCallVC.phoneNumberLabelText = currentCallPhoneNumberLabelText
            secondCallVC.firstCallPhoneNumberLabelText = firstCallPhoneNumberLabelText
        case .unwindToFirstCall:
            let callVC = segue.destination as! SIPCallingViewController
            if let call = currentCall, call.callState != .null && call.callState != .disconnected {
                callVC.activeCall = call
            } else if let call = firstCall, call.callState != .null && call.callState != .disconnected {
                callVC.activeCall = call
            }
        }
    }
}

// MARK: - KVO
extension SetupCallTransferDialPadViewController {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &myContext {
            DispatchQueue.main.async { [weak self] in
                self?.updateUI()
                if let call = self?.firstCall, call.callState == .disconnected {
                    self?.performSegue(segueIdentifier: .unwindToFirstCall)
                }
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}
