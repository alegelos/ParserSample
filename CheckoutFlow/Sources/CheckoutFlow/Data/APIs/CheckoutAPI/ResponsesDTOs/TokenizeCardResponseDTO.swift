import Foundation

extension CheckoutAPISetup {
    
    struct TokenizeCardResponseDTO: Decodable {
        
        let token: String
        
    }
    
}
    
// MARK: - Domain Mapper
    
extension CheckoutAPISetup.TokenizeCardResponseDTO {
        
    var domain: PaymentToken {
        PaymentToken(value: token)
    }

}
