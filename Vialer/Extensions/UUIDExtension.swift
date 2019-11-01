import Foundation

enum UUIDError: Error {
    case unknown
}

@objc extension NSUUID {
    
    @objc(uuidFixerWithString:)
    static func uuidFixer(uuidString: String) -> NSUUID? {
        if let uuid = NSUUID(uuidString: uuidString) { return uuid }
        let hyphenForIdx:(Int) -> String = { return  [7, 11, 15, 19].contains($0) ? "-" : "" }
        var newString = ""
        uuidString.enumerated().forEach { newString = newString + "\($0.element)" + hyphenForIdx($0.offset) }
        return NSUUID(uuidString: newString)
    }

}
