//
//  ButtonMock.swift
//  VialerTests
//
//  Created by Redmer Loen on 8/30/18.
//  Copyright © 2018 VoIPGRID. All rights reserved.
//

import Foundation
@testable import Vialer

class ButtonMock: UIButton {
    var buttonHidden: Bool = true

    override var isHidden: Bool {
        get {
            return buttonHidden
        }
        set { }
    }
}
