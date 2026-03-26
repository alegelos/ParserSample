import Foundation

enum CheckoutThreeDSChallengeCompletion: Equatable {
    case success
    case failure(message: String?)
    case cancelled
}

enum CheckoutThreeDSChallengeNavigationAction: Equatable {
    case allow
    case finishSuccess
    case finishFailure(message: String?)
    case finishCancelled
}

struct CheckoutThreeDSChallengeViewState: Equatable {
    
    let titleText: String
    let requestURL: URL
    let isLoading: Bool
    let errorMessage: String?
    let showsCloseButton: Bool
}
