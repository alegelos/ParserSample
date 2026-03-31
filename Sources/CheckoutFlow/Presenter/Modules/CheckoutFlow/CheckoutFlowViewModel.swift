import Foundation

public enum CheckoutFlowCompletionResult: Equatable, Sendable {
    case completedSuccessfully
    case completedWithFailure(message: String?)
    case cancelled
}

@MainActor
final class CheckoutFlowViewModel: ObservableObject {

    @Published var currentStep: CheckoutFlowStep = .cardForm
    @Published var threeDSChallengeViewModel: ThreeDSChallengeViewModel?
    @Published var paymentResultViewModel: PaymentResultViewModel?
    @Published var cardFormViewModel: CardFormViewModel!

    private let paymentFlowProvider: any PaymentFlowProviderProtocol
    private let amountInMinorUnits: Int
    private let currencyCode: String
    private let successURL: URL
    private let failureURL: URL
    private let onComplete: (CheckoutFlowCompletionResult) -> Void
    private let mapSubmitErrorMessage: ((Error) -> String)?
    private let payButtonTitle: String

    init(
        payButtonTitle: String = CheckoutFlowLocalized.string("checkout.card_form.pay_button_title"),
        paymentFlowProvider: any PaymentFlowProviderProtocol,
        amountInMinorUnits: Int,
        currencyCode: String,
        successURL: URL,
        failureURL: URL,
        mapSubmitErrorMessage: ((Error) -> String)? = nil,
        onComplete: @escaping (CheckoutFlowCompletionResult) -> Void
    ) {
        self.payButtonTitle = payButtonTitle
        self.paymentFlowProvider = paymentFlowProvider
        self.amountInMinorUnits = amountInMinorUnits
        self.currencyCode = currencyCode
        self.successURL = successURL
        self.failureURL = failureURL
        self.mapSubmitErrorMessage = mapSubmitErrorMessage
        self.onComplete = onComplete
        self.currentStep = .cardForm
        self.cardFormViewModel = nil
        self.cardFormViewModel = makeCardFormViewModel()
    }
}

// MARK: - Helping Structures

extension CheckoutFlowViewModel {
    
    enum CheckoutFlowStep: Equatable {
        case cardForm
        case threeDSChallenge
        case paymentResult
    }
    
}

// MARK: - Private

extension CheckoutFlowViewModel {

    private func makeCardFormViewModel() -> CardFormViewModel {
        CardFormViewModel(
            payButtonTitle: payButtonTitle,
            paymentFlowProvider: paymentFlowProvider,
            onCardTokenized: { [weak self] paymentToken in
                guard let self else {
                    return
                }

                await self.handleCardTokenized(paymentToken)
            },
            mapSubmitErrorMessage: mapSubmitErrorMessage
        )
    }

    private func handleCardTokenized(_ paymentToken: PaymentToken) async {
        do {
            let cardPayment = CardPayment(
                paymentToken: paymentToken,
                amountInMinorUnits: amountInMinorUnits,
                currencyCode: currencyCode,
                successURL: successURL,
                failureURL: failureURL
            )

            let threeDSPaymentSession = try await paymentFlowProvider.createPayment(cardPayment)
            handlePaymentSession(threeDSPaymentSession)
        } catch {
            let failureMessage = mapSubmitErrorMessage?(error)
                ?? CheckoutFlowLocalized.string("checkout.payment_result.failure.message")

            showFailureResult(message: failureMessage)
        }
    }

    private func handlePaymentSession(_ threeDSPaymentSession: ThreeDSPaymentSession) {
        switch threeDSPaymentSession.status {
        case .pending:
            guard let redirectURL = threeDSPaymentSession.redirectURL else {
                showFailureResult(message: CheckoutFlowLocalized.string("checkout.three_ds.error.missing_redirect_url"))
                return
            }

            showThreeDSChallenge(with: redirectURL)

        case .unknown(let rawStatus):
            showFailureResult(message: CheckoutFlowLocalized.string("checkout.three_ds.error.unsupported_status", rawStatus))
        }
    }

