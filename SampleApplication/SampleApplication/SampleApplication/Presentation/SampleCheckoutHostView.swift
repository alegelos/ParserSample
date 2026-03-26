import SwiftUI
import CheckoutFlow

struct SampleCheckoutHostView: View {

    private enum ResolvedState {
        case ready(CheckoutFlowViewModel)
        case failed(String)
    }

    let onFinished: (CheckoutFlowCompletionResult) -> Void

    private let resolvedState: ResolvedState

    init(onFinished: @escaping (CheckoutFlowCompletionResult) -> Void) {
        self.onFinished = onFinished
        self.resolvedState = Self.resolveState(onFinished: onFinished)
    }

    var body: some View {
        Group {
            switch resolvedState {
            case .ready(let checkoutFlowViewModel):
                CheckoutFlowView(viewModel: checkoutFlowViewModel)
            case .failed(let errorMessage):
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 32))
                    Text("Checkout could not be initialized.")
                        .font(.headline)
                    Text(errorMessage)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .padding(24)
            }
        }
    }

    private static func resolveState(
        onFinished: @escaping (CheckoutFlowCompletionResult) -> Void
    ) -> ResolvedState {
        do {
            let checkoutSandboxConfiguration = try CheckoutSandboxConfiguration.load()

            CheckoutFlowModule.create(
                configuration: checkoutSandboxConfiguration.moduleConfiguration
            )

            let checkoutFlowViewModel = try CheckoutFlowViewModel(
                payButtonTitle: checkoutSandboxConfiguration.payButtonTitle,
                amountInMinorUnits: checkoutSandboxConfiguration.amountInMinorUnits,
                currencyCode: checkoutSandboxConfiguration.currencyCode,
                successURL: checkoutSandboxConfiguration.successURL,
                failureURL: checkoutSandboxConfiguration.failureURL,
                onComplete: onFinished
            )

            return .ready(checkoutFlowViewModel)
        } catch {
            return .failed(error.localizedDescription)
        }
    }
}
