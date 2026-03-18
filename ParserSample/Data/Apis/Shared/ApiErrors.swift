import Foundation

/// Enumeration for Api errors
public enum ApiErrors: Error {

	/// When accessToken is not valid
	case unauthorized

	/// When access Token has been refreshed too many times
	case tooManyRefreshAcessToken

	/// When user have not permission to call this API
	case forbidden

	/// When Api not fount
	case notFound

    /// Something went wrong on the server side
    case serverError

	/// When error is not defined
	case undefined

	/// When accessToken is not valid
	case invalidToken

	/// When accessToken is missing
	case missingToken

	/// When Api url is not valid
	case invalidUrl

	/// When Api body is not valid
	case invalidBody

	/// When response is nil
	case nilResponse

    /// When Api result cannot be decode
    case decodeError

    /// When Api is too long to respond
    case timeOut

    /// Some mandatory parameters are missing
    case missingParameters
    
    /// Some mandatory parameters are missing
    case domainMappingError

    var description: String {
        (self as NSError).description
    }
}
