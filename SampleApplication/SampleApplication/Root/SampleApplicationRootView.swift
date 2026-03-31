import SwiftUI
import CheckoutFlow

struct SampleApplicationRootView: View {

    @State private var isPresentingCheckout = false
    @State private var resultMessage: String?
    @State private var pendingCheckoutResult: CheckoutFlowCompletionResult?
    
    var body: some View {
        VStack(spacing: 16) {
            Button("Start Checkout") {
                resultMessage = nil
                pendingCheckoutResult = nil
                isPresentingCheckout = true
            }
            .buttonStyle(.borderedProminent)
            
            if let resultMessage {
                Text(resultMessage)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .navigationTitle("Checkout Sample")
        .sheet(
            isPresented: $isPresentingCheckout,
            onDismiss: handleCheckoutDismissed
        ) {
            SampleCheckoutHostView(
                onFinished: { result in
                    pendingCheckoutResult = result
                    isPresentingCheckout = false
                }
            )
        }
    }

    private func handleCheckoutDismissed() {
        let finalResult = pendingCheckoutResult ?? .cancelled

        switch finalResult {
        case .completedSuccessfully:
            resultMessage = "Payment completed successfully"
        case .completedWithFailure(let message):
            resultMessage = message ?? "Payment failed"
        case .cancelled:
            resultMessage = "Payment cancelled"
        }

        pendingCheckoutResult = nil
    }
    
}
