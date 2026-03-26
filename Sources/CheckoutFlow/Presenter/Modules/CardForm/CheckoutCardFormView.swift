import SwiftUI
import Observation

struct CheckoutCardFormView: View {
    
    @Bindable var viewModel: CheckoutCardFormViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                CardNumberInputView(
                    cardNumberText: $viewModel.cardNumberText,
                    schemeName: viewModel.detectedSchemeName
                )
                
                HStack(alignment: .top, spacing: 12) {
                    ExpiryDateInputView(
                        expiryDateText: $viewModel.expiryDateText
                    )
                    
                    CVVInputView(
                        cvvText: $viewModel.cvvText
                    )
                }
                
                if let errorMessage = viewModel.errorMessage {
                    CardFormErrorView(message: errorMessage)
                }
                
                if viewModel.isLoading {
                    CardFormLoadingView()
                }
                
                PayButtonView(
                    title: viewModel.payButtonTitle,
                    isEnabled: viewModel.isPayButtonEnabled,
                    isLoading: viewModel.isLoading,
                    action: {
                        Task {
                            await viewModel.submit()
                        }
                    }
                )
            }
            .padding(16)
        }
        .navigationTitle("Checkout")
        .disabled(viewModel.isLoading)
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
            redirectURL: URL(string: "https://example.com")!
        )
    }
}

#Preview {
    CheckoutCardFormView(
        viewModel: CheckoutCardFormViewModel(
            payButtonTitle: "Pay",
            paymentFlowProvider: PreviewPaymentFlowProvider(),
            onCardTokenized: { _ in }
        )
    )
}
#endif