    private func showThreeDSChallenge(with challengeURL: URL) {
        paymentResultViewModel = nil

        threeDSChallengeViewModel = ThreeDSChallengeViewModel(
            requestURL: challengeURL,
            titleText: CheckoutFlowLocalized.string("checkout.three_ds.title"),
            showsCloseButton: true,
            navigationActionResolver: { [weak self] url in
                guard let strongSelf = self else {
                    return .finishCancelled
                }

                return strongSelf.resolveThreeDSNavigationAction(for: url)
            },
            onCompletion: { [weak self] completion in
                self?.handleThreeDSCompletion(completion)
            }
        )

        currentStep = .threeDSChallenge
    }

    private func resolveThreeDSNavigationAction(for url: URL) -> ThreeDSChallengeViewModel.ThreeDSChallengeNavigationAction {
        if matchesCallbackURL(url, expectedURL: successURL) {
            return .finishSuccess
        }

        if matchesCallbackURL(url, expectedURL: failureURL) {
            return .finishFailure(message: nil)
        }

        return .allow
    }

    private func matchesCallbackURL(_ navigatedURL: URL, expectedURL: URL) -> Bool {
        if navigatedURL.absoluteString == expectedURL.absoluteString {
            return true
        }

        let navigatedComponents = URLComponents(url: navigatedURL, resolvingAgainstBaseURL: false)
        let expectedComponents = URLComponents(url: expectedURL, resolvingAgainstBaseURL: false)

        return navigatedComponents?.scheme == expectedComponents?.scheme
            && navigatedComponents?.host == expectedComponents?.host
            && navigatedComponents?.path == expectedComponents?.path
    }

    private func handleThreeDSCompletion(
        _ completion: ThreeDSChallengeViewModel.ThreeDSChallengeCompletion
    ) {
        switch completion {
        case .success:
            showSuccessResult()

        case .failure(let message):
            showFailureResult(message: message)

        case .cancelled:
            showCancelledResult()
        }
    }

    private func showSuccessResult() {
        threeDSChallengeViewModel = nil

        paymentResultViewModel = PaymentResultViewModel(
            status: PaymentResultViewState.PaymentOutcome.success,
            titleText: CheckoutFlowLocalized.string("checkout.payment_result.success.title"),
            messageText: CheckoutFlowLocalized.string("checkout.payment_result.success.message"),
            primaryButtonTitle: CheckoutFlowLocalized.string("checkout.payment_result.success.primary_button"),
            secondaryButtonTitle: nil,
            onPrimaryAction: { [weak self] in
                self?.onComplete(.completedSuccessfully)
            },
            onSecondaryAction: nil
        )

        currentStep = .paymentResult
    }

    private func showFailureResult(message: String?) {
        threeDSChallengeViewModel = nil

        let failureMessage = message ?? CheckoutFlowLocalized.string("checkout.payment_result.failure.message")

        paymentResultViewModel = PaymentResultViewModel(
            status: PaymentResultViewState.PaymentOutcome.failure,
            titleText: CheckoutFlowLocalized.string("checkout.payment_result.failure.title"),
            messageText: failureMessage,
            primaryButtonTitle: CheckoutFlowLocalized.string("checkout.payment_result.failure.primary_button"),
            secondaryButtonTitle: CheckoutFlowLocalized.string("checkout.payment_result.failure.secondary_button"),
            onPrimaryAction: { [weak self] in
                self?.resetToCardForm()
            },
            onSecondaryAction: { [weak self] in
                self?.onComplete(.completedWithFailure(message: message))
            }
        )

        currentStep = .paymentResult
    }

    private func showCancelledResult() {
        threeDSChallengeViewModel = nil

        paymentResultViewModel = PaymentResultViewModel(
            status: PaymentResultViewState.PaymentOutcome.cancelled,
            titleText: CheckoutFlowLocalized.string("checkout.payment_result.cancelled.title"),
            messageText: CheckoutFlowLocalized.string("checkout.payment_result.cancelled.message"),
            primaryButtonTitle: CheckoutFlowLocalized.string("checkout.payment_result.cancelled.primary_button"),
            secondaryButtonTitle: nil,
            onPrimaryAction: { [weak self] in
                self?.onComplete(.cancelled)
            },
            onSecondaryAction: nil
        )

        currentStep = .paymentResult
    }

    private func resetToCardForm() {
        threeDSChallengeViewModel = nil
        paymentResultViewModel = nil
        currentStep = .cardForm
    }
}
