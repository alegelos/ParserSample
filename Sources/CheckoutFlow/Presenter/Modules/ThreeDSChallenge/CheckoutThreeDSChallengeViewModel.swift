import Foundation
import Observation

@MainActor
@Observable
final class CheckoutThreeDSChallengeViewModel {
    
    let titleText: String
    let requestURL: URL
    let showsCloseButton: Bool
    
    var isLoading: Bool = true
    var errorMessage: String?
    
    var viewState: CheckoutThreeDSChallengeViewState {
        CheckoutThreeDSChallengeViewState(
            titleText: titleText,
            requestURL: requestURL,
            isLoading: isLoading,
            errorMessage: errorMessage,
            showsCloseButton: showsCloseButton
        )
    }
    
    @ObservationIgnored
    private let navigationActionResolver: (URL) -> CheckoutThreeDSChallengeNavigationAction
    
    @ObservationIgnored
    private let onCompletion: ((CheckoutThreeDSChallengeCompletion) -> Void)?
    
    init(
        requestURL: URL,
        titleText: String = "3D Secure",
        showsCloseButton: Bool = true,
        navigationActionResolver: @escaping (URL) -> CheckoutThreeDSChallengeNavigationAction = { _ in .allow },
        onCompletion: ((CheckoutThreeDSChallengeCompletion) -> Void)? = nil
    ) {
        self.requestURL = requestURL
        self.titleText = titleText
        self.showsCloseButton = showsCloseButton
        self.navigationActionResolver = navigationActionResolver
        self.onCompletion = onCompletion
    }
    
    func didStartLoading() {
        isLoading = true
        errorMessage = nil
    }
    
    func didFinishLoading() {
        isLoading = false
    }
    
    func didFailLoading(with error: Error) {
        let nsError = error as NSError
        
        if nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorCancelled {
            return
        }
        
        isLoading = false
        errorMessage = "Unable to load the authentication page. Please try again."
    }
    
    func decideNavigationPolicy(for url: URL) -> Bool {
        switch navigationActionResolver(url) {
        case .allow:
            return true
            
        case .finishSuccess:
            onCompletion?(.success)
            return false
            
        case .finishFailure(let message):
            onCompletion?(.failure(message: message))
            return false
            
        case .finishCancelled:
            onCompletion?(.cancelled)
            return false
        }
    }
    
    func didTapCloseButton() {
        onCompletion?(.cancelled)
    }
}
