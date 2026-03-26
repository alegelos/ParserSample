import Foundation
import Observation

@MainActor
@Observable
final class CheckoutPaymentResultViewModel {
    
    let status: PaymentOutcome
    let titleText: String
    let messageText: String
    let primaryButtonTitle: String
    let secondaryButtonTitle: String?
    
    var viewState: CheckoutPaymentResultViewState {
        CheckoutPaymentResultViewState(
            status: status,
            titleText: titleText,
            messageText: messageText,
            primaryButtonTitle: primaryButtonTitle,
            secondaryButtonTitle: secondaryButtonTitle
        )
    }
    
    @ObservationIgnored
    private let onPrimaryAction: (() -> Void)?
    
    @ObservationIgnored
    private let onSecondaryAction: (() -> Void)?
    
    init(
        status: PaymentOutcome,
        titleText: String,
        messageText: String,
        primaryButtonTitle: String,
        secondaryButtonTitle: String? = nil,
        onPrimaryAction: (() -> Void)? = nil,
        onSecondaryAction: (() -> Void)? = nil
    ) {
        self.status = status
        self.titleText = titleText
        self.messageText = messageText
        self.primaryButtonTitle = primaryButtonTitle
        self.secondaryButtonTitle = secondaryButtonTitle
        self.onPrimaryAction = onPrimaryAction
        self.onSecondaryAction = onSecondaryAction
    }
    
    static func success(
        titleText: String = "Payment completed",
        messageText: String = "Your payment was processed successfully.",
        primaryButtonTitle: String = "Done",
        onPrimaryAction: (() -> Void)? = nil
    ) -> CheckoutPaymentResultViewModel {
        CheckoutPaymentResultViewModel(
            status: .success,
            titleText: titleText,
            messageText: messageText,
            primaryButtonTitle: primaryButtonTitle,
            onPrimaryAction: onPrimaryAction
        )
    }
    
    static func failure(
        titleText: String = "Payment failed",
        messageText: String = "We could not complete your payment. Please try again.",
        primaryButtonTitle: String = "Try Again",
        secondaryButtonTitle: String? = "Close",
        onPrimaryAction: (() -> Void)? = nil,
        onSecondaryAction: (() -> Void)? = nil
    ) -> CheckoutPaymentResultViewModel {
        CheckoutPaymentResultViewModel(
            status: .failure,
            titleText: titleText,
            messageText: messageText,
            primaryButtonTitle: primaryButtonTitle,
            secondaryButtonTitle: secondaryButtonTitle,
            onPrimaryAction: onPrimaryAction,
            onSecondaryAction: onSecondaryAction
        )
    }
    
    static func cancelled(
        titleText: String = "Payment cancelled",
        messageText: String = "The checkout flow was cancelled.",
        primaryButtonTitle: String = "Close",
        onPrimaryAction: (() -> Void)? = nil
    ) -> CheckoutPaymentResultViewModel {
        CheckoutPaymentResultViewModel(
            status: .cancelled,
            titleText: titleText,
            messageText: messageText,
            primaryButtonTitle: primaryButtonTitle,
            onPrimaryAction: onPrimaryAction
        )
    }
    
    func didTapPrimaryButton() {
        onPrimaryAction?()
    }
    
    func didTapSecondaryButton() {
        onSecondaryAction?()
    }
}
