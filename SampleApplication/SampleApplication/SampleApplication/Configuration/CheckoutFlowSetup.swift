import Foundation
import CheckoutFlow

enum CheckoutFlowSetup {
    
    static var checkoutFlowConfiguration: CheckoutFlowConfiguration {
        get throws {
            let bundle = Bundle.main
            let publicAPIKey = try bundle.requiredInfoDictionaryValue(forKey: "CheckoutPublicKey")
            let secretAPIKey = try bundle.requiredInfoDictionaryValue(forKey: "CheckoutSecretKey")
            let checkoutBaseURLString = try bundle.requiredInfoDictionaryValue(forKey: "CheckoutBaseURL")

            guard let checkoutBaseURL = URL(string: checkoutBaseURLString) else {
                throw SetupError.invalidURL(checkoutBaseURLString)
            }
            
            return CheckoutFlowConfiguration(
                baseURL: checkoutBaseURL,
                publicAPIKey: publicAPIKey,
                secretAPIKey: secretAPIKey
            )
        }
    }

    static var samplePayment: CheckoutFlowPaymentConfiguration {
        CheckoutFlowPaymentConfiguration(
            amountInMinorUnits: 6_540,
            currencyCode: "GBP",
            successURL: URL(string: "https://example.com/payments/success")!,
            failureURL: URL(string: "https://example.com/payments/fail")!,
            payButtonTitle: "Pay £65.40"
        )
    }
    
    enum SetupError: LocalizedError, Equatable {
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
    
}
