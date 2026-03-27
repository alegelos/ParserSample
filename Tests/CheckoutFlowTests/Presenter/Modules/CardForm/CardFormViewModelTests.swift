import Foundation
import Testing

@testable import CheckoutFlow

@Suite(.serialized)
struct CardFormViewModelTests {

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

// MARK: - View state

extension CardFormViewModelTests {

    @MainActor
    @Test
    func init_buildsExpectedDefaultViewState() {
        // Given
        let cardFormViewModel = CardFormViewModel(
            payButtonTitle: "Pay €10.99",
            paymentFlowProvider: checkoutFlowServiceProviderSpy
        )

        // Then
        #expect(
            cardFormViewModel.viewState == CardFormViewState(
                cardNumberText: "",
                expiryDateText: "",
                cvvText: "",
                detectedSchemeName: nil,
                errorMessage: nil,
                isLoading: false,
                isPayButtonEnabled: false,
                payButtonTitle: "Pay €10.99"
            )
        )
    }

    @MainActor
    @Test
    func cardNumberText_detectsVisaScheme() {
        // Given
        let cardFormViewModel = CardFormViewModel(
            paymentFlowProvider: checkoutFlowServiceProviderSpy
        )

        // When
        cardFormViewModel.cardNumberText = "4111 1111 1111 1111"

        // Then
        #expect(cardFormViewModel.detectedSchemeName == "visa")
    }

    @MainActor
    @Test
    func cardNumberText_detectsMastercardTwoSeriesScheme() {
        // Given
        let cardFormViewModel = CardFormViewModel(
            paymentFlowProvider: checkoutFlowServiceProviderSpy
        )

        // When
        cardFormViewModel.cardNumberText = "2221 0000 0000 0009"

        // Then
        #expect(cardFormViewModel.detectedSchemeName == "mastercard")
    }

    @MainActor
    @Test
    func cardNumberText_detectsAmexScheme() {
        // Given
        let cardFormViewModel = CardFormViewModel(
            paymentFlowProvider: checkoutFlowServiceProviderSpy
        )

        // When
        cardFormViewModel.cardNumberText = "378282246310005"

        // Then
        #expect(cardFormViewModel.detectedSchemeName == "amex")
    }

    @MainActor
    @Test
    func isPayButtonEnabled_isTrueForValidSanitizedInput() {
        // Given
        let cardFormViewModel = CardFormViewModel(
            paymentFlowProvider: checkoutFlowServiceProviderSpy
        )

        // When
        cardFormViewModel.cardNumberText = "4111 1111 1111 1111"
        cardFormViewModel.expiryDateText = "12/29"
        cardFormViewModel.cvvText = "123"

        // Then
        #expect(cardFormViewModel.isPayButtonEnabled)
        #expect(cardFormViewModel.viewState.isPayButtonEnabled)
    }

    @MainActor
    @Test
    func editingField_clearsExistingErrorMessage() {
        // Given
        let cardFormViewModel = CardFormViewModel(
            paymentFlowProvider: checkoutFlowServiceProviderSpy
        )
        cardFormViewModel.errorMessage = "Previous error"

        // When
        cardFormViewModel.cardNumberText = "4"

        // Then
        #expect(cardFormViewModel.errorMessage == nil)
    }
}

// MARK: - submit()

extension CardFormViewModelTests {

    @MainActor
    @Test
    func submit_whenFormIsInvalid_setsValidationError_andDoesNotCallProvider() async {
        // Given
        let cardFormViewModel = CardFormViewModel(
            paymentFlowProvider: checkoutFlowServiceProviderSpy
        )

        // When
        await cardFormViewModel.submit()

        // Then
        #expect(cardFormViewModel.errorMessage == "Enter the card number.")
        #expect(stubPaymentFlowProvider.tokenizeCardInvocationCount == 0)
        #expect(stubPaymentFlowProvider.createPaymentInvocationCount == 0)
    }

