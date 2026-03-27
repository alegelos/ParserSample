import Testing

@testable import CheckoutFlow

struct PaymentResultViewModelTests { }

// MARK: - View state mapping

extension PaymentResultViewModelTests {

    @MainActor
    @Test
    func init_whenStatusIsSuccess_buildsExpectedViewState() {
        // Given
        let paymentResultViewModel = PaymentResultViewModel(
            status: .success,
            titleText: "Payment completed",
            messageText: "Your payment was processed successfully.",
            primaryButtonTitle: "Done"
        )

        // Then
        #expect(
            paymentResultViewModel.viewState == PaymentResultViewState(
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
    @Test
    func init_whenStatusIsFailure_buildsExpectedViewState() {
        // Given
        let paymentResultViewModel = PaymentResultViewModel(
            status: .failure,
            titleText: "Payment failed",
            messageText: "We could not complete your payment. Please try again.",
            primaryButtonTitle: "Try Again",
            secondaryButtonTitle: "Close"
        )

        // Then
        #expect(
            paymentResultViewModel.viewState == PaymentResultViewState(
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
    @Test
    func init_whenStatusIsCancelled_buildsExpectedViewState() {
        // Given
        let paymentResultViewModel = PaymentResultViewModel(
            status: .cancelled,
            titleText: "Payment cancelled",
            messageText: "The checkout flow was cancelled.",
            primaryButtonTitle: "Close"
        )

        // Then
        #expect(
            paymentResultViewModel.viewState == PaymentResultViewState(
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

// MARK: - Factory helpers

extension PaymentResultViewModelTests {

    @MainActor
    @Test
    func success_usesExpectedDefaultValues() {
        // Given
        let paymentResultViewModel = PaymentResultViewModel.success()

        // Then
        #expect(
            paymentResultViewModel.viewState == PaymentResultViewState(
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
    @Test
    func failure_usesExpectedDefaultValues() {
        // Given
        let paymentResultViewModel = PaymentResultViewModel.failure()

        // Then
        #expect(
            paymentResultViewModel.viewState == PaymentResultViewState(
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
    @Test
    func cancelled_usesExpectedDefaultValues() {
        // Given
        let paymentResultViewModel = PaymentResultViewModel.cancelled()

        // Then
        #expect(
            paymentResultViewModel.viewState == PaymentResultViewState(
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

    @MainActor
    @Test
    func failure_allowsHidingSecondaryButton() {
        // Given
        let paymentResultViewModel = PaymentResultViewModel.failure(
            secondaryButtonTitle: nil
        )

        // Then
        #expect(paymentResultViewModel.viewState.secondaryButtonTitle == nil)
    }
}

// MARK: - Button actions

extension PaymentResultViewModelTests {

    @MainActor
    @Test
    func didTapPrimaryButton_callsPrimaryActionOnly() {
        // Given
        let primaryActionSpy = ActionSpy()
        let secondaryActionSpy = ActionSpy()

        let paymentResultViewModel = PaymentResultViewModel.failure(
            onPrimaryAction: {
                primaryActionSpy.recordInvocation()
            },
            onSecondaryAction: {
                secondaryActionSpy.recordInvocation()
            }
        )

        // When
        paymentResultViewModel.didTapPrimaryButton()

        // Then
        #expect(primaryActionSpy.invocationCount == 1)
        #expect(secondaryActionSpy.invocationCount == 0)
    }

    @MainActor
    @Test
    func didTapSecondaryButton_callsSecondaryActionOnly() {
        // Given
        let primaryActionSpy = ActionSpy()
        let secondaryActionSpy = ActionSpy()

        let paymentResultViewModel = PaymentResultViewModel.failure(
            onPrimaryAction: {
                primaryActionSpy.recordInvocation()
            },
            onSecondaryAction: {
                secondaryActionSpy.recordInvocation()
            }
        )

        // When
        paymentResultViewModel.didTapSecondaryButton()

        // Then
        #expect(primaryActionSpy.invocationCount == 0)
        #expect(secondaryActionSpy.invocationCount == 1)
    }

    @MainActor
    @Test
    func didTapPrimaryButton_whenActionIsNil_doesNothing() {
        // Given
        let paymentResultViewModel = PaymentResultViewModel.success()

        // When
        paymentResultViewModel.didTapPrimaryButton()

        // Then
        #expect(Bool(true))
    }

    @MainActor
    @Test
    func didTapSecondaryButton_whenActionIsNil_doesNothing() {
        // Given
        let paymentResultViewModel = PaymentResultViewModel.failure(
            onSecondaryAction: nil
        )

        // When
        paymentResultViewModel.didTapSecondaryButton()

        // Then
        #expect(Bool(true))
    }
}

// MARK: - Helping structures

extension PaymentResultViewModelTests {

    final class ActionSpy {
        private(set) var invocationCount: Int = 0

        func recordInvocation() {
            invocationCount += 1
        }
    }
}
