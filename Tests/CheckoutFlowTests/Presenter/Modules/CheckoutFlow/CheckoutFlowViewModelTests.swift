import Foundation
import Testing

@testable import CheckoutFlow

@Suite(.serialized)
struct CheckoutFlowViewModelTests {

    let stubPaymentFlowProvider: StubPaymentFlowProvider
    let checkoutFlowServiceProviderSpy: CheckoutFlowServiceProviderSpy

    init() {
        let stubPaymentFlowProvider = StubPaymentFlowProvider()
        self.stubPaymentFlowProvider = stubPaymentFlowProvider
        self.checkoutFlowServiceProviderSpy = CheckoutFlowServiceProviderSpy(
            cardPaymentFlowProvider: stubPaymentFlowProvider
        )
    }
}

// MARK: - Initialization

extension CheckoutFlowViewModelTests {

    @MainActor
    @Test
    func init_startsAtCardForm_andBuildsCardFormViewModel() {
        // Given
        let checkoutCompletionSpy = CheckoutCompletionSpy()

        // When
        let checkoutFlowViewModel = makeCheckoutFlowViewModel(
            checkoutCompletionSpy: checkoutCompletionSpy
        )

        // Then
        #expect(checkoutFlowViewModel.currentStep == .cardForm)
        #expect(checkoutFlowViewModel.viewState == CheckoutFlowViewState(currentStep: .cardForm))
        #expect(checkoutFlowViewModel.viewState.isShowingCardForm)
        #expect(checkoutFlowViewModel.cardFormViewModel != nil)
        #expect(checkoutFlowViewModel.threeDSChallengeViewModel == nil)
        #expect(checkoutFlowViewModel.paymentResultViewModel == nil)
        #expect(checkoutFlowViewModel.cardFormViewModel.payButtonTitle == "Pay €10.99")
    }
}

// MARK: - Flow

extension CheckoutFlowViewModelTests {

