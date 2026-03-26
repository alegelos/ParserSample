import Foundation
import Observation

@MainActor
@Observable
final class ThreeDSChallengeViewModel {
    
    let requestURL: URL
    let titleText: String
    let showsCloseButton: Bool
    let loadingText: String
    let errorTitleText: String
    let closeButtonTitle: String
    
    var isLoading: Bool
    var errorMessage: String?
    
    var viewState: ThreeDSChallengeViewState {
        ThreeDSChallengeViewState(
            titleText: titleText,
            requestURL: requestURL,
            isLoading: isLoading,
            loadingText: loadingText,
            errorTitleText: errorTitleText,
            errorMessage: errorMessage,
            showsCloseButton: showsCloseButton,
            closeButtonTitle: closeButtonTitle
        )
    }
    
    @ObservationIgnored
    private let navigationActionResolver: (URL) -> ThreeDSChallengeNavigationAction
    
    @ObservationIgnored
    private let onCompletion: ((ThreeDSChallengeCompletion) -> Void)?
    
    init(
        requestURL: URL,
        titleText: String = "3D Secure",
        showsCloseButton: Bool = true,
        loadingText: String = "Loading authentication…",
        errorTitleText: String = "Authentication Error",
        closeButtonTitle: String = "Close",
        navigationActionResolver: @escaping (URL) -> ThreeDSChallengeNavigationAction = { _ in .allow },
        onCompletion: ((ThreeDSChallengeCompletion) -> Void)? = nil
    ) {
        self.requestURL = requestURL
        self.titleText = titleText
        self.showsCloseButton = showsCloseButton
        self.loadingText = loadingText
        self.errorTitleText = errorTitleText
        self.closeButtonTitle = closeButtonTitle
        self.isLoading = true
        self.errorMessage = nil
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
        
        if nsError.domain == NSURLErrorDomain,
           nsError.code == NSURLErrorCancelled {
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

// MARK: - Helping Structures

extension ThreeDSChallengeViewModel {
    
    enum ThreeDSChallengeCompletion: Equatable {
        case success
        case failure(message: String?)
        case cancelled
    }

    enum ThreeDSChallengeNavigationAction: Equatable {
        case allow
        case finishSuccess
        case finishFailure(message: String?)
        case finishCancelled
    }
    
}
