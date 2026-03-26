import SwiftUI
import CheckoutFlow

struct SampleCheckoutHostView: View {

    private enum ResolvedState {
        case ready(CheckoutFlowPaymentConfiguration)
        case failed(String)
    }

    let onFinished: (CheckoutFlowCompletionResult) -> Void

    private let resolvedState: ResolvedState

    init(onFinished: @escaping (CheckoutFlowCompletionResult) -> Void) {
        self.onFinished = onFinished
        self.resolvedState = SampleCheckoutHostView.resolveState()
    }

    var body: some View {
        Group {
            switch resolvedState {
            case .ready(let paymentConfiguration):
                if let checkoutFlowView = try? CheckoutFlowView(
                    paymentConfiguration: paymentConfiguration,
                    onComplete: onFinished
                ) {
                    checkoutFlowView
                } else {
                    failureView(message: "Checkout could not be initialized.")
                }

            case .failed(let errorMessage):
                failureView(message: errorMessage)
            }
        }
    }

    private static func resolveState() -> ResolvedState {
        do {
            let configuration = try CheckoutFlowSetup.checkoutFlowConfiguration
            CheckoutFlowModule.create(configuration: configuration)

            return .ready(CheckoutFlowSetup.samplePayment)
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    @ViewBuilder
    private func failureView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
            Text("Checkout could not be initialized.")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(24)
    }
}