    @MainActor
    @Test
    func submitCardForm_whenPaymentRequiresThreeDS_movesToThreeDSChallenge_andCallsProviderMethods() async {
        // Given
        let checkoutCompletionSpy = CheckoutCompletionSpy()

        stubPaymentFlowProvider.paymentTokenToReturn = PaymentToken(value: "payment_token_123")
        stubPaymentFlowProvider.threeDSPaymentSessionToReturn = ThreeDSPaymentSession(
            status: .pending,
            redirectURL: URL(string: "https://gateway.example.com/3ds")!
        )

        let checkoutFlowViewModel = makeCheckoutFlowViewModel(
            checkoutCompletionSpy: checkoutCompletionSpy
        )

        fillValidCardForm(on: checkoutFlowViewModel.cardFormViewModel)

        // When
        await checkoutFlowViewModel.cardFormViewModel.submit()
        await waitForFlowToAdvance()

        // Then
        checkoutFlowServiceProviderSpy.assertExpectedInvocations(
            .checkoutFlow(.tokenizeCard, .createPayment)
        )

        #expect(checkoutFlowViewModel.currentStep == .threeDSChallenge)
        #expect(checkoutFlowViewModel.threeDSChallengeViewModel?.requestURL == URL(string: "https://gateway.example.com/3ds")!)
        #expect(checkoutFlowViewModel.paymentResultViewModel == nil)

        #expect(
            stubPaymentFlowProvider.receivedCardPayment == CardPayment(
                paymentToken: PaymentToken(value: "payment_token_123"),
                amountInMinorUnits: 1_099,
                currencyCode: "EUR",
                successURL: URL(string: "myapp://checkout/success")!,
                failureURL: URL(string: "myapp://checkout/failure")!
            )
        )
    }

    @MainActor
    @Test
    func threeDSNavigationMatchingBySchemeHostAndPath_showsSuccessResult_andPrimaryActionCompletesSuccessfully() async {
        // Given
        let checkoutCompletionSpy = CheckoutCompletionSpy()

        stubPaymentFlowProvider.paymentTokenToReturn = PaymentToken(value: "payment_token_123")
        stubPaymentFlowProvider.threeDSPaymentSessionToReturn = ThreeDSPaymentSession(
            status: .pending,
            redirectURL: URL(string: "https://gateway.example.com/3ds")!
        )

        let checkoutFlowViewModel = makeCheckoutFlowViewModel(
            checkoutCompletionSpy: checkoutCompletionSpy
        )

        fillValidCardForm(on: checkoutFlowViewModel.cardFormViewModel)

        await checkoutFlowViewModel.cardFormViewModel.submit()
        await waitForFlowToAdvance()

        // When
        let shouldAllowNavigation = checkoutFlowViewModel
            .threeDSChallengeViewModel?
            .decideNavigationPolicy(for: URL(string: "myapp://checkout/success?session_id=123")!)

        // Then
        #expect(shouldAllowNavigation == false)
        #expect(checkoutFlowViewModel.currentStep == .paymentResult)
        #expect(checkoutFlowViewModel.paymentResultViewModel?.viewState.status == .success)

        // When
        checkoutFlowViewModel.paymentResultViewModel?.didTapPrimaryButton()

        // Then
        #expect(checkoutCompletionSpy.recordedCompletions == [.completedSuccessfully])
    }

    @MainActor
    @Test
    func threeDSFailureNavigation_showsFailureResult_andSecondaryActionCompletesWithNilMessage() async {
        // Given
        let checkoutCompletionSpy = CheckoutCompletionSpy()

        stubPaymentFlowProvider.paymentTokenToReturn = PaymentToken(value: "payment_token_123")
        stubPaymentFlowProvider.threeDSPaymentSessionToReturn = ThreeDSPaymentSession(
            status: .pending,
            redirectURL: URL(string: "https://gateway.example.com/3ds")!
        )

        let checkoutFlowViewModel = makeCheckoutFlowViewModel(
            checkoutCompletionSpy: checkoutCompletionSpy
        )

        fillValidCardForm(on: checkoutFlowViewModel.cardFormViewModel)

        await checkoutFlowViewModel.cardFormViewModel.submit()
        await waitForFlowToAdvance()

        // When
        let shouldAllowNavigation = checkoutFlowViewModel
            .threeDSChallengeViewModel?
            .decideNavigationPolicy(for: URL(string: "myapp://checkout/failure")!)

        // Then
        #expect(shouldAllowNavigation == false)
        #expect(checkoutFlowViewModel.currentStep == .paymentResult)
        #expect(checkoutFlowViewModel.paymentResultViewModel?.viewState.status == .failure)
        #expect(
            checkoutFlowViewModel.paymentResultViewModel?.viewState.messageText
                == "We could not complete your payment. Please try again."
        )

        // When
        checkoutFlowViewModel.paymentResultViewModel?.didTapSecondaryButton()

        // Then
        #expect(checkoutCompletionSpy.recordedCompletions == [.completedWithFailure(message: nil)])
    }

    @MainActor
    @Test
    func cancelledThreeDS_showsCancelledResult_andPrimaryActionCompletesCancelled() async {
        // Given
        let checkoutCompletionSpy = CheckoutCompletionSpy()

        stubPaymentFlowProvider.paymentTokenToReturn = PaymentToken(value: "payment_token_123")
        stubPaymentFlowProvider.threeDSPaymentSessionToReturn = ThreeDSPaymentSession(
            status: .pending,
            redirectURL: URL(string: "https://gateway.example.com/3ds")!
        )

        let checkoutFlowViewModel = makeCheckoutFlowViewModel(
            checkoutCompletionSpy: checkoutCompletionSpy
        )

        fillValidCardForm(on: checkoutFlowViewModel.cardFormViewModel)

        await checkoutFlowViewModel.cardFormViewModel.submit()
        await waitForFlowToAdvance()

        // When
        checkoutFlowViewModel.threeDSChallengeViewModel?.didTapCloseButton()

        // Then
        #expect(checkoutFlowViewModel.currentStep == .paymentResult)
        #expect(checkoutFlowViewModel.paymentResultViewModel?.viewState.status == .cancelled)

        // When
        checkoutFlowViewModel.paymentResultViewModel?.didTapPrimaryButton()

        // Then
        #expect(checkoutCompletionSpy.recordedCompletions == [.cancelled])
    }

    @MainActor
    @Test
    func createPaymentFailure_showsMappedFailureResult_andPrimaryActionResetsToCardForm() async {
        // Given
        let checkoutCompletionSpy = CheckoutCompletionSpy()

        stubPaymentFlowProvider.paymentTokenToReturn = PaymentToken(value: "payment_token_123")
        stubPaymentFlowProvider.createPaymentError = TestError.expectedFailure

        let checkoutFlowViewModel = makeCheckoutFlowViewModel(
            mapSubmitErrorMessage: { error in
                guard error is TestError else {
                    return "Unexpected error"
                }
                return "Mapped create payment error"
            },
            checkoutCompletionSpy: checkoutCompletionSpy
        )

        fillValidCardForm(on: checkoutFlowViewModel.cardFormViewModel)

        // When
        await checkoutFlowViewModel.cardFormViewModel.submit()
        await waitForFlowToAdvance()

        // Then
        checkoutFlowServiceProviderSpy.assertExpectedInvocations(
            .checkoutFlow(.tokenizeCard, .createPayment)
        )

        #expect(checkoutFlowViewModel.currentStep == .paymentResult)
        #expect(checkoutFlowViewModel.paymentResultViewModel?.viewState.status == .failure)
        #expect(checkoutFlowViewModel.paymentResultViewModel?.viewState.messageText == "Mapped create payment error")

        // When
        checkoutFlowViewModel.paymentResultViewModel?.didTapPrimaryButton()

        // Then
        #expect(checkoutFlowViewModel.currentStep == .cardForm)
        #expect(checkoutFlowViewModel.threeDSChallengeViewModel == nil)
        #expect(checkoutFlowViewModel.paymentResultViewModel == nil)
        #expect(checkoutCompletionSpy.recordedCompletions.isEmpty)
    }

    @MainActor
    @Test
    func pendingPaymentWithoutRedirect_showsFailureResult() async {
        // Given
        let checkoutCompletionSpy = CheckoutCompletionSpy()

        stubPaymentFlowProvider.paymentTokenToReturn = PaymentToken(value: "payment_token_123")
        stubPaymentFlowProvider.threeDSPaymentSessionToReturn = ThreeDSPaymentSession(
            status: .pending,
            redirectURL: nil
        )

        let checkoutFlowViewModel = makeCheckoutFlowViewModel(
            checkoutCompletionSpy: checkoutCompletionSpy
        )

        fillValidCardForm(on: checkoutFlowViewModel.cardFormViewModel)

        // When
        await checkoutFlowViewModel.cardFormViewModel.submit()
        await waitForFlowToAdvance()

        // Then
        #expect(checkoutFlowViewModel.currentStep == .paymentResult)
        #expect(
            checkoutFlowViewModel.paymentResultViewModel?.viewState.messageText
                == "The payment requires authentication, but no redirect URL was provided."
        )
    }

    @MainActor
    @Test
    func unknownPaymentStatus_showsFailureResult() async {
        // Given
        let checkoutCompletionSpy = CheckoutCompletionSpy()

        stubPaymentFlowProvider.paymentTokenToReturn = PaymentToken(value: "payment_token_123")
        stubPaymentFlowProvider.threeDSPaymentSessionToReturn = ThreeDSPaymentSession(
            status: .unknown("authorized"),
            redirectURL: nil
        )

        let checkoutFlowViewModel = makeCheckoutFlowViewModel(
            checkoutCompletionSpy: checkoutCompletionSpy
        )

        fillValidCardForm(on: checkoutFlowViewModel.cardFormViewModel)

        // When
        await checkoutFlowViewModel.cardFormViewModel.submit()
        await waitForFlowToAdvance()

        // Then
        #expect(checkoutFlowViewModel.currentStep == .paymentResult)
        #expect(
            checkoutFlowViewModel.paymentResultViewModel?.viewState.messageText
                == "Unsupported payment status: authorized"
        )
    }
}

