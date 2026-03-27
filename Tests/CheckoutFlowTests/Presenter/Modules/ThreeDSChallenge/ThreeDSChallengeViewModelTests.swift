import Foundation
import Testing

@testable import CheckoutFlow

struct ThreeDSChallengeViewModelTests { }

// MARK: - View state

extension ThreeDSChallengeViewModelTests {

    @MainActor
    @Test
    func init_buildsExpectedDefaultViewState() {
        // Given
        let requestURL = URL(string: "https://example.com/3ds")!

        let threeDSChallengeViewModel = ThreeDSChallengeViewModel(
            requestURL: requestURL
        )

        // Then
        #expect(
            threeDSChallengeViewModel.viewState == ThreeDSChallengeViewState(
                titleText: "3D Secure",
                requestURL: requestURL,
                isLoading: true,
                loadingText: "Loading authentication…",
                errorTitleText: "Authentication Error",
                errorMessage: nil,
                showsCloseButton: true,
                closeButtonTitle: "Close"
            )
        )
        #expect(threeDSChallengeViewModel.viewState.shouldShowLoadingOverlay)
        #expect(threeDSChallengeViewModel.viewState.shouldShowErrorView == false)
    }

    @MainActor
    @Test
    func didStartLoading_clearsPreviousError_andShowsLoading() {
        // Given
        let threeDSChallengeViewModel = ThreeDSChallengeViewModel(
            requestURL: URL(string: "https://example.com/3ds")!
        )
        threeDSChallengeViewModel.errorMessage = "Previous error"
        threeDSChallengeViewModel.isLoading = false

        // When
        threeDSChallengeViewModel.didStartLoading()

        // Then
        #expect(threeDSChallengeViewModel.isLoading)
        #expect(threeDSChallengeViewModel.errorMessage == nil)
    }

    @MainActor
    @Test
    func didFinishLoading_hidesLoading() {
        // Given
        let threeDSChallengeViewModel = ThreeDSChallengeViewModel(
            requestURL: URL(string: "https://example.com/3ds")!
        )

        // When
        threeDSChallengeViewModel.didFinishLoading()

        // Then
        #expect(threeDSChallengeViewModel.isLoading == false)
    }

    @MainActor
    @Test
    func didFailLoading_withNonCancelledError_showsError() {
        // Given
        let threeDSChallengeViewModel = ThreeDSChallengeViewModel(
            requestURL: URL(string: "https://example.com/3ds")!
        )

        // When
        threeDSChallengeViewModel.didFailLoading(with: URLError(.badServerResponse))

        // Then
        #expect(threeDSChallengeViewModel.isLoading == false)
        #expect(
            threeDSChallengeViewModel.errorMessage
                == "Unable to load the authentication page. Please try again."
        )
        #expect(threeDSChallengeViewModel.viewState.shouldShowErrorView)
    }

    @MainActor
    @Test
    func didFailLoading_withCancelledError_doesNothing() {
        // Given
        let threeDSChallengeViewModel = ThreeDSChallengeViewModel(
            requestURL: URL(string: "https://example.com/3ds")!
        )

        // When
        threeDSChallengeViewModel.didFailLoading(with: URLError(.cancelled))

        // Then
        #expect(threeDSChallengeViewModel.isLoading)
        #expect(threeDSChallengeViewModel.errorMessage == nil)
    }
}

// MARK: - Navigation actions

extension ThreeDSChallengeViewModelTests {

    @MainActor
    @Test
    func decideNavigationPolicy_whenActionIsAllow_returnsTrue_andDoesNotComplete() {
        // Given
        let completionSpy = ThreeDSCompletionSpy()

        let threeDSChallengeViewModel = ThreeDSChallengeViewModel(
            requestURL: URL(string: "https://example.com/3ds")!,
            navigationActionResolver: { _ in .allow },
            onCompletion: { completion in
                completionSpy.record(completion)
            }
        )

        // When
        let shouldAllowNavigation = threeDSChallengeViewModel.decideNavigationPolicy(
            for: URL(string: "https://example.com/next")!
        )

        // Then
        #expect(shouldAllowNavigation)
        #expect(completionSpy.recordedCompletions.isEmpty)
    }

    @MainActor
    @Test
    func decideNavigationPolicy_whenActionIsFinishSuccess_returnsFalse_andCompletesSuccess() {
        // Given
        let completionSpy = ThreeDSCompletionSpy()

        let threeDSChallengeViewModel = ThreeDSChallengeViewModel(
            requestURL: URL(string: "https://example.com/3ds")!,
            navigationActionResolver: { _ in .finishSuccess },
            onCompletion: { completion in
                completionSpy.record(completion)
            }
        )

        // When
        let shouldAllowNavigation = threeDSChallengeViewModel.decideNavigationPolicy(
            for: URL(string: "https://example.com/success")!
        )

        // Then
        #expect(shouldAllowNavigation == false)
        #expect(completionSpy.recordedCompletions == [.success])
    }

    @MainActor
    @Test
    func decideNavigationPolicy_whenActionIsFinishFailure_returnsFalse_andCompletesFailure() {
        // Given
        let completionSpy = ThreeDSCompletionSpy()

        let threeDSChallengeViewModel = ThreeDSChallengeViewModel(
            requestURL: URL(string: "https://example.com/3ds")!,
            navigationActionResolver: { _ in .finishFailure(message: "3DS failed") },
            onCompletion: { completion in
                completionSpy.record(completion)
            }
        )

        // When
        let shouldAllowNavigation = threeDSChallengeViewModel.decideNavigationPolicy(
            for: URL(string: "https://example.com/failure")!
        )

        // Then
        #expect(shouldAllowNavigation == false)
        #expect(completionSpy.recordedCompletions == [.failure(message: "3DS failed")])
    }

    @MainActor
    @Test
    func decideNavigationPolicy_whenActionIsFinishCancelled_returnsFalse_andCompletesCancelled() {
        // Given
        let completionSpy = ThreeDSCompletionSpy()

        let threeDSChallengeViewModel = ThreeDSChallengeViewModel(
            requestURL: URL(string: "https://example.com/3ds")!,
            navigationActionResolver: { _ in .finishCancelled },
            onCompletion: { completion in
                completionSpy.record(completion)
            }
        )

        // When
        let shouldAllowNavigation = threeDSChallengeViewModel.decideNavigationPolicy(
            for: URL(string: "https://example.com/cancelled")!
        )

        // Then
        #expect(shouldAllowNavigation == false)
        #expect(completionSpy.recordedCompletions == [.cancelled])
    }

    @MainActor
    @Test
    func didTapCloseButton_completesCancelled() {
        // Given
        let completionSpy = ThreeDSCompletionSpy()

        let threeDSChallengeViewModel = ThreeDSChallengeViewModel(
            requestURL: URL(string: "https://example.com/3ds")!,
            onCompletion: { completion in
                completionSpy.record(completion)
            }
        )

        // When
        threeDSChallengeViewModel.didTapCloseButton()

        // Then
        #expect(completionSpy.recordedCompletions == [.cancelled])
    }
}

// MARK: - Helpers

extension ThreeDSChallengeViewModelTests {

    final class ThreeDSCompletionSpy {
        private(set) var recordedCompletions: [ThreeDSChallengeViewModel.ThreeDSChallengeCompletion] = []

        func record(_ completion: ThreeDSChallengeViewModel.ThreeDSChallengeCompletion) {
            recordedCompletions.append(completion)
        }
    }
}
