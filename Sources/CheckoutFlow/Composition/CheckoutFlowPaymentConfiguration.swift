import Foundation

public struct CheckoutFlowPaymentConfiguration: Sendable, Equatable {
    
    public let amountInMinorUnits: Int
    public let currencyCode: String
    public let successURL: URL
    public let failureURL: URL
    public let payButtonTitle: String

    public init(
        amountInMinorUnits: Int,
        currencyCode: String,
        successURL: URL,
        failureURL: URL,
        payButtonTitle: String? = nil
    ) {
        self.amountInMinorUnits = amountInMinorUnits
        self.currencyCode = currencyCode
        self.successURL = successURL
        self.failureURL = failureURL
        self.payButtonTitle = payButtonTitle ?? CheckoutFlowLocalized.string("checkout.card_form.pay_button_title")
    }
}
