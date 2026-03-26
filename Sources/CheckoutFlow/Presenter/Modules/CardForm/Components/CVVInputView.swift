import SwiftUI

struct CVVInputView: View {
    
    @Binding var cvvText: String
    
    let placeholderText: String
    let maximumLength: Int
    
    init(
        cvvText: Binding<String>,
        placeholderText: String = "CVV",
        maximumLength: Int = 4
    ) {
        self._cvvText = cvvText
        self.placeholderText = placeholderText
        self.maximumLength = maximumLength
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Security Code")
                .font(.footnote)
                .fontWeight(.semibold)
            
            SecureField(placeholderText, text: $cvvText)
                .keyboardType(.numberPad)
                .textContentType(.creditCardSecurityCode)
                .onChange(of: cvvText) { newValue in
                    cvvText = sanitizeCVV(from: newValue)
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
    
    private func sanitizeCVV(from rawValue: String) -> String {
        let onlyDigits = rawValue.filter(\.isNumber)
        return String(onlyDigits.prefix(maximumLength))
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