// MARK: - Helpers

extension CheckoutFlowViewModelTests {

    enum TestError: Error {
        case expectedFailure
    }

    @MainActor
    func makeCheckoutFlowViewModel(
        mapSubmitErrorMessage: ((Error) -> String)? = nil,
        checkoutCompletionSpy: CheckoutCompletionSpy
    ) -> CheckoutFlowViewModel {
        CheckoutFlowViewModel(
            payButtonTitle: "Pay €10.99",
            paymentFlowProvider: checkoutFlowServiceProviderSpy,
            amountInMinorUnits: 1_099,
            currencyCode: "EUR",
            successURL: URL(string: "myapp://checkout/success")!,
            failureURL: URL(string: "myapp://checkout/failure")!,
            mapSubmitErrorMessage: mapSubmitErrorMessage,
            onComplete: { completion in
                checkoutCompletionSpy.record(completion)
            }
        )
    }

    @MainActor
    func fillValidCardForm(on cardFormViewModel: CardFormViewModel) {
        cardFormViewModel.cardNumberText = "4111 1111 1111 1111"
        cardFormViewModel.expiryDateText = "12/29"
        cardFormViewModel.cvvText = "123"
    }

    @MainActor
    func waitForFlowToAdvance() async {
        await Task.yield()
        try? await Task.sleep(nanoseconds: 20_000_000)
        await Task.yield()
    }

    final class CheckoutCompletionSpy {
        private(set) var recordedCompletions: [CheckoutFlowCompletionResult] = []

        func record(_ completion: CheckoutFlowCompletionResult) {
            recordedCompletions.append(completion)
        }
    }

    final class StubPaymentFlowProvider: PaymentFlowProviderProtocol, @unchecked Sendable {

        var paymentTokenToReturn = PaymentToken(value: "default_token")
        var threeDSPaymentSessionToReturn = ThreeDSPaymentSession(
            status: .pending,
            redirectURL: URL(string: "https://example.com/3ds")!
        )

        var tokenizeCardError: Error?
        var createPaymentError: Error?

        private(set) var tokenizeCardInvocationCount = 0
        private(set) var createPaymentInvocationCount = 0
        private(set) var receivedCardDetails: CardDetails?
        private(set) var receivedCardPayment: CardPayment?

        func tokenizeCard(_ cardDetails: CardDetails) async throws -> PaymentToken {
            tokenizeCardInvocationCount += 1
            receivedCardDetails = cardDetails

            if let tokenizeCardError {
                throw tokenizeCardError
            }

            return paymentTokenToReturn
        }

        func createPayment(_ cardPayment: CardPayment) async throws -> ThreeDSPaymentSession {
            createPaymentInvocationCount += 1
            receivedCardPayment = cardPayment

            if let createPaymentError {
                throw createPaymentError
            }

            return threeDSPaymentSessionToReturn
        }
    }
}
