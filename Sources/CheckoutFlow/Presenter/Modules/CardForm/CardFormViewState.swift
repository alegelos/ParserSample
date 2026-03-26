import Foundation

struct CardFormViewState: Equatable {
    
    let cardNumberText: String
    let expiryDateText: String
    let cvvText: String
    let detectedSchemeName: String?
    let errorMessage: String?
    let isLoading: Bool
    let isPayButtonEnabled: Bool
    let payButtonTitle: String
    
}
