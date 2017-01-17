//
//  SecondCallViewController.swift
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

private var myContext = 0

class SecondCallViewController: SIPCallingViewController {

    // MARK: - Configuration

    private struct Configuration {
        struct Segues {
            static let TransferInProgress = "TransferInProgressSegue"
            static let UnwindToFirstCall = "UnwindToFirstCallSegue"
            static let UnwindToVialerRootViewController = "UnwindToVialerRootViewControllerSegue"
        }
        struct KVO {
            struct Call {
                static let callState = "callState"
            }
        }
    }

    // MARK: - Properties

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

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        VialerGAITracker.trackScreenForController(name: controllerName)
        UIDevice.current.isProximityMonitoringEnabled = true
        updateUI()
        firstCall?.addObserver(self, forKeyPath: Configuration.KVO.Call.callState, options: .new, context: &myContext)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIDevice.current.isProximityMonitoringEnabled = false
        firstCall?.removeObserver(self, forKeyPath: Configuration.KVO.Call.callState)
    }

    // MARK: - Outlets

    @IBOutlet weak var firstCallNumberLabel: UILabel!
    @IBOutlet weak var firstCallStatusLabel: UILabel!

    // MARK: - Actions

    override func transferButtonPressed(_ sender: SipCallingButton) {
        guard let firstCall = firstCall, firstCall.callState == .confirmed,
            let secondCall = activeCall, firstCall.callState == .confirmed else { return }

        if firstCall.transfer(to: secondCall) {
            callManager.end(firstCall) { error in
                if error != nil {
                    VialerLogError("Error hanging up call: \(error)")
                }
            }
            callManager.end(secondCall) { error in
                if error != nil {
                    VialerLogError("Error hanging up call: \(error)")
                }
            }

            performSegue(withIdentifier: Configuration.Segues.TransferInProgress, sender: nil)
        }
    }

    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        guard let activeCall = activeCall, activeCall.callState != .disconnected else {
            performSegue(withIdentifier: Configuration.Segues.UnwindToFirstCall, sender: nil)
            return
        }
        // If current call is not disconnected, hangup the call.
        callManager.end(activeCall) { error in
            if error != nil {
                VialerLogError("Error hanging up call: \(error)")
            } else {
                self.performSegue(withIdentifier: Configuration.Segues.UnwindToFirstCall, sender: nil)
            }
        }
    }

    // MARK: - Helper functions

    override func updateUI() {
        super.updateUI()

        // Only enable transferButton if both calls are confirmed.
        transferButton?.isEnabled = activeCall?.callState == .confirmed && firstCall?.callState == .confirmed

        firstCallNumberLabel?.text = firstCallPhoneNumberLabelText

        guard let call = firstCall else { return }

        if call.callState == .disconnected {
            firstCallStatusLabel?.text = NSLocalizedString("Disconnected", comment: "Disconnected phone state")
        } else {
            firstCallStatusLabel?.text = NSLocalizedString("ON HOLD", comment: "On hold phone state")
        }
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let transferInProgressVC = segue.destination as? TransferInProgressViewController {
            transferInProgressVC.firstCall = firstCall
            transferInProgressVC.firstCallPhoneNumberLabelText = firstCallPhoneNumberLabelText
            transferInProgressVC.currentCall = activeCall
            transferInProgressVC.currentCallPhoneNumberLabelText = phoneNumberLabelText
        } else if let firstCallVC = segue.destination as? SIPCallingViewController {
            if firstCall?.callState == .disconnected {
                firstCallVC.activeCall = activeCall
                firstCallVC.phoneNumberLabelText = phoneNumberLabelText
            } else {
                firstCallVC.activeCall = firstCall
                firstCallVC.phoneNumberLabelText = firstCallPhoneNumberLabelText
            }
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }

    // MARK: - KVO

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {

        // If the first call is disconnected and the second call is in progress, unwind to CallViewController.
        // In prepare the second call will be set as the activeCall.
        if let call = object as? VSLCall, call == firstCall && call.callState == .disconnected && call.transferStatus == .unkown,
            let activeCall = activeCall, activeCall.callState != .null {
            DispatchQueue.main.async { [weak self] in
                self?.performSegue(withIdentifier: Configuration.Segues.UnwindToFirstCall, sender: nil)
            }
            return
        }

        if context == &myContext {
            DispatchQueue.main.async { [weak self] in
                if let call = self?.activeCall, keyPath == Configuration.KVO.Call.callState &&  call.callState == .disconnected && self?.firstCall?.transferStatus != .unkown  {
                    // If the transfer is in progress, the active call will be Disconnected. Perform the segue.
                    self?.performSegue(withIdentifier: Configuration.Segues.TransferInProgress, sender: nil)
                }
                self?.updateUI()
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}
