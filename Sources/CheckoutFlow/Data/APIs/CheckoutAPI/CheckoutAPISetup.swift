import Foundation
import iOSCleanNetwork

enum CheckoutAPISetup {
    case token(
        baseURL: URL,
        publicAPIKey: String,
        tokenizeCardRequest: TokenizeCardRequestDTO
    )
    case payment(
        baseURL: URL,
        secretAPIKey: String,
        paymentRequest: PaymentRequestDTO
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
        case let .token(_, _, tokenizeCardRequest):
            return try? jsonEncoder.encode(tokenizeCardRequest)
            
        case let .payment(_, _, paymentRequest):
            return try? jsonEncoder.encode(paymentRequest)
        }
    }
    
    var queryItems: [URLQueryItem] {
        []
    }
    
}
