//
//  String+numeric.swift
//  Vialer
//
//  Created by Chris Kontos on 13/12/2018.
//  Copyright © 2018 VoIPGRID. All rights reserved.
//

import Foundation

extension String{
    
    func isNumeric() -> Bool{
        return CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn:self))
    }
}
