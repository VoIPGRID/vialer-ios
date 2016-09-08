//
//  UIViewControllerExtensions.swift
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

extension UIViewController {
    /// Returns the controllerName without the bundle name prepended.
    var controllerName: String {
        return NSStringFromClass(self.classForCoder).replacingOccurrences(of: "\(Bundle.main.infoDictionary!["CFBundleName"]! as! String).", with: "")
    }
}
