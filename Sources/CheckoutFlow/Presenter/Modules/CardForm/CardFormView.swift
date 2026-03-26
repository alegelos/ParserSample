import SwiftUI
import Observation

struct CardFormView: View {
    
    @Bindable var viewModel: CardFormViewModel
    @State private var isLoadingOverlayVisible = false
    
    var body: some View {
        ZStack {
            cardFormContent
                .disabled(viewModel.isLoading)
                .blur(radius: viewModel.isLoading ? 2 : 0)
                .scaleEffect(viewModel.isLoading ? 0.985 : 1)
                .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)
            
            if isLoadingOverlayVisible {
                CardFormBlockingLoadingView()
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.98)),
                        removal: .opacity
                    ))
                    .zIndex(1)
            }
        }
        .navigationTitle("Checkout")
        .onChange(of: viewModel.isLoading) { _, isLoading in
            withAnimation(.easeInOut(duration: 0.2)) {
                isLoadingOverlayVisible = isLoading
            }
        }
        .onAppear {
            isLoadingOverlayVisible = viewModel.isLoading
        }
    }
    
    private var cardFormContent: some View {
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
                
                PayButtonView(
                    title: viewModel.payButtonTitle,
                    isEnabled: viewModel.isPayButtonEnabled,
                    isLoading: false,
                    action: {
                        Task {
                            await viewModel.submit()
                        }
                    }
                )
            }
            .padding(16)
        }
    }
}

private struct CardFormBlockingLoadingView: View {
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.black.opacity(0.16))
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)
                
                VStack(spacing: 6) {
                    Text("Processing payment")
                        .font(.headline)
                    
                    Text("Please wait a moment...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(.white.opacity(0.12))
            )
            .shadow(radius: 20, y: 8)
            .padding(24)
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
            redirectURL: URL(string: "https://example.com")!
        )
    }
}

#Preview {
    NavigationStack {
        CardFormView(
            viewModel: CardFormViewModel(
                payButtonTitle: "Pay",
                paymentFlowProvider: PreviewPaymentFlowProvider(),
                onCardTokenized: { _ in }
            )
        )
    }
}
#endif
