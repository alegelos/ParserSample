import Foundation

enum CheckoutFlowStep: Equatable {
    case cardForm
    case threeDSChallenge
    case paymentResult
}

struct CheckoutFlowViewState: Equatable {
    
    let currentStep: CheckoutFlowStep
    
    var isShowingCardForm: Bool {
        currentStep == .cardForm
    }
    
    var isShowingThreeDSChallenge: Bool {
        currentStep == .threeDSChallenge
    }
    
    var isShowingPaymentResult: Bool {
        currentStep == .paymentResult
    }
}
