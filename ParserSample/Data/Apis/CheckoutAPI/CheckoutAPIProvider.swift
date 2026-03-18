import Foundation

final class CheckoutAPIProvider: ApiProvider, CheckoutFlowProtocol {
    
    let baseURL: URL
    let session: NetworkSessionProtocol
    
    private let publicAPIKey: String
    private let secretAPIKey: String
    private let jsonDecoder: JSONDecoder
    
    init(
        baseURL: URL,
        publicAPIKey: String,
        secretAPIKey: String,
        session: NetworkSessionProtocol = URLSession.shared,
        jsonDecoder: JSONDecoder = JSONDecoder()
    ) {
        self.baseURL = baseURL
        self.publicAPIKey = publicAPIKey
        self.secretAPIKey = secretAPIKey
        self.session = session
        self.jsonDecoder = jsonDecoder
    }
    
    func tokenizeCard(_ cardTokenizationRequest: CardTokenizationRequest) async throws -> CardToken {
        let endpoint = CheckoutAPISetup.token(
            baseURL: baseURL,
            publicAPIKey: publicAPIKey,
            cardTokenizationRequest: cardTokenizationRequest
        )
        
        let (responseData, _) = try await session.data(for: endpoint)
        
        do {
            let requestTokenResponse = try jsonDecoder.decode(
                CheckoutAPIRequestTokenResponse.self,
                from: responseData
            )
            
            return requestTokenResponse.domain
        } catch {
            throw ApiErrors.decodeError
        }
    }
    
    func requestPayment(_ paymentRequest: PaymentRequest) async throws -> Payment {
        let endpoint = CheckoutAPISetup.payment(
            baseURL: baseURL,
            secretAPIKey: secretAPIKey,
            paymentRequest: paymentRequest
        )
        
        let (responseData, _) = try await session.data(for: endpoint)
        
        do {
            let requestPaymentResponse = try jsonDecoder.decode(
                CheckoutAPIRequestPaymentResponse.self,
                from: responseData
            )
            
            return try requestPaymentResponse.domain
        } catch let apiError as ApiErrors {
            throw apiError
        } catch {
            throw ApiErrors.decodeError
        }
    }
    
}
