import Foundation
import XCTest
import iOSCleanNetworkTesting

@testable import CheckoutFlow

final class CheckoutAPIProviderTests: XCTestCase {

    private var checkoutBaseURL: URL!
    private var service: CheckoutFlowServiceProviderSpy!

    override func setUpWithError() throws {
        try super.setUpWithError()

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

    override func tearDown() {
        checkoutBaseURL = nil
        service = nil
        super.tearDown()
    }

    private var sampleCardDetails: CardDetails {
        CardDetails(
            cardNumber: "4242424242424242",
            expirationMonth: "10",
            expirationYear: "2025",
            securityCode: "100"
        )
    }

    private func makeSampleCardPayment() throws -> CardPayment {
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

    func test_tokenSetup_buildsTokensEndpointWithPublicKeyAuthorization() throws {
        // Given
        let tokenSetup = CheckoutAPISetup.token(
            baseURL: checkoutBaseURL,
            publicAPIKey: "pk_sbox_example",
            tokenizeCardRequest: .init(domain: sampleCardDetails)
        )

        // When
        let urlRequest = try tokenSetup.request

        // Then
        XCTAssertEqual(urlRequest.url?.absoluteString, "https://api.sandbox.checkout.com/tokens")
        XCTAssertEqual(urlRequest.httpMethod, "POST")
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Authorization"), "Bearer pk_sbox_example")
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Accept"), "application/json")
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }

    func test_paymentSetup_buildsPaymentsEndpointWithSecretKeyAuthorization() throws {
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
        XCTAssertEqual(urlRequest.url?.absoluteString, "https://api.sandbox.checkout.com/payments")
        XCTAssertEqual(urlRequest.httpMethod, "POST")
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Authorization"), "Bearer sk_sbox_example")
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Accept"), "application/json")
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }

    func test_tokenizeCard_returnsPaymentTokenFromFixture() async throws {
        // Given
        service.resetAllCounters()
        let expectedPaymentToken = PaymentToken(value: "tok_ubfj2q76miwundwlk72vxt2i7q")

        // When
        let paymentToken = try await service.tokenizeCard(sampleCardDetails)

        // Then
        XCTAssertEqual(paymentToken, expectedPaymentToken)
        service.assertExpectedInvocations(
            .checkoutFlow(.tokenizeCard)
        )
    }

    func test_createPayment_returnsPendingStatusAndRedirectURLFromFixture() async throws {
        // Given
        service.resetAllCounters()
        let cardPayment = try makeSampleCardPayment()
        let expectedRedirectURL = try XCTUnwrap(
            URL(string: "https://api.checkout.com/3ds/pay_mbabizu24mvu3mela5njyhpit4")
        )

        // When
        let paymentSession = try await service.createPayment(cardPayment)

        // Then
        XCTAssertEqual(paymentSession.status, .pending)
        XCTAssertEqual(paymentSession.redirectURL, expectedRedirectURL)
        service.assertExpectedInvocations(
            .checkoutFlow(.createPayment)
        )
    }

    func test_tokenizeCard_throwsInjectedError() async {
        // Given
        service.resetAllCounters()
        service.failingMethods(
            .checkoutFlow(.tokenizeCard)
        )

        // When / Then
        do {
            _ = try await service.tokenizeCard(sampleCardDetails)
            XCTFail("Expected tokenizeCard to throw injected error")
        } catch {
            service.assertExpectedInvocations(
                .checkoutFlow(.tokenizeCard)
            )
        }
    }
}

extension CheckoutAPIProviderTests {

    enum Errors: Error {
        case invalidBaseURL
        case invalidSuccessURL
        case invalidFailureURL
    }
}