    @MainActor
    @Test
    func submit_whenExpiryMonthIsInvalid_setsMonthValidationError() async {
        // Given
        let cardFormViewModel = CardFormViewModel(
            paymentFlowProvider: checkoutFlowServiceProviderSpy
        )
        cardFormViewModel.cardNumberText = "4111 1111 1111 1111"
        cardFormViewModel.expiryDateText = "13/29"
        cardFormViewModel.cvvText = "123"

        // When
        await cardFormViewModel.submit()

        // Then
        #expect(cardFormViewModel.errorMessage == "Enter a valid expiry month.")
        #expect(stubPaymentFlowProvider.tokenizeCardInvocationCount == 0)
    }

    @MainActor
    @Test
    func submit_whenAlreadyLoading_doesNothing() async {
        // Given
        let cardFormViewModel = CardFormViewModel(
            paymentFlowProvider: checkoutFlowServiceProviderSpy
        )
        cardFormViewModel.cardNumberText = "4111 1111 1111 1111"
        cardFormViewModel.expiryDateText = "12/29"
        cardFormViewModel.cvvText = "123"
        cardFormViewModel.isLoading = true

        // When
        await cardFormViewModel.submit()

        // Then
        #expect(stubPaymentFlowProvider.tokenizeCardInvocationCount == 0)
        #expect(stubPaymentFlowProvider.createPaymentInvocationCount == 0)
    }

    @MainActor
    @Test
    func submit_whenTokenizationSucceeds_sendsSanitizedCardDetails_callsProvider_andInvokesCallback() async {
        // Given
        let expectedPaymentToken = PaymentToken(value: "payment_token_123")
        let tokenizationCallbackSpy = TokenizationCallbackSpy()

        stubPaymentFlowProvider.paymentTokenToReturn = expectedPaymentToken

        let cardFormViewModel = CardFormViewModel(
            payButtonTitle: "Pay now",
            paymentFlowProvider: checkoutFlowServiceProviderSpy,
            onCardTokenized: { paymentToken in
                tokenizationCallbackSpy.record(paymentToken)
            }
        )

        cardFormViewModel.cardNumberText = "4111 1111 1111 1111"
        cardFormViewModel.expiryDateText = "12/29"
        cardFormViewModel.cvvText = "123"

        // When
        await cardFormViewModel.submit()

        // Then
        checkoutFlowServiceProviderSpy.assertExpectedInvocations(
            .checkoutFlow(.tokenizeCard)
        )

        #expect(
            stubPaymentFlowProvider.receivedCardDetails == CardDetails(
                cardNumber: "4111111111111111",
                expirationMonth: "12",
                expirationYear: "29",
                securityCode: "123"
            )
        )
        #expect(tokenizationCallbackSpy.recordedPaymentTokens == [expectedPaymentToken])
        #expect(cardFormViewModel.isLoading == false)
        #expect(cardFormViewModel.errorMessage == nil)
    }

    @MainActor
    @Test
    func submit_whenTokenizationFails_setsMappedErrorMessage() async {
        // Given
        stubPaymentFlowProvider.tokenizeCardError = TestError.expectedFailure

        let cardFormViewModel = CardFormViewModel(
            paymentFlowProvider: checkoutFlowServiceProviderSpy,
            mapSubmitErrorMessage: { error in
                guard error is TestError else {
                    return "Unexpected error"
                }
                return "Mapped tokenization error"
            }
        )

        cardFormViewModel.cardNumberText = "4111 1111 1111 1111"
        cardFormViewModel.expiryDateText = "12/29"
        cardFormViewModel.cvvText = "123"

        // When
        await cardFormViewModel.submit()

        // Then
        checkoutFlowServiceProviderSpy.assertExpectedInvocations(
            .checkoutFlow(.tokenizeCard)
        )

        #expect(cardFormViewModel.isLoading == false)
        #expect(cardFormViewModel.errorMessage == "Mapped tokenization error")
    }
}

// MARK: - Helpers

extension CardFormViewModelTests {

    enum TestError: Error {
        case expectedFailure
    }

    final class TokenizationCallbackSpy {
        private(set) var recordedPaymentTokens: [PaymentToken] = []

        func record(_ paymentToken: PaymentToken) {
            recordedPaymentTokens.append(paymentToken)
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
