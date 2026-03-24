import Foundation

public enum PaymentStatus: Equatable, Sendable {
    case pending
    case unknown(String)
}
