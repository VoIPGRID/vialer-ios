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
    
    var currentCallPhoneNumberLabelText: String? {
        didSet {
            updateUI()
        }
    }
    
    var attendedTransferSession: AttendedTransferSession?
    
    // MARK: - Outlets
    @IBOutlet weak var firstCallNumberLabel: UILabel!
    @IBOutlet weak var firstCallStatusLabel: UILabel!
}

// MARK: - Lifecycle
extension SecondCallViewController{
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        super.presentsSecondCall = true
        sip.secondTransferCall = sip.call 
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
        guard let attendedTransferSession =  self.attendedTransferSession else {return}
        // Merging calls
        let transferSuccess = sip.finishAttendedTransfer(attendedTransferSession: attendedTransferSession)
        
        if transferSuccess == true {
            
//            if let targetCall = self.attendedTransferSession?.to {
//                _ = sip.endCall(for: targetCall) //sip.call = nil //wip
//            }
             
            
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: SecondCallVCSegue.transferInProgress.rawValue, sender: nil)
            }
        } else {
            VialerLogError("Error on merging calls.")
        }
    }

    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        endSecondCallAndUnwindToFirst()
    }
    
    override func hangupButtonPressed(_ sender: UIButton) {
        endSecondCallAndUnwindToFirst()
    }
}

// MARK: - Helper functions
extension SecondCallViewController {
    override func updateUI() {
        DispatchQueue.main.async {
            super.updateUI()
            
            guard let secondCall = self.sip.secondTransferCall else {return}
            if secondCall.simpleState == .finished {
                VialerLogInfo("Unwind to first call from updateUI() as second call has ended.")
                self.performSegue(withIdentifier: SecondCallVCSegue.unwindToFirstCall.rawValue, sender: nil)
            }
            
            // Only enable transferButton if both calls are confirmed.
            self.transferButton?.isEnabled = self.sip.call?.simpleState == .inProgress && self.firstCall?.simpleState == .inProgress
            self.firstCallNumberLabel?.text = self.firstCallPhoneNumberLabelText

            self.numberLabel?.isHidden = false
            if self.statusLabelTopConstraint != nil {
                self.statusLabelTopConstraint.constant = 20
            }

            guard let firstCall = self.firstCall else { return }

            if firstCall.simpleState == .finished {
                self.firstCallStatusLabel?.text = NSLocalizedString("Disconnected", comment: "Disconnected phone state")
            } else {
                self.firstCallStatusLabel?.text = NSLocalizedString("On hold", comment: "On hold")
            }
        }
        
    }
    
// MARK: - Call setup
    func endSecondCallAndUnwindToFirst() { //wip
        guard let transferTargetSession = attendedTransferSession?.to else {return}
        
        let callEndSuccess = sip.endCall(for: transferTargetSession)
        VialerLogInfo("Second call ended with success: \(callEndSuccess). Unwinding back to the first one.")
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
            transferInProgressVC.currentCallPhoneNumberLabelText = currentCallPhoneNumberLabelText
            
            //wip - end all calls? set sip.call and other calls to nil? update UI?
            //sip.call einai to second call of transfer - 209
            //sip.firstTransferCall einai nil
            //sip.secondTransferCall einai to 209
//            if let session = sip.call?.session {
//                VialerLogDebug("Transfer was a success, setting calls to nil.")
//                _ = sip.endCall(for: session)
//                sip.secondTransferCall = nil //wip
//                sip.call = nil
//                sip.firstTransferCall = nil
//            }
            
        case .unwindToFirstCall:
            _ = segue.destination as! SIPCallingViewController
        case .showKeypad:
            let keypadVC = segue.destination as! KeypadViewController
            keypadVC.delegate = self
        case .unwindToActiveCall:
            _ = segue.destination as! SIPCallingViewController
        }
    }
}

// MARK: - KVO
extension SecondCallViewController {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        // If the first call is disconnected and the second call is in progress, unwind to CallViewController.
        // In prepare the second call will be set as the activeCall.
//        if let call = firstCall, call.simpleState == .finished,
//           let activeCall = self.sip.call, activeCall.simpleState != .finished {
//
//            DispatchQueue.main.async { [weak self] in
//                self?.performSegue(withIdentifier: SecondCallVCSegue.unwindToActiveCall.rawValue, sender: nil)
//            }
//            return
//        }
//
//        if context == &myContext {
//            DispatchQueue.main.async { [weak self] in
//                if let call = self?.sip.call, keyPath == #keyPath(call.simpleState) && call.simpleState == .finished && self?.firstCall?.transferStatus != .unkown  {
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
