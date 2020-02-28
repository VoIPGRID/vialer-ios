//
//  TransferInProgressViewController.swift
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

private var myContext = 0

class TransferInProgressViewController: UIViewController {
    
    // MARK: - Configuration
    enum SegueIdentifier : String {
        case unwindToVialerRootViewController = "UnwindToVialerRootViewControllerSegue"
    }

    // MARK: - Properties
    var callManager = VialerSIPLib.sharedInstance().callManager
    
    var callObserversSet = false // Keep track if observers are set to prevent removing unset observers.

    var firstCall: VSLCall? {
        didSet {
            firstCall?.addObserver(self, forKeyPath: "callState", options: .new, context: &myContext)
            callObserversSet = true

            updateUI()
        }
    }
    var firstCallPhoneNumberLabelText: String? {
        didSet {
            updateUI()
        }
    }
    var currentCall: VSLCall? {
        didSet {
            updateUI()
        }
    }
    var currentCallPhoneNumberLabelText: String? {
        didSet {
            updateUI()
        }
    }
    lazy var successfullImage = UIImage(asset: .successfullTransfer)
    lazy var rejectedImage = UIImage(asset: .rejectedTransfer)

    // MARK: - Outlets
    @IBOutlet weak var successfullImageView: UIImageView!
    @IBOutlet weak var firstNumberLabel: UILabel!
    @IBOutlet weak var transferStatusLabel: UILabel!
    @IBOutlet weak var currentCallNumberLabel: UILabel!
}

// MARK: - Lifecycle
extension TransferInProgressViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        VialerGAITracker.trackScreenForController(name: controllerName)
        updateUI()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if callObserversSet {
            firstCall?.removeObserver(self, forKeyPath: "callState")
            callObserversSet = false
        }
    }

}

// MARK: - Actions
extension TransferInProgressViewController {
    @IBAction func backButtonPressed(_ sender: UIBarButtonItem) {
        if firstCall?.callState != .disconnected {
            callManager.end(firstCall!) { error in
                if error != nil {
                    VialerLogError("Error disconnecting call: \(error!)")
                }
            }
        }
        if currentCall?.callState != .disconnected {
            callManager.end(currentCall!) { error in
                if error != nil {
                    VialerLogError("Error disconnecting call: \(error!)")
                }
            }
        }
    }
}

// MARK: - Helper functions
extension TransferInProgressViewController {
    fileprivate func updateUI() {
        firstNumberLabel?.text = firstCallPhoneNumberLabelText
        currentCallNumberLabel?.text = currentCallPhoneNumberLabelText

        guard let call = firstCall else { return }

        switch call.transferStatus {
        case .unkown: fallthrough
        case .initialized:
            successfullImageView?.isHidden = true
            transferStatusLabel?.text = NSLocalizedString("Transfer requested for", comment:"Transfer requested for")
        case .trying:
            successfullImageView?.isHidden = true
            transferStatusLabel?.text = NSLocalizedString("Transfer in progress to", comment:"Transfer in progress to")
        case .accepted:
            successfullImageView?.isHidden = false
            successfullImageView?.image = successfullImage
            transferStatusLabel?.text = NSLocalizedString("Successfully connected with", comment:"Successfully connected with")
            VialerGAITracker.callTranferEvent(withSuccess: true)
        case .rejected:
            successfullImageView?.isHidden = false
            successfullImageView?.image = rejectedImage
            transferStatusLabel?.text = NSLocalizedString("Couldn't transfer call to", comment: "Transfer failed")
            VialerGAITracker.callTranferEvent(withSuccess: false)
        }
    }
}

// MARK: - KVO
extension TransferInProgressViewController {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if context == &myContext {
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.updateUI()

                guard let call = object as? VSLCall, call.transferStatus == .accepted || call.transferStatus == .rejected else { return }
                // Call transfer is finished, so end the transferred calls,
                if self!.firstCall?.callState != .disconnected {
                    strongSelf.callManager.end(self!.firstCall!) { error in
                        if error != nil {
                            VialerLogError("Error disconnecting call: \(String(describing: error))")
                        }
                    }
                }
                if self!.currentCall!.callState != .disconnected {
                    strongSelf.callManager.end(self!.currentCall!) { error in
                        if error != nil {
                            VialerLogError("Error disconnecting call: \(String(describing: error))")
                        }
                    }
                }
                
                // Return to the root view controller.
                DispatchQueue.main.async {
                    strongSelf.performSegue(withIdentifier: SegueIdentifier.unwindToVialerRootViewController.rawValue, sender: nil)
                }
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}
