//
//  TransferInProgressViewController.swift
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

private var myContext = 0

class TransferInProgressViewController: UIViewController {

    // MARK: - Configuration

    private struct Configuration {
        struct Segues {
            static let UnwindToFirstCallViewController = "UnwindToFirstCallViewControllerSegue"
        }
        struct KVO {
            struct FirstCall {
                static let transferStatus = "transferStatus"
            }
        }
        static let UnwindTiming = 2.0
    }

    // MARK: - Properties

    var firstCall: VSLCall? {
        didSet {
            updateUI()
        }
    }

    var callManager: VSLCallManager {
        get {
            return VialerSIPLib.sharedInstance().callManager
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

    lazy var successfullImage: UIImage = {
        let image = UIImage(named: "successfullTransfer")!
        return image
    }()

    lazy var rejectedImage: UIImage = {
        let image = UIImage(named: "rejectedTransfer")!
        return image
    }()

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        VialerGAITracker.trackScreenForController(name: controllerName)
        firstCall?.addObserver(self, forKeyPath: Configuration.KVO.FirstCall.transferStatus, options: .new, context: &myContext)
        updateUI()
        if let call = firstCall, call.transferStatus == .accepted || call.transferStatus == .rejected {
            self.prepareForDismissing()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        firstCall?.removeObserver(self, forKeyPath: Configuration.KVO.FirstCall.transferStatus)
    }

    // MARK: - Outlets

    @IBOutlet weak var successFullImageView: UIImageView!
    @IBOutlet weak var firstNumberLabel: UILabel!
    @IBOutlet weak var transferStatusLabel: UILabel!
    @IBOutlet weak var currentCallNumberLabel: UILabel!

    // MARK: - Actions

    @IBAction func backButtonPressed(_ sender: UIBarButtonItem) {
        callManager.end(firstCall!) { error in
            if error != nil {
                DDLogWrapper.logError("Error disconnecting call: \(error)")
            }
        }
        callManager.end(currentCall!) { error in
            if error != nil {
                DDLogWrapper.logError("Error disconnecting call: \(error)")
            }
        }
        dismissView()
    }

    // MARK: - Helper functions

    private func updateUI() {
        firstNumberLabel?.text = firstCallPhoneNumberLabelText
        currentCallNumberLabel?.text = currentCallPhoneNumberLabelText

        guard let call = firstCall else { return }

        switch call.transferStatus {
        case .unkown: fallthrough
        case .initialized:
            successFullImageView?.isHidden = true
            transferStatusLabel?.text = NSLocalizedString("Transfer requested for", comment:"Transfer requested for")
        case .trying:
            successFullImageView?.isHidden = true
            transferStatusLabel?.text = NSLocalizedString("Transfer in progress to", comment:"Transfer in progress to")
        case .accepted:
            successFullImageView?.isHidden = false
            successFullImageView?.image = successfullImage
            transferStatusLabel?.text = NSLocalizedString("Successfully connected with", comment:"Successfully connected with")
            VialerGAITracker.callTranferEvent(withSuccess: true)
        case .rejected:
            successFullImageView?.isHidden = false
            successFullImageView?.image = rejectedImage
            transferStatusLabel?.text = NSLocalizedString("Couldn't transfer call to", comment: "Transfer failed")
            VialerGAITracker.callTranferEvent(withSuccess: false)
        }
    }

    private func prepareForDismissing() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(Configuration.UnwindTiming * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
            self.dismissView()
        }
    }

    private func dismissView() {
        self.performSegue(withIdentifier: Configuration.Segues.UnwindToFirstCallViewController, sender: nil)
    }

    // MARK: - KVO

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &myContext {
            DispatchQueue.main.async { [weak self] in
                self?.updateUI()

                if let call = object as? VSLCall, call.transferStatus == .accepted || call.transferStatus == .rejected {
                    self?.callManager.end(self!.firstCall!) { error in
                        if error != nil {
                            DDLogWrapper.logError("Error disconnecting call: \(error)")
                        }
                    }
                    self?.callManager.end(self!.currentCall!) { error in
                        if error != nil {
                            DDLogWrapper.logError("Error disconnecting call: \(error)")
                        }
                    }
                    self?.prepareForDismissing()
                }
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}
