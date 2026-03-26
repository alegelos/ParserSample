import SwiftUI

struct CardFormErrorView: View {
    
    let message: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.red)
            
            Text(message)
                .font(.footnote)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.18), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(message)")
    }
}

#if DEBUG
struct CardFormErrorView_Previews: PreviewProvider {
    static var previews: some View {
        CardFormErrorView(message: "The card number is invalid.")
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif
