import SwiftUI

struct PayButtonView: View {
    
    let title: String
    let isEnabled: Bool
    let isLoading: Bool
    let action: () -> Void
    
    init(
        title: String = CheckoutFlowLocalized.string("checkout.card_form.pay_button_title"),
        isEnabled: Bool = true,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isEnabled = isEnabled
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
                
                Text(isLoading ? CheckoutFlowLocalized.string("checkout.card_form.loading_message") : title)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isEnabled && !isLoading ? Color.blue : Color.gray.opacity(0.6))
            )
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
        .accessibilityLabel(isLoading ? CheckoutFlowLocalized.string("checkout.card_form.loading_title") : title)
    }
}

#if DEBUG
struct PayButtonView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            PayButtonView(title: "Pay €19.99") { }
            PayButtonView(title: "Pay €19.99", isEnabled: false) { }
            PayButtonView(title: "Pay €19.99", isLoading: true) { }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
