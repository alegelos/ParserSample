import Foundation
import iOSCleanNetwork

final class CheckoutAPIProvider: PaymentFlowProviderProtocol {
    
    private let baseURL: URL
    private let publicAPIKey: String
    private let secretAPIKey: String
    private let session: any NetworkSessionProtocol
    private let jsonDecoder: JSONDecoder
    
    init(
        baseURL: URL,
        publicAPIKey: String,
        secretAPIKey: String,
        session: any NetworkSessionProtocol,
        jsonDecoder: JSONDecoder = JSONDecoder()
    ) {
        self.baseURL = baseURL
        self.publicAPIKey = publicAPIKey
        self.secretAPIKey = secretAPIKey
        self.session = session
        self.jsonDecoder = jsonDecoder
    }
    
    func tokenizeCard(_ cardDetails: CardDetails) async throws -> PaymentToken {
        let requestDTO = CheckoutAPISetup.TokenizeCardRequestDTO(domain: cardDetails)
        
        let apiEndpointSetup = CheckoutAPISetup.token(
            baseURL: baseURL,
            publicAPIKey: publicAPIKey,
            tokenizeCardRequest: requestDTO
        )
        
        let (responseData, _) = try await session.data(for: apiEndpointSetup)
        let responseDTO = try jsonDecoder.decode(
            CheckoutAPISetup.TokenizeCardResponseDTO.self,
            from: responseData
        )
        
        return responseDTO.domain
    }
    
    func createPayment(_ cardPayment: CardPayment) async throws -> ThreeDSPaymentSession {
        let requestDTO = CheckoutAPISetup.PaymentRequestDTO(domain: cardPayment)
        
        let apiEndpointSetup = CheckoutAPISetup.payment(
            baseURL: baseURL,
            secretAPIKey: secretAPIKey,
            paymentRequest: requestDTO
        )
        
        let (responseData, _) = try await session.data(for: apiEndpointSetup)
        let responseDTO = try jsonDecoder.decode(
            CheckoutAPISetup.PaymentResponseDTO.self,
            from: responseData
        )
        
        return try responseDTO.domain
    }
    
}
