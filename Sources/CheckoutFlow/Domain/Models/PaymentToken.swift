import Foundation

public struct PaymentToken: Equatable, Sendable {
    public let value: String

    public init(value: String) {
        self.value = value
    }
}
