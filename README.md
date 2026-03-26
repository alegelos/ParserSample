# CheckoutFlow

`CheckoutFlow` is a Swift Package that provides a ready-to-present SwiftUI card payment flow.

The SDK owns the UI flow internally:
- card form
- card tokenization
- payment creation
- 3D Secure challenge
- final result screen

From the host app perspective, the integration surface is intentionally small:
- initialize the SDK once with `CheckoutFlowModule.create(...)`
- create a `CheckoutFlowView` whenever you want to present a payment flow
- react to the final `CheckoutFlowCompletionResult`

## Requirements

- iOS 18+
- Swift 6.2

## Installation

Add the package with Swift Package Manager.

### Xcode

Use **File > Add Package Dependencies...** > https://github.com/alegelos/ParserSample

### Package.swift

```swift
.package(url: "https://github.com/alegelos/ParserSample", from: "1.0.3")
```

Then add the product to your target:

```swift
.product(name: "CheckoutFlow", package: "CheckoutFlow")
```

## Public API

The SDK is currently designed to be consumed through these public types:

- `CheckoutFlowModule`
- `CheckoutFlowConfiguration`
- `CheckoutFlowPaymentConfiguration`
- `CheckoutFlowView`
- `CheckoutFlowCompletionResult`

The internal view models and internal flow steps are implementation details and are not part of the integration contract.

## Integration Overview

The integration has two distinct phases:

### 1. Bootstrap the SDK once

Use `CheckoutFlowModule.create(...)` once during app startup, feature bootstrap, or before the first checkout is shown.

```swift
import CheckoutFlow

let checkoutConfiguration = CheckoutFlowConfiguration(
    baseURL: URL(string: "https://api.sandbox.checkout.com")!,
    publicAPIKey: "pk_sbox_example",
    secretAPIKey: "sk_sbox_example"
)

CheckoutFlowModule.create(configuration: checkoutConfiguration)
```

This stores a shared module instance used later by `CheckoutFlowView`.

### 2. Present a payment flow whenever needed

Each payment attempt is configured with a `CheckoutFlowPaymentConfiguration`.

```swift
import CheckoutFlow
import SwiftUI

struct PaymentScreen: View {

    var body: some View {
        try? CheckoutFlowView(
            paymentConfiguration: CheckoutFlowPaymentConfiguration(
                amountInMinorUnits: 1_099,
                currencyCode: "EUR",
                successURL: URL(string: "myapp://checkout/success")!,
                failureURL: URL(string: "myapp://checkout/failure")!,
                payButtonTitle: "Pay €10.99"
            ),
            onComplete: { result in
                switch result {
                case .completedSuccessfully:
                    print("Payment succeeded")

                case .completedWithFailure(let message):
                    print("Payment failed: \(message ?? \"Unknown error\")")

                case .cancelled:
                    print("Payment cancelled")
                }
            }
        )
    }
}
```

## Recommended App Lifecycle

A typical lifecycle looks like this:

1. create the module once with API configuration
2. show `CheckoutFlowView` for a specific payment
3. receive the completion callback
4. show `CheckoutFlowView` again later with a different `CheckoutFlowPaymentConfiguration` if needed

You do **not** need to recreate the module for every payment attempt as long as the SDK configuration stays the same.

## Configuration Types

### CheckoutFlowConfiguration

Defines the SDK-wide setup used by the shared module.

```swift
public struct CheckoutFlowConfiguration: Sendable, Equatable {
    public let baseURL: URL
    public let publicAPIKey: String
    public let secretAPIKey: String
}
```

#### Fields

- `baseURL`: Checkout API base URL
- `publicAPIKey`: used by the tokenization request
- `secretAPIKey`: used by the payment request

## Important

In the current SDK implementation, both tokenization and payment creation are performed by the package itself, so both keys are required by `CheckoutFlowConfiguration`.

### CheckoutFlowPaymentConfiguration

Defines the data for one specific checkout attempt.

```swift
public struct CheckoutFlowPaymentConfiguration: Sendable, Equatable {
    public let amountInMinorUnits: Int
    public let currencyCode: String
    public let successURL: URL
    public let failureURL: URL
    public let payButtonTitle: String
}
```

#### Fields

- `amountInMinorUnits`: payment amount in minor units
- `currencyCode`: ISO currency code such as `EUR` or `GBP`
- `successURL`: callback URL that marks the 3DS flow as successful
- `failureURL`: callback URL that marks the 3DS flow as failed
- `payButtonTitle`: button label shown in the card form

## Completion Callback

`CheckoutFlowView` finishes through the `onComplete` closure.

```swift
public enum CheckoutFlowCompletionResult: Equatable, Sendable {
    case completedSuccessfully
    case completedWithFailure(message: String?)
    case cancelled
}
```

### Meanings

- `completedSuccessfully`: the payment flow reached the configured success callback
- `completedWithFailure(message:)`: the flow failed during submission or reached the configured failure callback
- `cancelled`: the user closed the 3DS challenge before completing it

## 3DS Callback URL Handling

During the 3DS challenge, the SDK monitors web navigation and compares navigated URLs against the configured `successURL` and `failureURL`.

A navigation is considered a match when either:
- the full absolute URL matches exactly, or
- the scheme, host, and path match

That means these callback URLs should be stable and uniquely identify the success and failure outcomes for your app.

## Error Mapping

You can customize the message shown when submission fails by passing `mapSubmitErrorMessage` to `CheckoutFlowView`.

```swift
try CheckoutFlowView(
    paymentConfiguration: paymentConfiguration,
    mapSubmitErrorMessage: { error in
        // Convert technical errors into user-facing copy
        return "We couldn't process your payment. Please try again."
    },
    onComplete: { result in
        // Handle final outcome
    }
)
```

This closure is used for:
- tokenization failures
- payment creation failures

If you do not provide a mapper, the SDK falls back to its default user-facing messages.

## Module Lifecycle

### Create

```swift
CheckoutFlowModule.create(configuration: checkoutConfiguration)
```

Creates or replaces the shared module instance.

### Destroy

```swift
CheckoutFlowModule.destroy()
```

Resets the shared module instance.

This is mainly useful when you want to explicitly clear SDK state, for example:
- logout flows
- test setup and teardown
- environment switching

## Initialization Error

`CheckoutFlowView` depends on the shared module created by `CheckoutFlowModule.create(...)`.

If you try to build the view before creating the module, its initializer throws `CheckoutFlowError.moduleNotInitialized`.

```swift
public enum CheckoutFlowError: LocalizedError, Equatable {
    case moduleNotInitialized
}
```

Make sure module creation happens before the first checkout view is presented.

## Custom Networking Session

The SDK uses `URLSession.shared` by default.

You can inject a custom session when bootstrapping the module:

```swift
import CheckoutFlow
import iOSCleanNetwork

CheckoutFlowModule.create(
    configuration: checkoutConfiguration,
    session: URLSession.shared
)
```

Use this when you need custom networking behavior such as:
- test doubles
- request interception
- custom transport configuration


## Notes

- `CheckoutFlowView` already wraps its content in a `NavigationStack`
- the SDK is SwiftUI-first
- payment-specific input such as amount, currency, and callback URLs belongs in `CheckoutFlowPaymentConfiguration`
- SDK-wide setup such as API keys and base URL belongs in `CheckoutFlowConfiguration`
