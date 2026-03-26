import Foundation
import SwiftUI

struct SampleApplicationRootView: View {

    @State private var isPresentingCheckout = false
    @State private var resultMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Button("Start Checkout") {
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
            .sheet(isPresented: $isPresentingCheckout) {
                SampleCheckoutHostView(
                    onFinished: { result in
                        switch result {
                        case .completedSuccessfully:
                            resultMessage = "Payment completed successfully"
                        case .completedWithFailure(let message):
                            resultMessage = message ?? "Payment failed"
                        case .cancelled:
                            resultMessage = "Payment cancelled"
                        }
                    }
                )
            }
        }
    }
}
