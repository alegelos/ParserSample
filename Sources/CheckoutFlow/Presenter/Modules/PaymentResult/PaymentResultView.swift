import SwiftUI
import Observation

struct PaymentResultView: View {
    
    @Bindable var viewModel: PaymentResultViewModel
    
    var body: some View {
        let viewState = viewModel.viewState
        
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: viewState.statusImageName)
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(statusColor(for: viewState.appearance))
            
            VStack(spacing: 8) {
                Text(viewState.titleText)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(viewState.messageText)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                Button(action: {
                    viewModel.didTapPrimaryButton()
                }) {
                    Text(viewState.primaryButtonTitle)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
                .foregroundColor(.white)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(primaryButtonColor(for: viewState.appearance))
                )
                
                if let secondaryButtonTitle = viewState.secondaryButtonTitle {
                    Button(action: {
                        viewModel.didTapSecondaryButton()
                    }) {
                        Text(secondaryButtonTitle)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.primary)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.separator).opacity(0.25), lineWidth: 1)
                    )
                }
            }
            
            Spacer()
        }
        .padding(24)
        .navigationBarBackButtonHidden(true)
    }
    
    private func statusColor(for appearance: PaymentResultViewState.CheckoutPaymentResultAppearance) -> Color {
        switch appearance {
        case .success:
            return .green
        case .failure:
            return .red
        case .cancelled:
            return .orange
        }
    }
    
    private func primaryButtonColor(for appearance: PaymentResultViewState.CheckoutPaymentResultAppearance) -> Color {
        switch appearance {
        case .success:
            return .green
        case .failure, .cancelled:
            return .blue
        }
    }
}
