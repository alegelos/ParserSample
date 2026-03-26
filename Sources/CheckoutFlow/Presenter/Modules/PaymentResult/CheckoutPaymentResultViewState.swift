import Foundation

enum PaymentOutcome: Equatable {
    case success
    case failure
    case cancelled
}

struct CheckoutPaymentResultViewState: Equatable {
    
    let status: PaymentOutcome
    let titleText: String
    let messageText: String
    let primaryButtonTitle: String
    let secondaryButtonTitle: String?
}
