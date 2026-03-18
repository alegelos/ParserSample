import Foundation

struct CheckoutAPIRequestTokenResponse: Decodable, Equatable {
    
    let type: String
    let token: String
    
}

// MARK: - Domain Mapper

extension CheckoutAPIRequestTokenResponse {
    
    var domain: CardToken {
        CardToken(token: token)
    }
    
}
