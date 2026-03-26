import Foundation
import CheckoutFlow

enum SampleApplicationConfigurationError: LocalizedError, Equatable {
    case missingValue(key: String)
    case invalidURL(String)

    var errorDescription: String? {
        switch self {
        case .missingValue(let key):
            return "Missing configuration value for \(key). Add it to Secrets.local.xcconfig."
        case .invalidURL(let value):
            return "Invalid Checkout base URL: \(value)"
        }
    }
}

struct CheckoutSandboxConfiguration: Equatable {

    let moduleConfiguration: CheckoutFlowConfiguration
    let amountInMinorUnits: Int
    let currencyCode: String
    let successURL: URL
    let failureURL: URL
    let payButtonTitle: String

    static func load(from bundle: Bundle = .main) throws -> CheckoutSandboxConfiguration {
        let publicAPIKey = try bundle.requiredInfoDictionaryValue(forKey: "CheckoutPublicKey")
        let secretAPIKey = try bundle.requiredInfoDictionaryValue(forKey: "CheckoutSecretKey")
        let checkoutBaseURLString = try bundle.requiredInfoDictionaryValue(forKey: "CheckoutBaseURL")

        guard let checkoutBaseURL = URL(string: checkoutBaseURLString) else {
            throw SampleApplicationConfigurationError.invalidURL(checkoutBaseURLString)
        }

        return CheckoutSandboxConfiguration(
            moduleConfiguration: CheckoutFlowConfiguration(
                baseURL: checkoutBaseURL,
                publicAPIKey: publicAPIKey,
                secretAPIKey: secretAPIKey
            ),
            amountInMinorUnits: 6_540,
            currencyCode: "GBP",
            successURL: URL(string: "https://example.com/payments/success")!,
            failureURL: URL(string: "https://example.com/payments/fail")!,
            payButtonTitle: "Pay £65.40"
        )
    }
}

private extension Bundle {

    func requiredInfoDictionaryValue(forKey key: String) throws -> String {
        let rawValue = (infoDictionary?[key] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard rawValue.isEmpty == false, rawValue.contains("replace_me") == false else {
            throw SampleApplicationConfigurationError.missingValue(key: key)
        }

        return rawValue
    }
}
