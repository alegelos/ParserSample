import SwiftUI

struct CardSchemeIconView: View {
    
    let schemeName: String?
    
    private var normalizedSchemeName: String {
        schemeName?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() ?? ""
    }
    
    private var displayName: String {
        switch normalizedSchemeName {
        case "visa":
            return "Visa"
        case "mastercard":
            return "Mastercard"
        case "amex", "american express":
            return "Amex"
        case "discover":
            return "Discover"
        case "maestro":
            return "Maestro"
        default:
            return schemeName?.isEmpty == false ? schemeName! : "Card"
        }
    }
    
    private var systemImageName: String {
        switch normalizedSchemeName {
        case "visa":
            return "v.circle"
        case "mastercard":
            return "c.circle"
        case "amex", "american express":
            return "a.circle"
        case "discover":
            return "d.circle"
        case "maestro":
            return "m.circle"
        default:
            return "creditcard"
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImageName)
                .font(.system(size: 16, weight: .semibold))
            
            Text(displayName)
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
        .accessibilityLabel("Detected card scheme \(displayName)")
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
