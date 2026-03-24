import Foundation

extension CheckoutAPISetup {
    
    struct PaymentRequestDTO: Encodable {
        
        let source: SourceDTO
        let amount: Int
        let currency: String
        let threeDS: ThreeDSDTO
        let successURL: String
        let failureURL: String
        
        enum CodingKeys: String, CodingKey {
            case source
            case amount
            case currency
            case threeDS = "3ds"
            case successURL = "success_url"
            case failureURL = "failure_url"
        }

    }
    
    struct SourceDTO: Encodable {
        let type: String
        let token: String
    }
    
    struct ThreeDSDTO: Encodable {
        let enabled: Bool
    }
    
}

// MARK: - Helping Structures

extension CheckoutAPISetup.PaymentRequestDTO {
    
    init(domain: CardPayment) {
        self.init(
            source: CheckoutAPISetup.SourceDTO(
                type: "token",
                token: domain.paymentToken.value
            ),
            amount: domain.amountInMinorUnits,
            currency: domain.currencyCode,
            threeDS: CheckoutAPISetup.ThreeDSDTO(enabled: true),
            successURL: domain.successURL.absoluteString,
            failureURL: domain.failureURL.absoluteString
        )
    }
    
}
