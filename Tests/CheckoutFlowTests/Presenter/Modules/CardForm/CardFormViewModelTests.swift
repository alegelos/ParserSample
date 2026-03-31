import Foundation
import XCTest

@testable import CheckoutFlow

final class CardFormViewModelTests: XCTestCase {

    private var stubPaymentFlowProvider: StubPaymentFlowProvider!
    private var checkoutFlowServiceProviderSpy: CheckoutFlowServiceProviderSpy!

    override func setUp() {
        super.setUp()
        let stubPaymentFlowProvider = StubPaymentFlowProvider()
        self.stubPaymentFlowProvider = stubPaymentFlowProvider
        self.checkoutFlowServiceProviderSpy = CheckoutFlowServiceProviderSpy(
            cardPaymentFlowProvider: stubPaymentFlowProvider
        )
    }

    override func tearDown() {
        stubPaymentFlowProvider = nil
        checkoutFlowServiceProviderSpy = nil
        super.tearDown()
    }

    @MainActor
    func test_cardNumberText_detectsVisaScheme() {
        // Given
        let cardFormViewModel = CardFormViewModel(
            paymentFlowProvider: checkoutFlowServiceProviderSpy
        )

        // When
        cardFormViewModel.cardNumberText = "4111 1111 1111 1111"

        // Then
        XCTAssertEqual(cardFormViewModel.detectedSchemeName, "visa")
    }

    @MainActor
    func test_cardNumberText_detectsMastercardTwoSeriesScheme() {
        // Given
        let cardFormViewModel = CardFormViewModel(
            paymentFlowProvider: checkoutFlowServiceProviderSpy
        )

        // When
        cardFormViewModel.cardNumberText = "2221 0000 0000 0009"

        // Then
        XCTAssertEqual(cardFormViewModel.detectedSchemeName, "mastercard")
    }

    @MainActor
    func test_cardNumberText_detectsAmexScheme() {
        // Given
        let cardFormViewModel = CardFormViewModel(
            paymentFlowProvider: checkoutFlowServiceProviderSpy
        )

        // When
        cardFormViewModel.cardNumberText = "378282246310005"

        // Then
        XCTAssertEqual(cardFormViewModel.detectedSchemeName, "amex")
    }

    @MainActor
    func test_isPayButtonEnabled_isTrueForValidSanitizedInput() {
        // Given
        let cardFormViewModel = CardFormViewModel(
            paymentFlowProvider: checkoutFlowServiceProviderSpy
        )

        // When
        cardFormViewModel.cardNumberText = "4111 1111 1111 1111"
        cardFormViewModel.expiryDateText = "12/29"
        cardFormViewModel.cvvText = "123"

        // Then
        XCTAssertTrue(cardFormViewModel.isPayButtonEnabled)
    }

    @MainActor
    func test_editingField_clearsExistingErrorMessage() {
        // Given
        let cardFormViewModel = CardFormViewModel(
            paymentFlowProvider: checkoutFlowServiceProviderSpy
        )
        cardFormViewModel.errorMessage = "Previous error"

        // When
        cardFormViewModel.cardNumberText = "4"

        // Then
        XCTAssertNil(cardFormViewModel.errorMessage)
    }

    @MainActor
    func test_submit_whenFormIsInvalid_setsValidationError_andDoesNotCallProvider() async {
        // Given
        let cardFormViewModel = CardFormViewModel(
            paymentFlowProvider: checkoutFlowServiceProviderSpy
        )

        // When
        await cardFormViewModel.submit()

        // Then
        XCTAssertEqual(cardFormViewModel.errorMessage, "Enter the card number.")
        XCTAssertEqual(stubPaymentFlowProvider.tokenizeCardInvocationCount, 0)
        XCTAssertEqual(stubPaymentFlowProvider.createPaymentInvocationCount, 0)
    }

    @MainActor
    func test_submit_whenExpiryMonthIsInvalid_setsMonthValidationError() async {
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
        XCTAssertEqual(cardFormViewModel.errorMessage, "Enter a valid expiry month.")
        XCTAssertEqual(stubPaymentFlowProvider.tokenizeCardInvocationCount, 0)
    }

    @MainActor
    func test_submit_whenAlreadyLoading_doesNothing() async {
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
        XCTAssertEqual(stubPaymentFlowProvider.tokenizeCardInvocationCount, 0)
        XCTAssertEqual(stubPaymentFlowProvider.createPaymentInvocationCount, 0)
    }

    @MainActor
    func test_submit_whenTokenizationSucceeds_sendsSanitizedCardDetails_callsProvider_andInvokesCallback() async {
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

        XCTAssertEqual(
            stubPaymentFlowProvider.receivedCardDetails,
            CardDetails(
                cardNumber: "4111111111111111",
                expirationMonth: "12",
                expirationYear: "29",
                securityCode: "123"
            )
        )
        XCTAssertEqual(tokenizationCallbackSpy.recordedPaymentTokens, [expectedPaymentToken])
        XCTAssertFalse(cardFormViewModel.isLoading)
        XCTAssertNil(cardFormViewModel.errorMessage)
    }

    @MainActor
    func test_submit_whenTokenizationFails_setsMappedErrorMessage() async {
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

        XCTAssertFalse(cardFormViewModel.isLoading)
        XCTAssertEqual(cardFormViewModel.errorMessage, "Mapped tokenization error")
    }
}

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
