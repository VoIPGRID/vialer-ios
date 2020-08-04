//
//  SecondCallViewController.swift
//  Copyright © 2016 VoIPGRID. All rights reserved.
//
import PhoneLib

private var myContext = 0

class SecondCallViewController: SIPCallingViewController {

    // MARK: - Configuration
    enum SecondCallVCSegue : String { // TODO: find a way to handle subclassed ViewControllers with SegueHandler.
        case transferInProgress = "TransferInProgressSegue"
        case unwindToFirstCall = "UnwindToFirstCallSegue"
        case showKeypad = "ShowKeypadSegue"
        case unwindToActiveCall = "UnwindToActiveCall"
    }

    // MARK: - Properties
    private var firstCallObserversWereSet = false
    
    var firstCall: Call? {
        didSet {
//            guard let call = firstCall else { return }
//            call.addObserver(self, forKeyPath: "callState", options: .new, context: &myContext)
//            call.addObserver(self, forKeyPath: "mediaState", options: .new, context: &myContext)
            firstCallObserversWereSet = true
            updateUI()
        }
    }
    var firstCallPhoneNumberLabelText: String? {
        didSet {
            updateUI()
        }
    }

    // MARK: - Outlets
    @IBOutlet weak var firstCallNumberLabel: UILabel!
    @IBOutlet weak var firstCallStatusLabel: UILabel!
}

// MARK: - Lifecycle
extension SecondCallViewController{
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        VialerGAITracker.trackScreenForController(name: controllerName)
        UIDevice.current.isProximityMonitoringEnabled = true
        updateUI()
    }

    override func viewWillDisappear(_ animated: Bool) {
        UIDevice.current.isProximityMonitoringEnabled = false
        
        if firstCallObserversWereSet {
//            firstCall?.removeObserver(self, forKeyPath: "callState")
//            firstCall?.removeObserver(self, forKeyPath: "mediaState")
            firstCallObserversWereSet = false
        }
        super.viewWillDisappear(animated)
    }
}

// MARK: - Actions
extension SecondCallViewController {
    override func transferButtonPressed(_ sender: SipCallingButton) {
//        guard let firstCall = firstCall, firstCall.callState == .confirmed,
//            let secondCall = activeCall, firstCall.callState == .confirmed else { return }

//        if firstCall.transfer(to: secondCall) {
//            callManager.end(firstCall) { error in
//                if error != nil {
//                    VialerLogError("Error hanging up call: \(String(describing: error))")
//                }
//            }
//            callManager.end(secondCall) { error in
//                if error != nil {
//                    VialerLogError("Error hanging up call: \(String(describing: error))")
//                }
//            }
//            DispatchQueue.main.async {
//                self.performSegue(withIdentifier: SecondCallVCSegue.transferInProgress.rawValue, sender: nil)
//            }
//        }
    }

    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
//        guard let activeCall = activeCall, activeCall.callState != .disconnected else {
//            DispatchQueue.main.async {
//                self.performSegue(withIdentifier: SecondCallVCSegue.unwindToFirstCall.rawValue, sender: nil)
//            }
//            return
//        }
//        // If current call is not disconnected, hangup the call.
//        callManager.end(activeCall) { error in
//            if error != nil {
//                VialerLogError("Error hanging up call: \(String(describing: error))")
//            } else {
//                DispatchQueue.main.async {
//                    self.performSegue(withIdentifier: SecondCallVCSegue.unwindToFirstCall.rawValue, sender: nil)
//                }
//            }
//        }
    }
}

// MARK: - Helper functions
extension SecondCallViewController {
    override func updateUI() {
//        DispatchQueue.main.async {
//            super.updateUI()
//
//            // Only enable transferButton if both calls are confirmed.
//            self.transferButton?.isEnabled = self.activeCall?.callState == .confirmed && self.firstCall?.callState == .confirmed
//            self.firstCallNumberLabel?.text = self.firstCallPhoneNumberLabelText
//
//            self.numberLabel?.isHidden = false
//            if self.statusLabelTopConstraint != nil {
//                self.statusLabelTopConstraint.constant = 20
//            }
//
//            guard let call = self.firstCall else { return }
//
//            if call.callState == .disconnected {
//                self.firstCallStatusLabel?.text = NSLocalizedString("Disconnected", comment: "Disconnected phone state")
//            } else {
//                self.firstCallStatusLabel?.text = NSLocalizedString("On hold", comment: "On hold")
//            }
//        }
        
    }
}

// MARK: - Segues
extension SecondCallViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch SecondCallVCSegue(rawValue: segue.identifier!)! {
        case .transferInProgress:
            let transferInProgressVC = segue.destination as! TransferInProgressViewController
            transferInProgressVC.firstCall = firstCall
            transferInProgressVC.firstCallPhoneNumberLabelText = firstCallPhoneNumberLabelText
        case .unwindToFirstCall:
            let firstCallVC = segue.destination as! SIPCallingViewController
        case .showKeypad:
            let keypadVC = segue.destination as! KeypadViewController
            keypadVC.delegate = self
        case .unwindToActiveCall:
            let firstCallVC = segue.destination as! SIPCallingViewController
        }
    }
}

// MARK: - KVO
extension SecondCallViewController {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        // If the first call is disconnected and the second call is in progress, unwind to CallViewController.
        // In prepare the second call will be set as the activeCall.
//        if let call = object as? VSLCall, call == firstCall && call.callState == .disconnected && call.transferStatus == .unkown,
//            let activeCall = activeCall, activeCall.callState != .null {
//
//            DispatchQueue.main.async { [weak self] in
//                self?.performSegue(withIdentifier: SecondCallVCSegue.unwindToActiveCall.rawValue, sender: nil)
//            }
//            return
//        }
//
//        if context == &myContext {
//            DispatchQueue.main.async { [weak self] in
//                if let call = self?.activeCall, keyPath == #keyPath(activeCall.callState) && call.callState == .disconnected && self?.firstCall?.transferStatus != .unkown  {
//                    // If the transfer is in progress, the active call will be Disconnected. Perform the segue.
//                    self?.performSegue(withIdentifier: SecondCallVCSegue.transferInProgress.rawValue, sender: nil)
//                }
//                self?.updateUI()
//            }
//        } else {
//            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
//        }
    }
}
