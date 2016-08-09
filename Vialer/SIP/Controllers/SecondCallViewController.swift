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

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
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

    // MARK: - Actions

    override func transferButtonPressed(sender: SipCallingButton) {
        guard let firstCall = firstCall where firstCall.callState == .Confirmed,
            let secondCall = activeCall where firstCall.callState == .Confirmed else { return }

        if firstCall.transferToCall(secondCall) {
            performSegueWithIdentifier(Configuration.Segues.TransferInProgress, sender: nil)
        }
    }

    @IBAction func cancelButtonPressed(sender: UIBarButtonItem) {
        // If current call is not disconnected, hangup the call.
        if let activeCall = activeCall where activeCall.callState != .Disconnected {
            do {
                try activeCall.hangup()
            } catch let error {
                DDLogWrapper.logError("Error hanging up call: \(error)")
            }
        }

        // Unwind to first call.
        performSegueWithIdentifier(Configuration.Segues.UnwindToFirstCall, sender: nil)
    }

    // MARK: - Helper functions

    override func updateUI() {
        super.updateUI()

        // Only enable transferButton if both calls are confirmed.
        transferButton?.enabled = activeCall?.callState == .Confirmed && firstCall?.callState == .Confirmed

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
        if let transferInProgressVC = segue.destinationViewController as? TransferInProgressViewController {
            transferInProgressVC.firstCall = firstCall
            transferInProgressVC.firstCallPhoneNumberLabelText = firstCallPhoneNumberLabelText
            transferInProgressVC.secondCall = activeCall
            transferInProgressVC.secondCallPhoneNumberLabelText = phoneNumberLabelText
        } else if let firstCallVC = segue.destinationViewController as? SIPCallingViewController {
            if firstCall?.callState == .Disconnected {
                firstCallVC.activeCall = activeCall
                firstCallVC.phoneNumberLabelText = phoneNumberLabelText
            } else {
                firstCallVC.activeCall = firstCall
                firstCallVC.phoneNumberLabelText = firstCallPhoneNumberLabelText
            }
        } else {
            super.prepareForSegue(segue, sender: sender)
        }
    }

    // MARK: - KVO

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {

        // If the first call is disconnected and the second call is in progress, unwind to CallViewController.
        // In prepare the second call will be set as the activeCall.
        if let call = object as? VSLCall where call == firstCall && call.callState == .Disconnected && call.transferStatus == .Unkown,
            let activeCall = activeCall where activeCall.callState != .Null {
            dispatch_async(dispatch_get_main_queue()) { [weak self] in
                self?.performSegueWithIdentifier(Configuration.Segues.UnwindToFirstCall, sender: nil)
            }
            return
        }

        if context == &myContext {
            dispatch_async(dispatch_get_main_queue()) { [weak self] in
                if let call = self?.activeCall where keyPath == Configuration.KVO.Call.callState &&  call.callState == .Disconnected && self?.firstCall?.transferStatus != .Unkown  {
                    // If the transfer is in progress, the active call will be Disconnected. Perform the segue.
                    self?.performSegueWithIdentifier(Configuration.Segues.TransferInProgress, sender: nil)
                }
                self?.updateUI()
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }

    }
}
