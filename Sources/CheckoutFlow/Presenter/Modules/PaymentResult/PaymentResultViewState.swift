import Foundation

struct PaymentResultViewState: Equatable {
    
    let status: PaymentResultViewState.PaymentOutcome
    let titleText: String
    let messageText: String
    let primaryButtonTitle: String
    let secondaryButtonTitle: String?
    let statusImageName: String
    let appearance: PaymentResultViewState.CheckoutPaymentResultAppearance
}

// MARK: - Helping Structures

extension PaymentResultViewState {
    
    enum PaymentOutcome: Equatable {
        case success
        case failure
        case cancelled
    }

    enum CheckoutPaymentResultAppearance: Equatable {
        case success
        case failure
        case cancelled
    }
}
