import SwiftUI
import Observation
import WebKit

struct ThreeDSChallengeView: View {
    
    @Bindable var viewModel: ThreeDSChallengeViewModel
    
    var body: some View {
        let viewState = viewModel.viewState
        
        ZStack {
            CheckoutThreeDSChallengeWebView(
                requestURL: viewState.requestURL,
                didStartLoading: {
                    viewModel.didStartLoading()
                },
                didFinishLoading: {
                    viewModel.didFinishLoading()
                },
                didFailLoading: { error in
                    viewModel.didFailLoading(with: error)
                },
                decideNavigationPolicy: { url in
                    viewModel.decideNavigationPolicy(for: url)
                }
            )
            
            if viewState.shouldShowLoadingOverlay {
                loadingOverlayView(viewState: viewState)
            }
            
            if viewState.shouldShowErrorView {
                errorView(viewState: viewState)
            }
        }
        .navigationTitle(viewState.titleText)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewState.showsCloseButton {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(viewState.closeButtonTitle) {
                        viewModel.didTapCloseButton()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func loadingOverlayView(viewState: ThreeDSChallengeViewState) -> some View {
        VStack(spacing: 12) {
            ProgressView()
            
            Text(viewState.loadingText)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground).opacity(0.95))
        )
    }
    
    @ViewBuilder
    private func errorView(viewState: ThreeDSChallengeViewState) -> some View {
        VStack {
            Spacer()
            
            VStack(alignment: .leading, spacing: 8) {
                Text(viewState.errorTitleText)
                    .font(.headline)
                
                if let errorMessage = viewState.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.separator).opacity(0.25), lineWidth: 1)
            )
            .padding(16)
        }
    }
}

private struct CheckoutThreeDSChallengeWebView: UIViewRepresentable {
    
    let requestURL: URL
    let didStartLoading: () -> Void
    let didFinishLoading: () -> Void
    let didFailLoading: (Error) -> Void
    let decideNavigationPolicy: (URL) -> Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            didStartLoading: didStartLoading,
            didFinishLoading: didFinishLoading,
            didFailLoading: didFailLoading,
            decideNavigationPolicy: decideNavigationPolicy
        )
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let webViewConfiguration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: webViewConfiguration)
        
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        
        let request = URLRequest(url: requestURL)
        webView.load(request)
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) { }
    
    final class Coordinator: NSObject, WKNavigationDelegate {
        
        private let didStartLoading: () -> Void
        private let didFinishLoading: () -> Void
        private let didFailLoading: (Error) -> Void
        private let decideNavigationPolicy: (URL) -> Bool
        
        init(
            didStartLoading: @escaping () -> Void,
            didFinishLoading: @escaping () -> Void,
            didFailLoading: @escaping (Error) -> Void,
            decideNavigationPolicy: @escaping (URL) -> Bool
        ) {
            self.didStartLoading = didStartLoading
            self.didFinishLoading = didFinishLoading
            self.didFailLoading = didFailLoading
            self.decideNavigationPolicy = decideNavigationPolicy
        }
        
        func webView(
            _ webView: WKWebView,
            didStartProvisionalNavigation navigation: WKNavigation!
        ) {
            didStartLoading()
        }
        
        func webView(
            _ webView: WKWebView,
            didFinish navigation: WKNavigation!
        ) {
            didFinishLoading()
        }
        
        func webView(
            _ webView: WKWebView,
            didFail navigation: WKNavigation!,
            withError error: Error
        ) {
            didFailLoading(error)
        }
        
        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation!,
            withError error: Error
        ) {
            didFailLoading(error)
        }
        
        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let requestURL = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }
            
            let shouldAllowNavigation = decideNavigationPolicy(requestURL)
            decisionHandler(shouldAllowNavigation ? .allow : .cancel)
        }
    }
}

#Preview {
    NavigationStack {
        ThreeDSChallengeView(
            viewModel: ThreeDSChallengeViewModel(
                requestURL: URL(string: "https://example.com")!
            )
        )
    }
}
