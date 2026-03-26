import SwiftUI

struct CardSchemeIconView: View {
    
    let schemeName: String?
    
    private var cardScheme: CardScheme {
        CardSchemeMapper.makePresentation(from: schemeName)
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: cardScheme.systemImageName)
                .font(.system(size: 16, weight: .semibold))
            
            Text(cardScheme.displayName)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color(.secondarySystemBackground))
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Detected card scheme \(cardScheme.displayName)")
    }
}

#if DEBUG
struct CardSchemeIconView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
            CardSchemeIconView(schemeName: "visa")
            CardSchemeIconView(schemeName: "mastercard")
            CardSchemeIconView(schemeName: "amex")
            CardSchemeIconView(schemeName: nil)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
