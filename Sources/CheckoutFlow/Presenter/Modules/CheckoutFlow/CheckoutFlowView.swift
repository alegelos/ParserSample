import SwiftUI

public struct CheckoutFlowView: View {

    @State private var viewModel: CheckoutFlowViewModel

    @MainActor
    public init(
        paymentConfiguration: CheckoutFlowPaymentConfiguration,
        mapSubmitErrorMessage: ((Error) -> String)? = nil,
        onComplete: @escaping (CheckoutFlowCompletionResult) -> Void
    ) throws {
        self._viewModel = State(
            initialValue: try CheckoutFlowModule.shared.makeCheckoutFlowViewModel(
                paymentConfiguration: paymentConfiguration,
                mapSubmitErrorMessage: mapSubmitErrorMessage,
                onComplete: onComplete
            )
        )
    }

    init(viewModel: CheckoutFlowViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            currentStepView
                .animation(.default, value: viewModel.viewState.currentStep)
        }
    }

    @ViewBuilder
    private var currentStepView: some View {
        switch viewModel.viewState.currentStep {
        case .cardForm:
            CardFormView(viewModel: viewModel.cardFormViewModel)

        case .threeDSChallenge:
            if let threeDSChallengeViewModel = viewModel.threeDSChallengeViewModel {
                ThreeDSChallengeView(viewModel: threeDSChallengeViewModel)
            } else {
                ProgressView()
            }

        case .paymentResult:
            if let paymentResultViewModel = viewModel.paymentResultViewModel {
                PaymentResultView(viewModel: paymentResultViewModel)
            } else {
                ProgressView()
            }
        }
    }
}

#if DEBUG
private struct PreviewPaymentFlowProvider: PaymentFlowProviderProtocol {

    func tokenizeCard(_ cardDetails: CardDetails) async throws -> PaymentToken {
        PaymentToken(value: "preview_token")
    }

    func createPayment(_ cardPayment: CardPayment) async throws -> ThreeDSPaymentSession {
        ThreeDSPaymentSession(
            status: .pending,
            redirectURL: URL(string: "https://example.com/3ds")!
        )
    }
}

#Preview {
    CheckoutFlowView(
        viewModel: CheckoutFlowViewModel(
            payButtonTitle: "Pay €10.99",
            paymentFlowProvider: PreviewPaymentFlowProvider(),
            amountInMinorUnits: 1_099,
            currencyCode: "EUR",
            successURL: URL(string: "myapp://checkout/success")!,
            failureURL: URL(string: "myapp://checkout/failure")!,
            onComplete: { _ in }
        )
    )
}
#endif
