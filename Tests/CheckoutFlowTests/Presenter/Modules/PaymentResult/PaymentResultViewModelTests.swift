import XCTest

@testable import CheckoutFlow

final class PaymentResultViewModelTests: XCTestCase {

    @MainActor
    func test_init_whenStatusIsSuccess_buildsExpectedViewState() {
        // Given
        let paymentResultViewModel = PaymentResultViewModel(
            status: .success,
            titleText: "Payment completed",
            messageText: "Your payment was processed successfully.",
            primaryButtonTitle: "Done"
        )

        // Then
        XCTAssertEqual(
            paymentResultViewModel.viewState,
            PaymentResultViewState(
                status: .success,
                titleText: "Payment completed",
                messageText: "Your payment was processed successfully.",
                primaryButtonTitle: "Done",
                secondaryButtonTitle: nil,
                statusImageName: "checkmark.circle.fill",
                appearance: .success
            )
        )
    }

    @MainActor
    func test_init_whenStatusIsFailure_buildsExpectedViewState() {
        // Given
        let paymentResultViewModel = PaymentResultViewModel(
            status: .failure,
            titleText: "Payment failed",
            messageText: "We could not complete your payment. Please try again.",
            primaryButtonTitle: "Try Again",
            secondaryButtonTitle: "Close"
        )

        // Then
        XCTAssertEqual(
            paymentResultViewModel.viewState,
            PaymentResultViewState(
                status: .failure,
                titleText: "Payment failed",
                messageText: "We could not complete your payment. Please try again.",
                primaryButtonTitle: "Try Again",
                secondaryButtonTitle: "Close",
                statusImageName: "xmark.circle.fill",
                appearance: .failure
            )
        )
    }

    @MainActor
    func test_init_whenStatusIsCancelled_buildsExpectedViewState() {
        // Given
        let paymentResultViewModel = PaymentResultViewModel(
            status: .cancelled,
            titleText: "Payment cancelled",
            messageText: "The checkout flow was cancelled.",
            primaryButtonTitle: "Close"
        )

        // Then
        XCTAssertEqual(
            paymentResultViewModel.viewState,
            PaymentResultViewState(
                status: .cancelled,
                titleText: "Payment cancelled",
                messageText: "The checkout flow was cancelled.",
                primaryButtonTitle: "Close",
                secondaryButtonTitle: nil,
                statusImageName: "minus.circle.fill",
                appearance: .cancelled
            )
        )
    }
    
}

extension PaymentResultViewModelTests {

    final class ActionSpy {
        private(set) var invocationCount: Int = 0

        func recordInvocation() {
            invocationCount += 1
        }
    }
}
