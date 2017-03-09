//
//  UIViewController.swift
//  Copyright © 2017 VoIPGRID. All rights reserved.
//

import Foundation

protocol SegueHandler {
    associatedtype SegueIdentifier: RawRepresentable
}

extension SegueHandler where Self : UIViewController, SegueIdentifier.RawValue == String {
    func performSegue(segueIdentifier: SegueIdentifier, sender: Any? = nil) {
        performSegue(withIdentifier: segueIdentifier.rawValue, sender: sender)
    }

    func segueIdentifier(segue: UIStoryboardSegue) -> SegueIdentifier {
        guard let identifier = segue.identifier,
            let segueIdentifier = SegueIdentifier(rawValue: identifier)
            else { fatalError("Unknown segue: \(segue))") }
        return segueIdentifier
    }
}
