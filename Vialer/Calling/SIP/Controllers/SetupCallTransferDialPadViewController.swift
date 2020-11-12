//
//  SetupCallTransferViewController.swift
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

private var myContext = 0

class SetupCallTransferDialPadViewController: SetupCallTransfer, SegueHandler {
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
        if call.simpleState == .finished {
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
        // This fixes the transparent-line-on-navigation-bar bug
        self.navigationController?.navigationBar.barTintColor = UIColor(red: 0.968627, green: 0.968627, blue: 0.968627, alpha: 1)
         
//        firstCall?.addObserver(self, forKeyPath: "callState", options: .new, context: &myContext)
//        firstCall?.addObserver(self, forKeyPath: "mediaState", options: .new, context: &myContext)
        callObserversSet = true

        VialerGAITracker.trackScreenForController(name: controllerName)
        updateUI()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if callObserversSet {
//            firstCall?.removeObserver(self, forKeyPath: "callState")
//            firstCall?.removeObserver(self, forKeyPath: "mediaState")
            callObserversSet = false
        }
    }
}

// MARK: - Actions
extension SetupCallTransferDialPadViewController {
    @IBAction func backButtonPressed(_ sender: AnyObject) {
        guard let call = currentCall else {
            DispatchQueue.main.async {
                self.performSegue(segueIdentifier: .unwindToFirstCall)
            }
            return
        }
        
        let success = sip.endCall(for: call.session)
        if success == true {
            DispatchQueue.main.async {
                self.performSegue(segueIdentifier: .unwindToFirstCall)
            }
        } else {
            VialerLogError("Could not hang up current call after cancelling.")
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
        beginTransferByCalling(phoneNumber: number)
    }

    @IBAction func zeroButtonLongPress(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            number = number + "+"
        }
    }
}

// MARK: - Utils
extension SetupCallTransferDialPadViewController {
    func beginTransferByCalling(phoneNumber: String) {
        guard let cleanedPhoneNumber = PhoneNumberUtils.cleanPhoneNumber(phoneNumber) else {return}
        transferTargetPhoneNumber = cleanedPhoneNumber
        
        guard let session = sip.call?.session else {return}
        attendedTransferSession = sip.beginAttendedTransfer(session: session, to: cleanedPhoneNumber)
        
        DispatchQueue.main.async { [weak self] in
            self?.performSegue(segueIdentifier: .secondCallActive)
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
        switch segueIdentifier(segue: segue) {
        case .secondCallActive:
            // The second call is active and is a subtype of SIPCallingVC, so cast the destination to it.
            let secondCallVC = segue.destination as? SecondCallViewController
            
            //secondCallVC.activeCall = currentCall
            secondCallVC?.firstCall = firstCall
            secondCallVC?.firstCallPhoneNumberLabelText = firstCallPhoneNumberLabelText
            secondCallVC?.attendedTransferSession = attendedTransferSession
            secondCallVC?.currentCallPhoneNumberLabelText = transferTargetPhoneNumber
            
        case .unwindToFirstCall:
            let callVC = segue.destination as! SIPCallingViewController
            VialerLogInfo("Unwinding to first call: \(String(describing: callVC.nameLabel.text))        \(String(describing: callVC.numberLabel.text)).")
            
            
//            if let call = currentCall, call.callState != .null && call.callState != .disconnected {
//                callVC.activeCall = call
//            } else if let call = firstCall, call.callState != .null && call.callState != .disconnected {
//                callVC.activeCall = call
//            }
        }
    }
}

// MARK: - KVO
extension SetupCallTransferDialPadViewController {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
//        if context == &myContext {
//            DispatchQueue.main.async { [weak self] in
//                self?.updateUI()
//                if let call = self?.firstCall, call.callState == .disconnected {
//                    self?.performSegue(segueIdentifier: .unwindToFirstCall)
//                }
//            }
//        } else {
//            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
//        }
    }
}
