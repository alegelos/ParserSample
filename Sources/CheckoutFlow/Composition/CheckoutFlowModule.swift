import Foundation
import iOSCleanNetwork

public enum CheckoutFlowError: LocalizedError, Equatable {
    case moduleNotInitialized

    public var errorDescription: String? {
        switch self {
        case .moduleNotInitialized:
            return "CheckoutFlowModule.create(...) must be called before presenting CheckoutFlowView."
        }
    }
}

public final class CheckoutFlowModule {

    nonisolated(unsafe) private static var sharedInstance: CheckoutFlowModule?
    private static let sharedQueue = DispatchQueue(
        label: "com.checkoutflow.module.threadSafeQueue",
        attributes: .concurrent
    )

    static var shared: CheckoutFlowModule {
        get throws {
            try sharedQueue.sync {
                guard let sharedInstance else {
                    throw CheckoutFlowError.moduleNotInitialized
                }

                return sharedInstance
            }
        }
    }

    private let paymentFlowProvider: any PaymentFlowProviderProtocol

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

            sharedInstance = CheckoutFlowModule(paymentFlowProvider: checkoutAPIProvider)
        }
    }

    public static func destroy() {
        sharedQueue.sync(flags: .barrier) {
            sharedInstance = nil
        }
    }
}

// MARK: - Factory

extension CheckoutFlowModule {

    @MainActor
    func makeCheckoutFlowViewModel(
        paymentConfiguration: CheckoutFlowPaymentConfiguration,
        mapSubmitErrorMessage: ((Error) -> String)? = nil,
        onComplete: @escaping (CheckoutFlowCompletionResult) -> Void
    ) -> CheckoutFlowViewModel {
        CheckoutFlowViewModel(
            payButtonTitle: paymentConfiguration.payButtonTitle,
            paymentFlowProvider: paymentFlowProvider,
            amountInMinorUnits: paymentConfiguration.amountInMinorUnits,
            currencyCode: paymentConfiguration.currencyCode,
            successURL: paymentConfiguration.successURL,
            failureURL: paymentConfiguration.failureURL,
            mapSubmitErrorMessage: mapSubmitErrorMessage,
            onComplete: onComplete
        )
    }
}
