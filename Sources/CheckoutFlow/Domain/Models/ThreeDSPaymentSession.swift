import Foundation

public struct ThreeDSPaymentSession: Equatable, Sendable {
    public let status: PaymentStatus
    public let redirectURL: URL?

    public init(
        status: PaymentStatus,
        redirectURL: URL?
    ) {
        self.status = status
        self.redirectURL = redirectURL
    }
    
}
