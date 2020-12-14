//
//  DialerViewController.swift
//  Copyright © 2017 VoIPGRID. All rights reserved.
//

import UIKit
import AVFoundation

class DialerViewController: UIViewController, SegueHandler {

    private lazy var sip: Sip = {
        (UIApplication.shared.delegate as! AppDelegate).sip
    }()

    enum SegueIdentifier: String {
        case sipCalling = "SIPCallingSegue"
        case twoStepCalling = "TwoStepCallingSegue"
        case reachabilityBar = "ReachabilityBarSegue"
    }

    fileprivate struct Config {
        struct ReachabilityBar {
            static let animationDuration = 0.3
            static let height: CGFloat = 30.0
        }
    }

    // MARK: - Properties
    var numberText: String? {
        didSet {
            if let number = numberText {
                numberText = PhoneNumberUtils.cleanPhoneNumber(number)
            }
            numberLabel.text = numberText
            setupButtons()
        }
    }
    var sounds = [String: AVAudioPlayer]()
    var lastCalledNumber: String? {
        didSet {
            setupButtons()
        }
    }
    var user = SystemUser.current()!
    fileprivate let reachability = ReachabilityHelper.instance.reachability!
    fileprivate var notificationCenter = NotificationCenter.default
    fileprivate var reachabilityChanged: NotificationToken?
    fileprivate var sipDisabled: NotificationToken?
    fileprivate var sipChanged: NotificationToken?
    fileprivate var encryptionUsageChanged: NotificationToken?
    
    // MARK: - Outlets
    @IBOutlet weak var leftDrawerButton: UIBarButtonItem!
    @IBOutlet weak var numberLabel: PasteableUILabel! {
        didSet {
            numberLabel.delegate = self
        }
    }
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var reachabilityBarHeigthConstraint: NSLayoutConstraint!
    @IBOutlet weak var reachabilityBar: UIView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }
}

// MARK: - Lifecycle
extension DialerViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        setupSounds()
        reachabilityChanged = notificationCenter.addObserver(descriptor: Reachability.changed) { [weak self] _ in
            self?.updateReachabilityBar()
        }
        sipDisabled = notificationCenter.addObserver(descriptor: SystemUser.sipDisabledNotification) { [weak self] _ in
            self?.updateReachabilityBar()
        }
        sipChanged = notificationCenter.addObserver(descriptor: SystemUser.sipChangedNotification) { [weak self] _ in
            self?.updateReachabilityBar()
        }
        encryptionUsageChanged = notificationCenter.addObserver(descriptor:SystemUser.encryptionUsageNotification) { [weak self] _ in
            self?.updateReachabilityBar()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateReachabilityBar()
        VialerGAITracker.trackScreenForController(name: controllerName)
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category(rawValue: AVAudioSession.Category.ambient.rawValue))
        setupButtons()
    }
}

// MARK: - Actions
extension DialerViewController {
    @IBAction func leftDrawerButtonPressed(_ sender: UIBarButtonItem) {
        mm_drawerController.toggle(.left, animated: true, completion: nil)
    }

    @IBAction func deleteButtonPressed(_ sender: UIButton) {
        if let number = numberText {
            numberText = String(number.dropLast())
            setupButtons()
        }
    }

    @IBAction func deleteButtonLongPress(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            numberText = nil
        }
    }

    @IBAction func callButtonPressed(_ sender: UIButton) {
        guard numberText != nil else {
            numberText = lastCalledNumber
            return
        }

        lastCalledNumber = numberText
        
        let group = DispatchGroup()
        group.enter()
        
        MicPermissionHelper.requestMicrophonePermission { startCalling in
            if !startCalling {
                DispatchQueue.main.async {
                    let alert = MicPermissionHelper.createMicPermissionAlert()
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            group.leave()
        }

        group.notify(queue: .main) {
            if ReachabilityHelper.instance.connectionFastEnoughForVoIP() {
                DispatchQueue.main.async {
                    self.sip.register { error in
                        if (error == nil) {
                            self.performSegue(segueIdentifier: .sipCalling)
                        } else {
                            VialerLogError("Failed to register when attempting outgoing call \(String(describing: error?.localizedDescription))")
                            self.present(RegistrationFailedAlert.create(), animated: true)
                        }
                    }
                }
            } else {
                VialerGAITracker.setupOutgoingConnectABCallEvent()
                DispatchQueue.main.async {
                    self.performSegue(segueIdentifier: .twoStepCalling)
                }
            }
        }
    }

    @IBAction func numberPressed(_ sender: NumberPadButton) {
        numberPadPressed(character: sender.number)
        playSound(character: sender.number)
    }

    @IBAction func zeroButtonLongPress(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            playSound(character: "0")
            numberPadPressed(character: "+")
        }
    }
}

