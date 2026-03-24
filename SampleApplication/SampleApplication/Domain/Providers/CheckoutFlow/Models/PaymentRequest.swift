import Foundation

struct PaymentRequest: Equatable {
    
    let cardToken: String
    let amount: Int
    let currency: String
    let isThreeDSecureEnabled: Bool
    let successURL: URL
    let failureURL: URL
    
    init(
        cardToken: String,
        amount: Int,
        currency: String = "GBP",
        isThreeDSecureEnabled: Bool = true,
        successURL: URL,
        failureURL: URL
    ) {
        self.cardToken = cardToken
        self.amount = amount
        self.currency = currency
        self.isThreeDSecureEnabled = isThreeDSecureEnabled
        self.successURL = successURL
        self.failureURL = failureURL
    }
    
}
