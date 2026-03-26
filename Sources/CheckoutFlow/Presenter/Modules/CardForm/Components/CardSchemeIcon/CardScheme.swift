import Foundation

struct CardScheme: Equatable {
    let displayName: String
    let systemImageName: String
}

enum CardSchemeMapper {
    
    static func makePresentation(from schemeName: String?) -> CardScheme {
        let normalizedSchemeName = normalizeCardSchemeName(from: schemeName)
        
        switch normalizedSchemeName {
        case "visa":
            return CardScheme(
                displayName: "Visa",
                systemImageName: "v.circle"
            )
            
        case "mastercard":
            return CardScheme(
                displayName: "Mastercard",
                systemImageName: "c.circle"
            )
            
        case "amex", "american express":
            return CardScheme(
                displayName: "Amex",
                systemImageName: "a.circle"
            )
            
        case "discover":
            return CardScheme(
                displayName: "Discover",
                systemImageName: "d.circle"
            )
            
        case "maestro":
            return CardScheme(
                displayName: "Maestro",
                systemImageName: "m.circle"
            )
            
        default:
            return CardScheme(
                displayName: fallbackDisplayName(from: schemeName),
                systemImageName: "creditcard"
            )
        }
    }
    
    private static func normalizeCardSchemeName(from schemeName: String?) -> String {
        schemeName?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() ?? ""
    }
    
    private static func fallbackDisplayName(from schemeName: String?) -> String {
        guard let schemeName,
              schemeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            return "Card"
        }
        
        return schemeName
    }
}
