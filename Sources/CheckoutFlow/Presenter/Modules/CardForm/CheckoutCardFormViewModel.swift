import Foundation
import Observation

@MainActor
@Observable
final class CheckoutCardFormViewModel {
    
    var cardNumberText: String = "" {
        didSet {
            detectedSchemeName = detectCardSchemeName(from: cardNumberText)
            clearErrorMessage()
        }
    }
    
    var expiryDateText: String = "" {
        didSet {
            clearErrorMessage()
        }
    }
    
    var cvvText: String = "" {
        didSet {
            clearErrorMessage()
        }
    }
    
    var detectedSchemeName: String?
    var errorMessage: String?
    var isLoading: Bool = false
    
    let payButtonTitle: String
    
    var isPayButtonEnabled: Bool {
        let hasCardNumber = sanitizedCardNumber.count >= 12
        let hasValidExpiryLength = sanitizedExpiryDate.count == 4
        let hasValidSecurityCodeLength = sanitizedSecurityCode.count >= 3
        
        return hasCardNumber
            && hasValidExpiryLength
            && hasValidSecurityCodeLength
            && !isLoading
    }
    
    var viewState: CheckoutCardFormViewState {
        CheckoutCardFormViewState(
            cardNumberText: cardNumberText,
            expiryDateText: expiryDateText,
            cvvText: cvvText,
            detectedSchemeName: detectedSchemeName,
            errorMessage: errorMessage,
            isLoading: isLoading,
            isPayButtonEnabled: isPayButtonEnabled,
            payButtonTitle: payButtonTitle
        )
    }
    
    @ObservationIgnored
    private let paymentFlowProvider: any PaymentFlowProviderProtocol
    
    @ObservationIgnored
    private let onCardTokenized: ((PaymentToken) -> Void)?
    
    @ObservationIgnored
    private let mapSubmitErrorMessage: ((Error) -> String)?
    
    init(
        payButtonTitle: String = "Pay",
        paymentFlowProvider: any PaymentFlowProviderProtocol,
        onCardTokenized: ((PaymentToken) -> Void)? = nil,
        mapSubmitErrorMessage: ((Error) -> String)? = nil
    ) {
        self.payButtonTitle = payButtonTitle
        self.paymentFlowProvider = paymentFlowProvider
        self.onCardTokenized = onCardTokenized
        self.mapSubmitErrorMessage = mapSubmitErrorMessage
    }
    
    func submit() async {
        guard !isLoading else {
            return
        }
        
        guard let cardDetails = buildCardDetails() else {
            errorMessage = validateForm()
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let paymentToken = try await paymentFlowProvider.tokenizeCard(cardDetails)
            isLoading = false
            onCardTokenized?(paymentToken)
        } catch {
            isLoading = false
            errorMessage = mapSubmitErrorMessage?(error) ?? "Unable to process the payment. Please try again."
        }
    }
    
    private func clearErrorMessage() {
        if errorMessage != nil {
            errorMessage = nil
        }
    }
    
    private func validateForm() -> String? {
        if sanitizedCardNumber.isEmpty {
            return "Enter the card number."
        }
        
        if sanitizedCardNumber.count < 12 {
            return "Enter a valid card number."
        }
        
        if sanitizedExpiryDate.count != 4 {
            return "Enter a valid expiry date."
        }
        
        let expirationMonthText = String(sanitizedExpiryDate.prefix(2))
        guard let expirationMonthNumber = Int(expirationMonthText),
              (1...12).contains(expirationMonthNumber) else {
            return "Enter a valid expiry month."
        }
        
        if sanitizedSecurityCode.count < 3 {
            return "Enter a valid security code."
        }
        
        return nil
    }
    
    private func buildCardDetails() -> CardDetails? {
        guard validateForm() == nil else {
            return nil
        }
        
        let expirationMonth = String(sanitizedExpiryDate.prefix(2))
        let expirationYear = String(sanitizedExpiryDate.suffix(2))
        
        return CardDetails(
            cardNumber: sanitizedCardNumber,
            expirationMonth: expirationMonth,
            expirationYear: expirationYear,
            securityCode: sanitizedSecurityCode
        )
    }
    
    private var sanitizedCardNumber: String {
        cardNumberText.filter(\.isNumber)
    }
    
    private var sanitizedExpiryDate: String {
        expiryDateText.filter(\.isNumber)
    }
    
    private var sanitizedSecurityCode: String {
        cvvText.filter(\.isNumber)
    }
    
    private func detectCardSchemeName(from cardNumberText: String) -> String? {
        let sanitizedCardNumber = cardNumberText.filter(\.isNumber)
        
        guard !sanitizedCardNumber.isEmpty else {
            return nil
        }
        
        if sanitizedCardNumber.hasPrefix("4") {
            return "visa"
        }
        
        if let firstTwoDigits = Int(String(sanitizedCardNumber.prefix(2))),
           (51...55).contains(firstTwoDigits) {
            return "mastercard"
        }
        
        if let firstFourDigits = Int(String(sanitizedCardNumber.prefix(4))),
           (2221...2720).contains(firstFourDigits) {
            return "mastercard"
        }
        
        if sanitizedCardNumber.hasPrefix("34") || sanitizedCardNumber.hasPrefix("37") {
            return "amex"
        }
        
        if sanitizedCardNumber.hasPrefix("6") {
            return "discover"
        }
        
        return nil
    }
}
