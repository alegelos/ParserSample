import SwiftUI
import Observation
import WebKit

struct CheckoutThreeDSChallengeView: View {
    
    @Bindable var viewModel: CheckoutThreeDSChallengeViewModel
    
    var body: some View {
        ZStack {
            CheckoutThreeDSChallengeWebView(
                requestURL: viewModel.requestURL,
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
            
            if viewModel.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Loading authentication…")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground).opacity(0.95))
                )
            }
            
            if let errorMessage = viewModel.errorMessage {
                VStack {
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Authentication Error")
                            .font(.headline)
                        
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
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
        .navigationTitle(viewModel.titleText)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.showsCloseButton {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        viewModel.didTapCloseButton()
                    }
                }
            }
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
    
    func updateUIView(_ uiView: WKWebView, context: Context) { }
    
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
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }
            
            let shouldAllowNavigation = decideNavigationPolicy(url)
            decisionHandler(shouldAllowNavigation ? .allow : .cancel)
        }
    }
}

#Preview {
    NavigationStack {
        CheckoutThreeDSChallengeView(
            viewModel: CheckoutThreeDSChallengeViewModel(
                requestURL: URL(string: "https://example.com")!
            )
        )
    }
}
