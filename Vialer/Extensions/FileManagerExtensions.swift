//
//  FileManagerExtensions.swift
//  Copyright © 2016 VoIPGRID BV. All rights reserved.
//

import Foundation

extension FileManager {
    static var documentsDir: URL {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.endIndex-1]
    }
}
