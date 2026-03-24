import Foundation

extension CheckoutAPISetup {
    
    struct TokenizeCardRequestDTO: Encodable {
        
        let type: String
        let number: String//todo ale: investigate the type that is here, maybe it tell us how to cast it
        let expiryMonth: String
        let expiryYear: String
        let cvv: String
        
        enum CodingKeys: String, CodingKey {
            case type
            case number
            case expiryMonth = "expiry_month"
            case expiryYear = "expiry_year"
            case cvv
        }
        
    }
    
}

// MARK: - Helping Structures

extension CheckoutAPISetup.TokenizeCardRequestDTO {
    
    init(domain: CardDetails) {
        self.init(
            type: "card",
            number: domain.cardNumber,
            expiryMonth: domain.expirationMonth,
            expiryYear: domain.expirationYear,
            cvv: domain.securityCode
        )
    }
    
}
