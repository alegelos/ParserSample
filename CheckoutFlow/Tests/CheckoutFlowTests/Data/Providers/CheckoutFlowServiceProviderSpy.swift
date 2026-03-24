import Foundation
import Testing

@testable import CheckoutFlow

final class CheckoutFlowServiceProviderSpy: PaymentFlowProviderProtocol, @unchecked Sendable {

    private let checkoutFlowProviderSpy: CheckoutFlowProviderSpy

    init(cardPaymentFlowProvider: any PaymentFlowProviderProtocol) {
        self.checkoutFlowProviderSpy = CheckoutFlowProviderSpy(wrapping: cardPaymentFlowProvider)
    }

    func tokenizeCard(_ cardDetails: CardDetails) async throws -> PaymentToken {
        try await checkoutFlowProviderSpy.tokenizeCard(cardDetails)
    }

    func createPayment(_ cardPayment: CardPayment) async throws -> ThreeDSPaymentSession {
        try await checkoutFlowProviderSpy.createPayment(cardPayment)
    }
}

// MARK: - Spy methods calls tracker

extension CheckoutFlowServiceProviderSpy {

    enum MethodsKeys {
        case checkoutFlow([(CheckoutFlowProviderSpy.MethodKey, Int)])

        static func checkoutFlow(_ keys: CheckoutFlowProviderSpy.MethodKey...) -> Self {
            .checkoutFlow(keys.map { ($0, 1) })
        }

        static func checkoutFlow(_ items: (CheckoutFlowProviderSpy.MethodKey, times: Int)...) -> Self {
            .checkoutFlow(items.map { ($0.0, $0.times) })
        }
    }

    func assertExpectedInvocations(
        _ expectedCalls: MethodsKeys...,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        var checkoutFlowExpectedInvocations: [(CheckoutFlowProviderSpy.MethodKey, Int)] = []

        for expectedCall in expectedCalls {
            switch expectedCall {
            case .checkoutFlow(let expected):
                checkoutFlowExpectedInvocations = expected
            }
        }

        checkoutFlowProviderSpy.assertExpectedInvocations(
            checkoutFlowExpectedInvocations,
            sourceLocation: sourceLocation
        )
    }

    func resetAllCounters() {
        checkoutFlowProviderSpy.resetInvocationsCount()
    }
}

// MARK: - Spy failing methods

extension CheckoutFlowServiceProviderSpy {

    enum FailingMethods {
        case checkoutFlow([(CheckoutFlowProviderSpy.MethodKey, Error)])

        static func checkoutFlow(
            _ keys: CheckoutFlowProviderSpy.MethodKey...,
            error: Error = Errors.timeout
        ) -> Self {
            .checkoutFlow(keys.map { ($0, error) })
        }

        static func checkoutFlow(
            _ failingMethods: (CheckoutFlowProviderSpy.MethodKey, Error)...
        ) -> Self {
            .checkoutFlow(failingMethods)
        }
    }

    func failingMethods(_ failingMethods: FailingMethods...) {
        for failingMethod in failingMethods {
            switch failingMethod {
            case .checkoutFlow(let failingMethods):
                checkoutFlowProviderSpy.failingMethods(failingMethods)
            }
        }
    }
}

// MARK: - Helping Structures

extension CheckoutFlowServiceProviderSpy {

    enum Errors: Error {
        case timeout
    }
}
