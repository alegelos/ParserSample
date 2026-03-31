import SwiftUI

public struct CheckoutFlowView: View {

    @StateObject private var viewModel: CheckoutFlowViewModel

    @MainActor
    public init(
        paymentConfiguration: CheckoutFlowPaymentConfiguration,
        mapSubmitErrorMessage: ((Error) -> String)? = nil,
        onComplete: @escaping (CheckoutFlowCompletionResult) -> Void
    ) throws {
        let checkoutFlowViewModel = try CheckoutFlowModule.shared.makeCheckoutFlowViewModel(
            paymentConfiguration: paymentConfiguration,
            mapSubmitErrorMessage: mapSubmitErrorMessage,
            onComplete: onComplete
        )

        _viewModel = StateObject(wrappedValue: checkoutFlowViewModel)
    }

    public var body: some View {
        NavigationView {
            currentStepView
                .animation(.default, value: viewModel.currentStep)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    @ViewBuilder
    private var currentStepView: some View {
        switch viewModel.currentStep {
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
