import Foundation

/// Defines how to obtain an OAuth access token for calling protected APIs.
public protocol ApisGatewayProtocol: AnyObject {

    /// Returns a valid OAuth bearer token for accessing protected APIs (e.g., Apigee), not a user identity token.
    ///
    /// - Parameter policy: Determines whether to reuse a cached token or force-refresh.
    /// - Returns: An OAuth access token string suitable for authenticating API requests.
    /// - Throws: Any network or decoding error encountered during retrieval.
    func apisAccessToken(policy: AccessTokenPolicy) async throws -> String

}

// MARK: Convenience Extension

extension ApisGatewayProtocol {

    /// This is equivalent to calling `apisAccessToken(policy: .default)`.
    public func apisAccessToken() async throws -> String {
        try await apisAccessToken(policy: .default)
    }

}

// MARK: - Access Token Refresh Policy

/// Defines how strictly to refresh your cached token.
public enum AccessTokenPolicy {

    /// Token will be valid for at least `minTTL` more seconds, fetching a new one if needed.
    case useCache(minTTL: TimeInterval)
    /// Fetch a fresh token.
    case forceRefresh

    /// A convenient “default” valid for at least 15 min
    public static let `default` = AccessTokenPolicy.useCache(minTTL: 180)
}
