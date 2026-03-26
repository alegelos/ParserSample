import SwiftUI

struct CardNumberInputView: View {
    
    @Binding var cardNumberText: String
    
    let schemeName: String?
    let placeholderText: String
    
    init(
        cardNumberText: Binding<String>,
        schemeName: String? = nil,
        placeholderText: String = "Card number"
    ) {
        self._cardNumberText = cardNumberText
        self.schemeName = schemeName
        self.placeholderText = placeholderText
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Card Number")
                .font(.footnote)
                .fontWeight(.semibold)
            
            HStack(spacing: 8) {
                TextField(placeholderText, text: $cardNumberText)
                    .keyboardType(.numberPad)
                    .textContentType(.creditCardNumber)
                    .onChange(of: cardNumberText) { newValue in
                        cardNumberText = formatCardNumber(from: newValue)
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
    
    private func formatCardNumber(from rawValue: String) -> String {
        let onlyDigits = rawValue.filter(\.isNumber)
        let limitedDigits = String(onlyDigits.prefix(19))
        
        var groupedCharacters: [String] = []
        var currentIndex = limitedDigits.startIndex
        
        while currentIndex < limitedDigits.endIndex {
            let nextIndex = limitedDigits.index(currentIndex, offsetBy: 4, limitedBy: limitedDigits.endIndex) ?? limitedDigits.endIndex
            groupedCharacters.append(String(limitedDigits[currentIndex..<nextIndex]))
            currentIndex = nextIndex
        }
        
        return groupedCharacters.joined(separator: " ")
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
