import SwiftUI

struct CardNumberInputView: View {
    
    @Binding var cardNumberText: String
    
    let schemeName: String?
    let placeholderText: String
    
    init(
        cardNumberText: Binding<String>,
        schemeName: String? = nil,
        placeholderText: String = CheckoutFlowLocalized.string("checkout.card_form.card_number.placeholder")
    ) {
        self._cardNumberText = cardNumberText
        self.schemeName = schemeName
        self.placeholderText = placeholderText
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(CheckoutFlowLocalized.string("checkout.card_form.card_number.title"))
                .font(.footnote)
                .fontWeight(.semibold)
            
            HStack(spacing: 8) {
                TextField(placeholderText, text: $cardNumberText)
                    .keyboardType(.numberPad)
                    .textContentType(.creditCardNumber)
                    .onChange(of: cardNumberText) { newValue in
                        cardNumberText = CardInputUtils.formatCardNumberInput(from: newValue)
                    }
                
                if schemeName != nil {
                    CardSchemeIconView(schemeName: schemeName)
                }
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
struct CardNumberInputView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            CardNumberInputView(
                cardNumberText: .constant("4242 4242 4242 4242"),
                schemeName: "visa"
            )
            
            CardNumberInputView(
                cardNumberText: .constant("5555 5555 5555 4444"),
                schemeName: "mastercard"
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
