import Foundation

public struct CardPayment: Equatable, Sendable {
    public let paymentToken: PaymentToken
    public let amountInMinorUnits: Int
    public let currencyCode: String
    public let successURL: URL
    public let failureURL: URL

    public init(
        paymentToken: PaymentToken,
        amountInMinorUnits: Int,
        currencyCode: String,
        successURL: URL,
        failureURL: URL
    ) {
        self.paymentToken = paymentToken
        self.amountInMinorUnits = amountInMinorUnits
        self.currencyCode = currencyCode
        self.successURL = successURL
        self.failureURL = failureURL
    }
}
