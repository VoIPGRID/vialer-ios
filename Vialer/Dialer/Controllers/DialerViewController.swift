//
//  DialerViewController.swift
//  Copyright © 2017 VoIPGRID. All rights reserved.
//

import UIKit

class DialerViewController: UIViewController, SegueHandler {

    enum SegueIdentifier: String {
        case sipCalling = "SIPCallingSegue"
        case twoStepCalling = "TwoStepCallingSegue"
        case reachabilityBar = "ReachabilityBarSegue"
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
    var reachabilityStatus: ReachabilityManagerStatusType = .highSpeed
    var lastCalledNumber: String? {
        didSet {
            setupButtons()
        }
    }
    var user = SystemUser.current()!

    // MARK: - Outlets
    @IBOutlet weak var leftDrawerButton: UIBarButtonItem!
    @IBOutlet weak var numberLabel: PasteableUILabel! {
        didSet {
            numberLabel.delegate = self
        }
    }
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!

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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        VialerGAITracker.trackScreenForController(name: controllerName)
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
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
            numberText = number.substring(to: number.index(before: number.endIndex))
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

        if reachabilityStatus == .highSpeed && user.sipEnabled {
            VialerGAITracker.setupOutgoingSIPCallEvent()
            performSegue(segueIdentifier: .sipCalling)
        } else {
            VialerGAITracker.setupOutgoingConnectABCallEvent()
            performSegue(segueIdentifier: .twoStepCalling)
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
            let sipCallingVC = segue.destination as! SIPCallingViewController
            if (UIApplication.shared.delegate as! AppDelegate).isScreenshotRun {
                sipCallingVC.handleOutgoingCallForScreenshot(phoneNumber: numberText!)
            } else {
                sipCallingVC.handleOutgoingCall(phoneNumber: numberText!, contact: nil)
            }
            numberText = nil
        case .twoStepCalling:
            let twoStepCallingVC = segue.destination as! TwoStepCallingViewController
            twoStepCallingVC.handlePhoneNumber(numberText!)
            numberText = nil
        case .reachabilityBar:
            let reachabilityBarVC = segue.destination as! ReachabilityBarViewController
            reachabilityBarVC.delegate = self
        }
    }
}

// MARK: - PasteableUILabelDelegate
extension DialerViewController : PasteableUILabelDelegate {
    func pasteableUILabel(_ label: UILabel!, didReceivePastedText text: String!) {
        numberText = text
    }
}

// MARK: - ReachabilityBarViewControllerDelegate
extension DialerViewController : ReachabilityBarViewControllerDelegate {
    func reachabilityBar(_ reachabilityBar: ReachabilityBarViewController!, statusChanged status: ReachabilityManagerStatusType) {
        reachabilityStatus = status
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
        if reachabilityStatus == .offline || (lastCalledNumber == nil && numberText == nil) {
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
        let player = sounds[character]!
        player.currentTime = 0
        player.play()
    }
}
