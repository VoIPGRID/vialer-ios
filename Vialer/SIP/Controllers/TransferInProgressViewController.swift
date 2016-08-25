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
    var firstCallPhoneNumberLabelText: String? {
        didSet {
            updateUI()
        }
    }

    var secondCall: VSLCall? {
        didSet {
            updateUI()
        }
    }
    var secondCallPhoneNumberLabelText: String? {
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

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        firstCall?.addObserver(self, forKeyPath: Configuration.KVO.FirstCall.transferStatus, options: .New, context: &myContext)
        updateUI()
        if let call = firstCall where call.transferStatus == .Accepted || call.transferStatus == .Rejected {
            self.prepareForDismissing()
        }
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        firstCall?.removeObserver(self, forKeyPath: Configuration.KVO.FirstCall.transferStatus)
    }

    // MARK: - Outlets

    @IBOutlet weak var successFullImageView: UIImageView!
    @IBOutlet weak var firstNumberLabel: UILabel!
    @IBOutlet weak var transferStatusLabel: UILabel!
    @IBOutlet weak var secondNumberLabel: UILabel!

    // MARK: - Actions

    @IBAction func backButtonPressed(sender: UIBarButtonItem) {
        do {
            try firstCall?.hangup()
            try secondCall?.hangup()
        } catch let error {
            DDLogWrapper.logError("Error disconnecting call: \(error)")
        }
        dismissView()
    }

    // MARK: - Helper functions

    private func updateUI() {
        firstNumberLabel?.text = firstCallPhoneNumberLabelText
        secondNumberLabel?.text = secondCallPhoneNumberLabelText

        guard let call = firstCall else { return }

        switch call.transferStatus {
        case .Unkown: fallthrough
        case .Initialized:
            successFullImageView?.hidden = true
            transferStatusLabel?.text = NSLocalizedString("Transfer requested for", comment:"Transfer requested for")
        case .Trying:
            successFullImageView?.hidden = true
            transferStatusLabel?.text = NSLocalizedString("Transfer in progress to", comment:"Transfer in progress to")
        case .Accepted:
            successFullImageView?.hidden = false
            successFullImageView?.image = successfullImage
            transferStatusLabel?.text = NSLocalizedString("Successfully connected with", comment:"Successfully connected with")
        case .Rejected:
            successFullImageView?.hidden = false
            successFullImageView?.image = rejectedImage
            transferStatusLabel?.text = NSLocalizedString("Couldn't transfer call to", comment: "Transfer failed")
        }
    }

    private func prepareForDismissing() {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(Configuration.UnwindTiming * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
            self.dismissView()
        }
    }

    private func dismissView() {
        self.performSegueWithIdentifier(Configuration.Segues.UnwindToFirstCallViewController, sender: nil)
    }

    // MARK: - KVO

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &myContext {
            dispatch_async(dispatch_get_main_queue()) { [weak self] in
                self?.updateUI()

                if let call = object as? VSLCall where call.transferStatus == .Accepted || call.transferStatus == .Rejected {
                    do {
                        try self?.firstCall?.hangup()
                        try self?.secondCall?.hangup()
                    } catch let error {
                        DDLogWrapper.logError("Error disconnecting call: \(error)")
                    }
                    self?.prepareForDismissing()
                }
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }

}
