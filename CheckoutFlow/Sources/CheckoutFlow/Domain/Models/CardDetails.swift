import Foundation

public struct CardDetails: Equatable, Sendable {
    public let cardNumber: String
    public let expirationMonth: String
    public let expirationYear: String
    public let securityCode: String

    public init(
        cardNumber: String,
        expirationMonth: String,
        expirationYear: String,
        securityCode: String
    ) {
        self.cardNumber = cardNumber
        self.expirationMonth = expirationMonth
        self.expirationYear = expirationYear
        self.securityCode = securityCode
    }
}
