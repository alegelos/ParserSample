import Foundation

extension URLSession: NetworkSessionProtocol {

    func data(for apiRequestSetup: ApiSetupProtocol) async throws -> (Data, URLResponse) {
        let request = try apiRequestSetup.request

        do {
            let (data, response) = try await self.data(for: request)

            let validated = try NetworkValidation.validate(
                data: data,
                response: response,
                for: request
            )

            return (validated, response)
        } catch {
            // TODO: Log request fails
            throw error
        }
    }

    func dataWithUnauthorizedRefreshRetry(
        apiAccessProvider: ApisGatewayProtocol,
        buildEndpoint: (String) -> ApiSetupProtocol
    ) async throws -> (Data, URLResponse) {
        do {
            let apiAccessToken = try await apiAccessProvider.apisAccessToken()
            let endpoint = buildEndpoint(apiAccessToken)

            return try await data(for: endpoint)
        } catch ApiErrors.unauthorized {
            let apiAccessToken = try await apiAccessProvider.apisAccessToken(policy: .forceRefresh)
            let endpoint = buildEndpoint(apiAccessToken)

            return try await data(for: endpoint)
        }
    }

}
