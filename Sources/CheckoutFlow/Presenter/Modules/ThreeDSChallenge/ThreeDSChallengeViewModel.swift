import Foundation
import WebKit

@MainActor
final class ThreeDSChallengeViewModel: ObservableObject {
    
    let requestURL: URL
    let titleText: String
    let showsCloseButton: Bool
    let loadingText: String
    let errorTitleText: String
    let closeButtonTitle: String
    
    @Published var isLoading: Bool
    @Published var errorMessage: String?
    
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
    
    private let navigationActionResolver: (URL) -> ThreeDSChallengeNavigationAction
    private let onCompletion: ((ThreeDSChallengeCompletion) -> Void)?
    
    init(
        requestURL: URL,
        titleText: String = CheckoutFlowLocalized.string("checkout.three_ds.title"),
        showsCloseButton: Bool = true,
        loadingText: String = CheckoutFlowLocalized.string("checkout.three_ds.loading_message"),
        errorTitleText: String = CheckoutFlowLocalized.string("checkout.three_ds.error.title"),
        closeButtonTitle: String = CheckoutFlowLocalized.string("checkout.three_ds.close_button"),
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
        
        if shouldIgnoreWebViewError(nsError) {
            return
        }
        
        isLoading = false
        errorMessage = CheckoutFlowLocalized.string("checkout.three_ds.error.message")
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

// MARK: - Private

extension ThreeDSChallengeViewModel {

    private func shouldIgnoreWebViewError(_ error: NSError) -> Bool {
        if error.domain == NSURLErrorDomain,
           error.code == NSURLErrorCancelled {
            return true
        }

        if error.domain == WebViewErrorConstants.webKitErrorDomain,
               error.code == WebViewErrorConstants.frameLoadInterruptedByPolicyChangeErrorCode {
                return true
        }

        return false
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
    
    enum WebViewErrorConstants {
        static let webKitErrorDomain = "WebKitErrorDomain"
        static let frameLoadInterruptedByPolicyChangeErrorCode = 102
    }
    
}
