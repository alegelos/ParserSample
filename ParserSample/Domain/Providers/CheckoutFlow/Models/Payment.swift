import Foundation

struct Payment: Equatable {
    
    let status: Status
    let redirectURL: URL?
    
}

extension Payment {
    
    enum Status: String, Equatable {
        case pending = "Pending"
        case authorized = "Authorized"
        case cardVerified = "Card Verified"
        case captured = "Captured"
        case declined = "Declined"
        case paid = "Paid"
    }
    
}
