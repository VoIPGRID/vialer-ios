import Foundation

enum UUIDError: Error {
    case unknown
}

extension UUID {
    
    // Initialize a proper UUID, even if the provided string misses hyphens. // TODO: use this, instead of static fixer function?
//    public init(uuidStringFix string: String) throws {
//        if let uuid = UUID(uuidString: string)! {
//            r
//        }
//        
//        
//        let hyphenForIdx:(Int) -> String = { return  [7, 11, 15, 19].contains($0) ? "-" : "" }
//        var newString = ""
//        uuidString.enumerated().forEach { newString = newString + "\($0.element)" + hyphenForIdx($0.offset) }
//        self.init(uuidString: newString)
//    }
    
    // Return a proper UUID, even if the provided string misses hyphens.
    static func uuidFixer(uuidString: String) -> UUID? {
        if let uuid = UUID(uuidString: uuidString) { return uuid }
        let hyphenForIdx:(Int) -> String = { return  [7, 11, 15, 19].contains($0) ? "-" : "" }
        var newString = ""
        uuidString.enumerated().forEach { newString = newString + "\($0.element)" + hyphenForIdx($0.offset) }
        return UUID(uuidString: newString)
    }

}
