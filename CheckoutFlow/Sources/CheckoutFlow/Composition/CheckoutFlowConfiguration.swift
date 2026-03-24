import Foundation

public struct CheckoutFlowConfiguration: Sendable, Equatable {
    
    public let baseURL: URL
    public let publicAPIKey: String
    public let secretAPIKey: String

    public init(
        baseURL: URL,
        publicAPIKey: String,
        secretAPIKey: String
    ) {
        self.baseURL = baseURL
        self.publicAPIKey = publicAPIKey
        self.secretAPIKey = secretAPIKey
    }
    
}
