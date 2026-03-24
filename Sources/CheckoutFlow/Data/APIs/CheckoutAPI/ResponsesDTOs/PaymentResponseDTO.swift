import Foundation

extension CheckoutAPISetup {
    
    struct PaymentResponseDTO: Decodable {
        
        let status: String
        let links: Links
        
        enum CodingKeys: String, CodingKey {
            case status
            case links = "_links"
        }
        
        struct Links: Decodable {
            let redirect: Redirect
        }
        
        struct Redirect: Decodable {
            let href: String
        }
        
    }
    
}

 // MARK: - Domain Mapper

extension CheckoutAPISetup.PaymentResponseDTO {
    
    enum MappingError: Error, Equatable {
        case invalidRedirectURL(String)
    }
    
    var domain: ThreeDSPaymentSession {
        get throws {
            guard let redirectURL = URL(string: links.redirect.href) else {
                throw CheckoutAPISetup.PaymentResponseDTO.MappingError.invalidRedirectURL(links.redirect.href)
            }
            
            return ThreeDSPaymentSession(
                status: .init(rawValue: status),
                redirectURL: redirectURL
            )
        }
    }
    
}

// MARK: - Helping Structures

private extension PaymentStatus {
    
    init(rawValue: String) {
        switch rawValue.lowercased() {
        case "pending":
            self = .pending
        default:
            self = .unknown(rawValue)
        }
    }
    
}
