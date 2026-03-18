import Foundation

protocol CheckoutFlowProtocol {
    
    func tokenizeCard(_ cardTokenizationRequest: CardTokenizationRequest) async throws -> CardToken
    
    func requestPayment(_ paymentRequest: PaymentRequest) async throws -> Payment
    
}
