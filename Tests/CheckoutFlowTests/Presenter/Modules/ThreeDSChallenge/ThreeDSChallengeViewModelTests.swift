import Foundation
import XCTest

@testable import CheckoutFlow

final class ThreeDSChallengeViewModelTests: XCTestCase {

    @MainActor
    func test_init_buildsExpectedDefaultViewState() {
        // Given
        let requestURL = URL(string: "https://example.com/3ds")!

        let threeDSChallengeViewModel = ThreeDSChallengeViewModel(
            requestURL: requestURL
        )

        // Then
        XCTAssertEqual(
            threeDSChallengeViewModel.viewState,
            ThreeDSChallengeViewState(
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
        XCTAssertTrue(threeDSChallengeViewModel.viewState.shouldShowLoadingOverlay)
        XCTAssertFalse(threeDSChallengeViewModel.viewState.shouldShowErrorView)
    }

    @MainActor
    func test_didStartLoading_clearsPreviousError_andShowsLoading() {
        // Given
        let threeDSChallengeViewModel = ThreeDSChallengeViewModel(
            requestURL: URL(string: "https://example.com/3ds")!
        )
        threeDSChallengeViewModel.errorMessage = "Previous error"
        threeDSChallengeViewModel.isLoading = false

        // When
        threeDSChallengeViewModel.didStartLoading()

        // Then
        XCTAssertTrue(threeDSChallengeViewModel.isLoading)
        XCTAssertNil(threeDSChallengeViewModel.errorMessage)
    }

    @MainActor
    func test_didFinishLoading_hidesLoading() {
        // Given
        let threeDSChallengeViewModel = ThreeDSChallengeViewModel(
            requestURL: URL(string: "https://example.com/3ds")!
        )

        // When
        threeDSChallengeViewModel.didFinishLoading()

        // Then
        XCTAssertFalse(threeDSChallengeViewModel.isLoading)
    }

    @MainActor
    func test_didFailLoading_withNonCancelledError_showsError() {
        // Given
        let threeDSChallengeViewModel = ThreeDSChallengeViewModel(
            requestURL: URL(string: "https://example.com/3ds")!
        )

        // When
        threeDSChallengeViewModel.didFailLoading(with: URLError(.badServerResponse))

        // Then
        XCTAssertFalse(threeDSChallengeViewModel.isLoading)
        XCTAssertEqual(
            threeDSChallengeViewModel.errorMessage,
            "Unable to load the authentication page. Please try again."
        )
        XCTAssertTrue(threeDSChallengeViewModel.viewState.shouldShowErrorView)
    }

    @MainActor
    func test_didFailLoading_withCancelledError_doesNothing() {
        // Given
        let threeDSChallengeViewModel = ThreeDSChallengeViewModel(
            requestURL: URL(string: "https://example.com/3ds")!
        )

        // When
        threeDSChallengeViewModel.didFailLoading(with: URLError(.cancelled))

        // Then
        XCTAssertTrue(threeDSChallengeViewModel.isLoading)
        XCTAssertNil(threeDSChallengeViewModel.errorMessage)
    }

    @MainActor
    func test_decideNavigationPolicy_whenActionIsAllow_returnsTrue_andDoesNotComplete() {
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
        XCTAssertTrue(shouldAllowNavigation)
        XCTAssertTrue(completionSpy.recordedCompletions.isEmpty)
    }

    @MainActor
    func test_decideNavigationPolicy_whenActionIsFinishSuccess_returnsFalse_andCompletesSuccess() {
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
        XCTAssertFalse(shouldAllowNavigation)
        XCTAssertEqual(completionSpy.recordedCompletions, [.success])
    }

    @MainActor
    func test_decideNavigationPolicy_whenActionIsFinishFailure_returnsFalse_andCompletesFailure() {
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
        XCTAssertFalse(shouldAllowNavigation)
        XCTAssertEqual(completionSpy.recordedCompletions, [.failure(message: "3DS failed")])
    }

    @MainActor
    func test_decideNavigationPolicy_whenActionIsFinishCancelled_returnsFalse_andCompletesCancelled() {
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
        XCTAssertFalse(shouldAllowNavigation)
        XCTAssertEqual(completionSpy.recordedCompletions, [.cancelled])
    }

    @MainActor
    func test_didTapCloseButton_completesCancelled() {
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
        XCTAssertEqual(completionSpy.recordedCompletions, [.cancelled])
    }
}

extension ThreeDSChallengeViewModelTests {

    final class ThreeDSCompletionSpy {
        private(set) var recordedCompletions: [ThreeDSChallengeViewModel.ThreeDSChallengeCompletion] = []

        func record(_ completion: ThreeDSChallengeViewModel.ThreeDSChallengeCompletion) {
            recordedCompletions.append(completion)
        }
    }
}
