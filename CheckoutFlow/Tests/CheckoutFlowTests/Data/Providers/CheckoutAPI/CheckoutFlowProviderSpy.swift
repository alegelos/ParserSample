import Foundation
import iOSCleanNetworkTesting

@testable import CheckoutFlow

final class CheckoutFlowProviderSpy: PaymentFlowProviderProtocol, @unchecked Sendable, ProviderSpyProtocol {
    

    enum MethodKey: Hashable, CaseIterable {
        case tokenizeCard
        case createPayment
    }

    var invocationsCount: [MethodKey: Int] = [:]
    var failingMethos: [(method: MethodKey, error: any Error)] = []

    private let wrappedProvider: any PaymentFlowProviderProtocol

    init(wrapping wrappedProvider: any PaymentFlowProviderProtocol) {
        self.wrappedProvider = wrappedProvider
    }

    func tokenizeCard(_ cardDetails: CardDetails) async throws -> PaymentToken {
        increment(.tokenizeCard)
        try validateFailingMethods(method: .tokenizeCard)
        return try await wrappedProvider.tokenizeCard(cardDetails)
    }

    func createPayment(_ cardPayment: CardPayment) async throws -> ThreeDSPaymentSession {
        increment(.createPayment)
        try validateFailingMethods(method: .createPayment)
        return try await wrappedProvider.createPayment(cardPayment)
    }
}
