import SwiftUI

struct CVVInputView: View {
    
    @Binding var cvvText: String
    
    let placeholderText: String
    let maximumLength: Int
    
    init(
        cvvText: Binding<String>,
        placeholderText: String = CheckoutFlowLocalized.string("checkout.card_form.security_code.placeholder"),
        maximumLength: Int = 4
    ) {
        self._cvvText = cvvText
        self.placeholderText = placeholderText
        self.maximumLength = maximumLength
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(CheckoutFlowLocalized.string("checkout.card_form.security_code.title"))
                .font(.footnote)
                .fontWeight(.semibold)
            
            SecureField(placeholderText, text: $cvvText)
                .keyboardType(.numberPad)
                .onChange(of: cvvText) { newValue in
                    cvvText = CardInputUtils.sanitizeCardSecurityCodeInput(
                        from: newValue,
                        maximumLength: maximumLength
                    )
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 14)
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
}

#if DEBUG
struct CVVInputView_Previews: PreviewProvider {
    static var previews: some View {
        CVVInputView(cvvText: .constant("123"))
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif
