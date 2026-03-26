import Foundation

struct ThreeDSChallengeViewState: Equatable {
    
    let titleText: String
    let requestURL: URL
    let isLoading: Bool
    let loadingText: String
    let errorTitleText: String
    let errorMessage: String?
    let showsCloseButton: Bool
    let closeButtonTitle: String
    
    var shouldShowLoadingOverlay: Bool {
        isLoading
    }
    
    var shouldShowErrorView: Bool {
        errorMessage != nil
    }
}
