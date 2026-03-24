import Foundation
import Testing
import iOSCleanNetworkTesting

@testable import CheckoutFlow

struct CheckoutAPIProviderTests {

    let checkoutBaseURL: URL
    let service: CheckoutFlowServiceProviderSpy

    init() throws {
        guard let checkoutBaseURL = URL(string: "https://api.sandbox.checkout.com") else {
            throw Errors.invalidBaseURL
        }

        let checkoutAPIProvider = CheckoutAPIProvider(
            baseURL: checkoutBaseURL,
            publicAPIKey: "pk_sbox_example",
            secretAPIKey: "sk_sbox_example",
            session: MockedURLSession()
        )

        self.checkoutBaseURL = checkoutBaseURL
        self.service = CheckoutFlowServiceProviderSpy(cardPaymentFlowProvider: checkoutAPIProvider)
    }

    var sampleCardDetails: CardDetails {
        CardDetails(
            cardNumber: "4242424242424242",
            expirationMonth: "10",
            expirationYear: "2025",
            securityCode: "100"
        )
    }

    func makeSampleCardPayment() throws -> CardPayment {
        guard let successURL = URL(string: "https://example.com/payments/success") else {
            throw Errors.invalidSuccessURL
        }

        guard let failureURL = URL(string: "https://example.com/payments/fail") else {
            throw Errors.invalidFailureURL
        }

        return CardPayment(
            paymentToken: PaymentToken(value: "tok_4gzeau5o2uqubbk6fufs3m7p54"),
            amountInMinorUnits: 6540,
            currencyCode: "GBP",
            successURL: successURL,
            failureURL: failureURL
        )
    }
}

// MARK: - CheckoutAPISetup

extension CheckoutAPIProviderTests {

    @Test
    func tokenSetup_buildsTokensEndpointWithPublicKeyAuthorization() throws {
        // Given
        let tokenSetup = CheckoutAPISetup.token(
            baseURL: checkoutBaseURL,
            publicAPIKey: "pk_sbox_example",
            tokenizeCardRequest: .init(domain: sampleCardDetails)
        )

        // When
        let urlRequest = try tokenSetup.request

        // Then
        #expect(urlRequest.url?.absoluteString == "https://api.sandbox.checkout.com/tokens")
        #expect(urlRequest.httpMethod == "POST")
        #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == "Bearer pk_sbox_example")
        #expect(urlRequest.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test
    func paymentSetup_buildsPaymentsEndpointWithSecretKeyAuthorization() throws {
        // Given
        let cardPayment = try makeSampleCardPayment()
        let paymentSetup = CheckoutAPISetup.payment(
            baseURL: checkoutBaseURL,
            secretAPIKey: "sk_sbox_example",
            paymentRequest: .init(domain: cardPayment)
        )

        // When
        let urlRequest = try paymentSetup.request

        // Then
        #expect(urlRequest.url?.absoluteString == "https://api.sandbox.checkout.com/payments")
        #expect(urlRequest.httpMethod == "POST")
        #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == "Bearer sk_sbox_example")
        #expect(urlRequest.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }
}

// MARK: - CheckoutAPIProvider

extension CheckoutAPIProviderTests {

    @Test
    func tokenizeCard_returnsPaymentTokenFromFixture() async throws {
        // Given
        service.resetAllCounters()
        let expectedPaymentToken = PaymentToken(value: "tok_ubfj2q76miwundwlk72vxt2i7q")

        // When
        let paymentToken = try await service.tokenizeCard(sampleCardDetails)

        // Then
        #expect(paymentToken == expectedPaymentToken)
        service.assertExpectedInvocations(
            .checkoutFlow(.tokenizeCard)
        )
    }

    @Test
    func createPayment_returnsPendingStatusAndRedirectURLFromFixture() async throws {
        // Given
        service.resetAllCounters()
        let cardPayment = try makeSampleCardPayment()
        let expectedRedirectURL = try #require(
            URL(string: "https://api.checkout.com/3ds/pay_mbabizu24mvu3mela5njyhpit4")
        )

        // When
        let paymentSession = try await service.createPayment(cardPayment)

        // Then
        #expect(paymentSession.status == .pending)
        #expect(paymentSession.redirectURL == expectedRedirectURL)
        service.assertExpectedInvocations(
            .checkoutFlow(.createPayment)
        )
    }

    @Test
    func tokenizeCard_throwsInjectedError() async throws {
        // Given
        service.resetAllCounters()
        service.failingMethods(
            .checkoutFlow(.tokenizeCard)
        )

        // When
        do {
            _ = try await service.tokenizeCard(sampleCardDetails)
            Issue.record("Expected tokenizeCard to throw injected error")
            return
        } catch { }

        // Then
        service.assertExpectedInvocations(
            .checkoutFlow(.tokenizeCard)
        )
    }
}

// MARK: - Helping Structures

extension CheckoutAPIProviderTests {

    enum Errors: Error {
        case invalidBaseURL
        case invalidSuccessURL
        case invalidFailureURL
    }
}
