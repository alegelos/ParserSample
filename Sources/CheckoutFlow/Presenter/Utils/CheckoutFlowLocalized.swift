import Foundation

enum CheckoutFlowLocalized {
    
    static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: nil, bundle: .module, value: key, comment: "")
    }

    static func string(_ key: String, _ arguments: CVarArg...) -> String {
        String(
            format: NSLocalizedString(key, tableName: nil, bundle: .module, value: key, comment: ""),
            locale: .current,
            arguments: arguments
        )
    }
    
}
