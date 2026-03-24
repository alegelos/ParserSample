import Foundation
import iOSCleanNetworkTesting

@testable import CheckoutFlow

extension CheckoutAPISetup: URLSessionSetupProtocol {

    public var jsonFileName: String {
        switch self {
        case .token:
            return "tokenizeCard_success"
        case .payment:
            return "requestPayment_pending"
        }
    }

    public var jsonBundle: Bundle {
        .module
    }
}
