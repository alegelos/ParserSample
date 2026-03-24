import Foundation

struct CheckoutAPIRequestPaymentResponse: Decodable, Equatable {
    
    let status: String
    let links: Links?
    
    enum CodingKeys: String, CodingKey {
        case status
        case links = "_links"
    }
    
}

// MARK: - Helping Structures

extension CheckoutAPIRequestPaymentResponse {
    
    struct Links: Decodable, Equatable {
        let redirect: Redirect?
    }
    
    struct Redirect: Decodable, Equatable {
        let href: String
    }
    
}

// MARK: - Domain Mapper

extension CheckoutAPIRequestPaymentResponse {
    
    var domain: Payment {
        get throws {
            guard let paymentStatus = Payment.Status(rawValue: status) else {
                throw ApiErrors.domainMappingError
            }
            
            let redirectURL: URL?
            
            if let redirectHref = links?.redirect?.href {
                guard let parsedRedirectURL = URL(string: redirectHref) else {
                    throw ApiErrors.domainMappingError
                }
                
                redirectURL = parsedRedirectURL
            } else {
                redirectURL = nil
            }
            
            return Payment(
                status: paymentStatus,
                redirectURL: redirectURL
            )
        }
    }
    
}
