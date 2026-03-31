import Foundation

@MainActor
final class PaymentResultViewModel: ObservableObject {
    
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
    
    private let onPrimaryAction: (() -> Void)?
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
    
    func didTapPrimaryButton() {
        onPrimaryAction?()
    }
    
    func didTapSecondaryButton() {
        onSecondaryAction?()
    }
}
