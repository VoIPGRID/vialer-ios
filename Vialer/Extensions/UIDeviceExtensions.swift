//
//  UIDevice+NTNUExtensions.swift
//  Vialer
//
//  Created by Redmer Loen on 10/13/17.
//  Copyright © 2017 VoIPGRID. All rights reserved.
//

import UIKit

extension UIDevice {
    @objc var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}
