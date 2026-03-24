import Foundation
import iOSCleanNetwork

public final class CheckoutFlowModule {

    public enum Errors: Error {
        case notInitialized
    }

    nonisolated(unsafe) private static var sharedInstance: CheckoutFlowModule?
    private static let sharedQueue = DispatchQueue(
        label: "com.checkoutflow.module.threadSafeQueue",
        attributes: .concurrent
    )

    public static var shared: CheckoutFlowModule {
        get throws {
            try sharedQueue.sync {
                guard let sharedInstance else {
                    throw Errors.notInitialized
                }
                return sharedInstance
            }
        }
    }

    let paymentFlowProvider: any PaymentFlowProviderProtocol

    private init(paymentFlowProvider: any PaymentFlowProviderProtocol) {
        self.paymentFlowProvider = paymentFlowProvider
    }

    public static func create(
        configuration: CheckoutFlowConfiguration,
        session: any NetworkSessionProtocol = URLSession.shared
    ) {
        sharedQueue.sync(flags: .barrier) {
            let checkoutAPIProvider = CheckoutAPIProvider(
                baseURL: configuration.baseURL,
                publicAPIKey: configuration.publicAPIKey,
                secretAPIKey: configuration.secretAPIKey,
                session: session
            )

            let module = CheckoutFlowModule(
                paymentFlowProvider: checkoutAPIProvider
            )

            sharedInstance = module
        }
    }

    public static func destroy() {
        sharedQueue.sync(flags: .barrier) {
            sharedInstance = nil
        }
    }
}

// MARK: - PaymentFlowProviderProtocol

extension CheckoutFlowModule: PaymentFlowProviderProtocol {

    public func tokenizeCard(_ cardDetails: CardDetails) async throws -> PaymentToken {
        try await paymentFlowProvider.tokenizeCard(cardDetails)
    }

    public func createPayment(_ cardPayment: CardPayment) async throws -> ThreeDSPaymentSession {
        try await paymentFlowProvider.createPayment(cardPayment)
    }
}
