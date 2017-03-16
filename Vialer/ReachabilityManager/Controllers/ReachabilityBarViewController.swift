//
//  ReachabilityBarViewController.swift
//  Copyright © 2017 VoIPGRID. All rights reserved.
//

import UIKit

class ReachabilityBarViewController: UIViewController {

    fileprivate let notificationCenter = NotificationCenter.default
    fileprivate let currentUser = SystemUser.current()!
    fileprivate let configuration = Configuration.default()!
    fileprivate let reachability = (UIApplication.shared.delegate as! AppDelegate).reachability!

    fileprivate var reachabilityChanged: NotificationToken?
    fileprivate var userLogout: NotificationToken?
    fileprivate var sipDisabled: NotificationToken?
    fileprivate var sipChanged: NotificationToken?

    @IBOutlet weak var twoStepButton: UIButton!
    @IBOutlet weak var informationLabel: UILabel!
}

// MARK: - Lifecycle
extension ReachabilityBarViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        reachabilityChanged = notificationCenter.addObserver(descriptor: Reachability.changed) { [weak self] _ in
            self?.updateLayout()
        }
        userLogout = notificationCenter.addObserver(descriptor: SystemUser.logoutNotification) { [weak self] _ in
            self?.updateLayout()
        }
        sipDisabled = notificationCenter.addObserver(descriptor: SystemUser.sipDisabledNotification) { [weak self] _ in
            self?.updateLayout()
        }
        sipChanged = notificationCenter.addObserver(descriptor: SystemUser.sipChangedNotification) { [weak self] _ in
            self?.updateLayout()
        }
        updateLayout()
    }
}

// MARK: - Helper functions
extension ReachabilityBarViewController {
    func updateLayout() {
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else { return }
            var shouldBeVisible = true
            weakSelf.twoStepButton.isHidden = true

            switch weakSelf.reachability.status {
            case .notReachable:
                weakSelf.informationLabel.text = NSLocalizedString("No connection, cannot call.", comment:"No connection, cannot call.")
            case .reachableVia2G: fallthrough
            case .reachableVia3G:
                if weakSelf.currentUser.sipEnabled {
                    weakSelf.informationLabel.text = NSLocalizedString("Poor connection, Two step calling enabled.", comment:"Poor connection, Two step calling enabled.")
                    weakSelf.twoStepButton.isHidden = false
                } else {
                    weakSelf.informationLabel.text = NSLocalizedString("VoIP disabled, enable in settings", comment:"VoIP disabled, enable in settings")
                }
            case .reachableVia4G: fallthrough
            case .reachableViaWiFi:
                if !weakSelf.currentUser.sipEnabled {
                    weakSelf.informationLabel.text = NSLocalizedString("VoIP disabled, enable in settings", comment:"VoIP disabled, enable in settings")
                } else {
                    weakSelf.informationLabel.text = ""
                    shouldBeVisible = false
                }
            }

            if shouldBeVisible {
                weakSelf.view.backgroundColor = weakSelf.configuration.colorConfiguration.color(forKey: ConfigurationReachabilityBarBackgroundColor)
                weakSelf.view.isHidden = false
            } else {
                weakSelf.view.backgroundColor = nil
                weakSelf.view.isHidden = true
            }
        }
    }
}

// MARK: - Actions
extension ReachabilityBarViewController {
    @IBAction func infoButtonPressed(_ sender: UIButton) {
        let alert = UIAlertController(title: NSLocalizedString("Two step modus", comment:"Two step modus"),
                                      message: NSLocalizedString("Two step modus will setup a call to your phone first and will call the other party when you answer the call.", comment: "Two step modus will setup a call to your phone first and will call the other party when you answer the call."),
                                      andDefaultButtonText: NSLocalizedString("Ok", comment: "Ok"))!
        present(alert, animated: true)
    }
}
