import SwiftUI

struct ExpiryDateInputView: View {
    
    @Binding var expiryDateText: String
    
    let placeholderText: String
    
    init(
        expiryDateText: Binding<String>,
        placeholderText: String = "MM/YY"
    ) {
        self._expiryDateText = expiryDateText
        self.placeholderText = placeholderText
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Expiry Date")
                .font(.footnote)
                .fontWeight(.semibold)
            
            TextField(placeholderText, text: $expiryDateText)
                .keyboardType(.numberPad)
                .textContentType(.none)
                .onChange(of: expiryDateText) { newValue in
                    expiryDateText = formatExpiryDate(from: newValue)
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
    
    private func formatExpiryDate(from rawValue: String) -> String {
        let onlyDigits = rawValue.filter(\.isNumber)
        let limitedDigits = String(onlyDigits.prefix(4))
        
        guard limitedDigits.count > 2 else {
            return limitedDigits
        }
        
        let monthText = String(limitedDigits.prefix(2))
        let yearText = String(limitedDigits.dropFirst(2))
        
        return "\(monthText)/\(yearText)"
    }
}

#if DEBUG
struct ExpiryDateInputView_Previews: PreviewProvider {
    static var previews: some View {
        ExpiryDateInputView(expiryDateText: .constant("12/28"))
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif
