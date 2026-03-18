import Foundation

/// Shared HTTP status‐code validator that reuses your existing ApiErrors.
enum NetworkValidation {
    /// Validates that `response` is 2xx, or throws the appropriate `ApiErrors`.
    /// - Returns: the original `data`.
    static func validate(
        data: Data,
        response: URLResponse,
        for request: URLRequest
    ) throws -> Data {
        guard let http = response as? HTTPURLResponse else {
            throw ApiErrors.undefined
        }
        let code = http.statusCode
        if (200..<300).contains(code) {
            return data
        }

        let dataAsString = String(data: data, encoding: String.Encoding.utf8)

        // TODO: Log request fails request, response and dataAsString

        switch code {
        case 400:
            throw ApiErrors.invalidBody
        case 401:
            throw ApiErrors.unauthorized
        case 403:
            throw ApiErrors.forbidden
        case 404:
            throw ApiErrors.notFound
        case 500..<600:
            throw ApiErrors.serverError
        default:
            throw ApiErrors.undefined
        }
    }
    
}
