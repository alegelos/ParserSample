import Foundation
import Observation

@MainActor
@Observable
final class PaymentResultViewModel {
    
    let status: PaymentResultViewState.PaymentOutcome
    let titleText: String
    let messageText: String
    let primaryButtonTitle: String
    let secondaryButtonTitle: String?
    
    var viewState: PaymentResultViewState {
        PaymentResultViewState(
            status: status,
            titleText: titleText,
            messageText: messageText,
            primaryButtonTitle: primaryButtonTitle,
            secondaryButtonTitle: secondaryButtonTitle,
            statusImageName: statusImageName,
            appearance: appearance
        )
    }

    private var statusImageName: String {
        switch status {
        case .success:
            return "checkmark.circle.fill"
        case .failure:
            return "xmark.circle.fill"
        case .cancelled:
            return "minus.circle.fill"
        }
    }

    private var appearance: PaymentResultViewState.CheckoutPaymentResultAppearance {
        switch status {
        case .success:
            return .success
        case .failure:
            return .failure
        case .cancelled:
            return .cancelled
        }
    }
    
    @ObservationIgnored
    private let onPrimaryAction: (() -> Void)?
    
    @ObservationIgnored
    private let onSecondaryAction: (() -> Void)?
    
    init(
        status: PaymentResultViewState.PaymentOutcome,
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
    ) -> PaymentResultViewModel {
        PaymentResultViewModel(
            status: PaymentResultViewState.PaymentOutcome.success,
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
    ) -> PaymentResultViewModel {
        PaymentResultViewModel(
            status: PaymentResultViewState.PaymentOutcome.failure,
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
    ) -> PaymentResultViewModel {
        PaymentResultViewModel(
            status: PaymentResultViewState.PaymentOutcome.cancelled,
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
