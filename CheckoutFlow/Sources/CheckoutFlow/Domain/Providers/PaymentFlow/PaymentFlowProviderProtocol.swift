import Foundation

protocol PaymentFlowProviderProtocol: Sendable {
    
    func tokenizeCard(_ cardDetails: CardDetails) async throws -> PaymentToken
    
    func createPayment(_ cardPayment: CardPayment) async throws -> ThreeDSPaymentSession
    
}
