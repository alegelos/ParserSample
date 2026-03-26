import Foundation
import Observation

public enum CheckoutFlowCompletionResult: Equatable, Sendable {
    case completedSuccessfully
    case completedWithFailure(message: String?)
    case cancelled
}

@MainActor
@Observable
final class CheckoutFlowViewModel {
    
    var currentStep: CheckoutFlowStep = .cardForm
    var threeDSChallengeViewModel: CheckoutThreeDSChallengeViewModel?
    var paymentResultViewModel: CheckoutPaymentResultViewModel?
    
    var viewState: CheckoutFlowViewState {
        CheckoutFlowViewState(currentStep: currentStep)
    }
    
    var cardFormViewModel: CheckoutCardFormViewModel!
    
    @ObservationIgnored
    private let paymentFlowProvider: any PaymentFlowProviderProtocol
    
    @ObservationIgnored
    private let amountInMinorUnits: Int
    
    @ObservationIgnored
    private let currencyCode: String
    
    @ObservationIgnored
    private let successURL: URL
    
    @ObservationIgnored
    private let failureURL: URL
    
    @ObservationIgnored
    private let onComplete: (CheckoutFlowCompletionResult) -> Void
    
    @ObservationIgnored
    private let mapSubmitErrorMessage: ((Error) -> String)?
    
    @ObservationIgnored
    private let payButtonTitle: String
    
    init(
        payButtonTitle: String = "Pay",
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

// MARK: - Private

extension CheckoutFlowViewModel {
    
    private func makeCardFormViewModel() -> CheckoutCardFormViewModel {
        CheckoutCardFormViewModel(
            payButtonTitle: payButtonTitle,
            paymentFlowProvider: paymentFlowProvider,
            onCardTokenized: { [weak self] paymentToken in
                guard let self else {
                    return
                }
                
                Task {
                    await self.handleCardTokenized(paymentToken)
                }
            },
            mapSubmitErrorMessage: mapSubmitErrorMessage
        )
    }
    
    private func handleCardTokenized(_ paymentToken: PaymentToken) async {
        cardFormViewModel.isLoading = true
        
        defer {
            cardFormViewModel.isLoading = false
        }
        
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
                ?? "We could not complete your payment. Please try again."
            
            showFailureResult(message: failureMessage)
        }
    }
    
    private func handlePaymentSession(_ threeDSPaymentSession: ThreeDSPaymentSession) {
        switch threeDSPaymentSession.status {
        case .pending:
            guard let redirectURL = threeDSPaymentSession.redirectURL else {
                showFailureResult(message: "The payment requires authentication, but no redirect URL was provided.")
                return
            }
            
            showThreeDSChallenge(with: redirectURL)
            
        case .unknown(let rawStatus):
            showFailureResult(message: "Unsupported payment status: \(rawStatus)")
        }
    }
    
    private func showThreeDSChallenge(with challengeURL: URL) {
        paymentResultViewModel = nil
        
        threeDSChallengeViewModel = CheckoutThreeDSChallengeViewModel(
            requestURL: challengeURL,
            titleText: "3D Secure",
            showsCloseButton: true,
            navigationActionResolver: { [weak self] url in
                guard let self else {
                    return .finishCancelled
                }
                
                return self.resolveThreeDSNavigationAction(for: url)
            },
            onCompletion: { [weak self] completion in
                self?.handleThreeDSCompletion(completion)
            }
        )
        
        currentStep = .threeDSChallenge
    }
    
    private func resolveThreeDSNavigationAction(for url: URL) -> CheckoutThreeDSChallengeNavigationAction {
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
        _ completion: CheckoutThreeDSChallengeCompletion
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
        
        paymentResultViewModel = CheckoutPaymentResultViewModel(
            status: .success,
            titleText: "Payment completed",
            messageText: "Your payment was processed successfully.",
            primaryButtonTitle: "Done",
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
        
        let failureMessage = message ?? "We could not complete your payment. Please try again."
        
        paymentResultViewModel = CheckoutPaymentResultViewModel(
            status: .failure,
            titleText: "Payment failed",
            messageText: failureMessage,
            primaryButtonTitle: "Try Again",
            secondaryButtonTitle: "Close",
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
        
        paymentResultViewModel = CheckoutPaymentResultViewModel(
            status: .cancelled,
            titleText: "Payment cancelled",
            messageText: "The checkout flow was cancelled.",
            primaryButtonTitle: "Close",
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
