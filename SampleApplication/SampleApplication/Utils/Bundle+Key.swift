import Foundation

// MARK: - Private

extension Bundle {

    func requiredInfoDictionaryValue(forKey key: String) throws -> String {
        let rawValue = (infoDictionary?[key] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard rawValue.isEmpty == false, rawValue.contains("replace_me") == false else {
            throw CheckoutFlowSetup.SetupError.missingValue(key: key)
        }

        return rawValue
    }
    
}
