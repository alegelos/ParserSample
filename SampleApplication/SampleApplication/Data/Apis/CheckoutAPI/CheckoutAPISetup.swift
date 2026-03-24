import Foundation

enum CheckoutAPISetup {
    case token(
        baseURL: URL,
        publicAPIKey: String,
        cardTokenizationRequest: CardTokenizationRequest
    )
    case payment(
        baseURL: URL,
        secretAPIKey: String,
        paymentRequest: PaymentRequest
    )
}

extension CheckoutAPISetup: ApiSetupProtocol {
    
    var request: URLRequest {
        get throws {
            let requestBaseURL: URL
            
            switch self {
            case let .token(baseURL, _, _),
                 let .payment(baseURL, _, _):
                requestBaseURL = baseURL
            }
            
            let fullURL = requestBaseURL.appendingPathComponent(path)
            
            guard var urlComponents = URLComponents(
                url: fullURL,
                resolvingAgainstBaseURL: false
            ) else {
                throw ApiErrors.invalidUrl
            }
            
            urlComponents.queryItems = queryItems.isEmpty ? nil : queryItems
            
            guard let resolvedURL = urlComponents.url else {
                throw ApiErrors.invalidUrl
            }
            
            var urlRequest = URLRequest(url: resolvedURL)
            urlRequest.httpMethod = method.rawValue
            
            for (field, value) in try headers {
                urlRequest.setValue(value, forHTTPHeaderField: field)
            }
            
            urlRequest.httpBody = body
            
            return urlRequest
        }
    }
    
    var path: String {
        switch self {
        case .token:
            return "tokens"
        case .payment:
            return "payments"
        }
    }
    
    var method: HttpMethod {
        switch self {
        case .token, .payment:
            return .post
        }
    }
    
    var headers: [String: String] {
        get throws {
            let apiKey: String
            
            switch self {
            case let .token(_, publicAPIKey, _):
                apiKey = publicAPIKey
            case let .payment(_, secretAPIKey, _):
                apiKey = secretAPIKey
            }
            
            return [
                "Authorization": "Bearer \(apiKey)",
                "Accept": "application/json",
                "Content-Type": "application/json"
            ]
        }
    }
    
    var body: Data? {
        let jsonEncoder = JSONEncoder()
        
        switch self {
        case let .token(_, _, cardTokenizationRequest):
            let requestBody = RequestTokenBody(
                type: "card",
                number: cardTokenizationRequest.number,
                expiryMonth: cardTokenizationRequest.expiryMonth,
                expiryYear: cardTokenizationRequest.expiryYear,
                cvv: cardTokenizationRequest.cvv
            )
            
            return try? jsonEncoder.encode(requestBody)
            
        case let .payment(_, _, paymentRequest):
            let requestBody = RequestPaymentBody(
                source: Source(
                    type: "token",
                    token: paymentRequest.cardToken
                ),
                amount: paymentRequest.amount,
                currency: paymentRequest.currency,
                threeDS: ThreeDS(
                    enabled: paymentRequest.isThreeDSecureEnabled
                ),
                successURL: paymentRequest.successURL.absoluteString,
                failureURL: paymentRequest.failureURL.absoluteString
            )
            
            return try? jsonEncoder.encode(requestBody)
        }
    }
    
    var queryItems: [URLQueryItem] {
        []
    }
    
}

// MARK: - Request Bodies

private extension CheckoutAPISetup {
    
    struct RequestTokenBody: Encodable {
        let type: String
        let number: String
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
    
    struct RequestPaymentBody: Encodable {
        let source: Source
        let amount: Int
        let currency: String
        let threeDS: ThreeDS
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
    
    struct Source: Encodable {
        let type: String
        let token: String
    }
    
    struct ThreeDS: Encodable {
        let enabled: Bool
    }
    
}
