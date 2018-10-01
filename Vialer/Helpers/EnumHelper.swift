//
//  EnumHelper.swift
//  Copyright © 2018 VoIPGRID. All rights reserved.
//

import Foundation

protocol EnumHelper {
    static var count: Int { get }
    var descriprtion: String { get }
}

extension EnumHelper where Self: RawRepresentable, Self.RawValue == Int {
    internal static var count: Int {
        var count = 0
        while let _ = Self(rawValue: count) {
            count += 1
        }
        return count
    }
}
