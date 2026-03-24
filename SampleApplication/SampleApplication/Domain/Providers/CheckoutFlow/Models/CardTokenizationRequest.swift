import Foundation

struct CardTokenizationRequest: Equatable {
    
    let number: String
    let expiryMonth: String
    let expiryYear: String
    let cvv: String
    
}