// MARK: - Segues
extension DialerViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(segue: segue) {
        case .sipCalling:
            _ = self.sip.call(number: self.numberText ?? "")
            numberText = nil
        case .twoStepCalling:
            let twoStepCallingVC = segue.destination as! TwoStepCallingViewController
            twoStepCallingVC.handlePhoneNumber(numberText ?? "")
            numberText = nil
        case .reachabilityBar:
            break
        }
    }
}

// MARK: - PasteableUILabelDelegate
extension DialerViewController : PasteableUILabelDelegate {
    func pasteableUILabel(_ label: UILabel!, didReceivePastedText text: String!) {
        numberText = text
    }
}

// MARK: - Helper functions layout
extension DialerViewController {
    fileprivate func setupUI() {
        title = NSLocalizedString("Keypad", comment: "Keypad")
        tabBarItem.image = UIImage(asset: .tabKeypad)
        tabBarItem.selectedImage = UIImage(asset: .tabKeypadActive)
    }

    fileprivate func setupLayout() {
        navigationItem.titleView = UIImageView(image: UIImage(asset: .logo))
        updateReachabilityBar()
    }

    fileprivate func setupSounds() {
        DispatchQueue.global(qos: .userInteractive).async {
            var sounds = [String: AVAudioPlayer]()
            for soundNumber in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "#", "*"] {
                let soundFileName = "dtmf-\(soundNumber)"
                let soundURL = Bundle.main.url(forResource: soundFileName, withExtension: "aif")
                assert(soundURL != nil, "No sound available")
                do {
                    let player = try AVAudioPlayer(contentsOf: soundURL!)
                    player.prepareToPlay()
                    sounds[soundNumber] = player
                } catch let error {
                    VialerLogError("Couldn't load sound: \(error)")
                }
            }
            self.sounds = sounds
        }
    }

    fileprivate func setupButtons() {
        // Enable callbutton if:
        // - status isn't offline or 
        // - there is a number in memory or 
        // - there is a number to be called
        if reachability.status == .notReachable || (lastCalledNumber == nil && numberText == nil) {
            callButton.isEnabled = false
        } else {
            callButton.isEnabled = true
        }
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
            self.callButton.alpha = self.callButton.isEnabled ? 1.0 : 0.5
        }, completion: nil)

        deleteButton.isEnabled = numberText != nil
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: { 
            self.deleteButton.alpha = self.deleteButton.isEnabled ? 1.0 : 0.0
        }, completion: nil)
    }

    fileprivate func numberPadPressed(character: String) {
        if character == "+" {
            if numberText == "0" || numberText == nil {
                numberText = "+"
            }
        } else if numberText != nil {
            numberText = "\(numberText!)\(character)"
        } else {
            numberText = character
        }
    }

    fileprivate func playSound(character: String) {
        if let player = sounds[character] {
            player.currentTime = 0
            player.play()
        }
    }

    fileprivate func updateReachabilityBar() {
        DispatchQueue.main.async {
            self.setupButtons()
            if (!self.user.sipEnabled) {
                self.reachabilityBarHeigthConstraint.constant = Config.ReachabilityBar.height
            } else if (!self.reachability.hasHighSpeed) {
                self.reachabilityBarHeigthConstraint.constant = Config.ReachabilityBar.height
            } else if (!self.user.sipUseEncryption){
                self.reachabilityBarHeigthConstraint.constant = Config.ReachabilityBar.height
            } else {
                self.reachabilityBarHeigthConstraint.constant = 0
            }
            UIView.animate(withDuration: Config.ReachabilityBar.animationDuration) {
                self.reachabilityBar.setNeedsUpdateConstraints()
                self.view.layoutIfNeeded()
            }
        }
    }
}

