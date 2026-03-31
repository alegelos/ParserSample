# CheckoutFlow

`CheckoutFlow` is a Swift Package that provides a ready-to-present SwiftUI card payment flow.

The package owns the checkout flow internally:
- card form
- card tokenization
- payment creation
- 3D Secure challenge
- final native result screen

The intended host-app integration surface is small:
- create the shared module with `CheckoutFlowModule.create(...)`
- build a `CheckoutFlowView` for each payment attempt
- handle the final `CheckoutFlowCompletionResult`

## Requirements

- iOS 15+
- Swift 6.2

## Installation

Add the package with Swift Package Manager.

### Xcode

Use **File > Add Package Dependencies...** and add this repository:

```text
https://github.com/alegelos/ParserSample
```

Then add the `CheckoutFlow` library product to your app target.

### Package.swift

```swift
.package(url: "https://github.com/alegelos/ParserSample", from: "1.0.3")
```

Then add the product to your target dependencies:

```swift
.product(name: "CheckoutFlow", package: "ParserSample")
```

## Recommended integration surface

For a normal SwiftUI integration, these are the types you should care about first:

- `CheckoutFlowModule`
- `CheckoutFlowConfiguration`
- `CheckoutFlowPaymentConfiguration`
- `CheckoutFlowView`
- `CheckoutFlowCompletionResult`
- `CheckoutFlowError`

The package also exposes some domain models publicly, but the normal host-app integration does not need to construct or coordinate the internal flow manually.

## Integration overview

The integration has two phases.

### 1. Bootstrap the shared module

Create the shared module before the first checkout view is presented.

```swift
import CheckoutFlow

let checkoutConfiguration = CheckoutFlowConfiguration(
    baseURL: URL(string: "https://api.sandbox.checkout.com")!,
    publicAPIKey: "pk_sbox_example",
    secretAPIKey: "sk_sbox_example"
)

CheckoutFlowModule.create(configuration: checkoutConfiguration)
```

`create(...)` replaces the current shared instance, so it can also be used again if you intentionally want to swap environments or rebuild the module.

### 2. Present a payment flow when needed

Each checkout attempt is described by `CheckoutFlowPaymentConfiguration`.

```swift
import CheckoutFlow
import SwiftUI

struct PaymentScreen: View {

    var body: some View {
        Group {
            if let checkoutFlowView = try? CheckoutFlowView(
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
            ) {
                checkoutFlowView
            } else {
                Text("Checkout could not be initialized.")
            }
        }
    }
}
```

## Module lifecycle

### Create

```swift
CheckoutFlowModule.create(configuration: checkoutConfiguration)
```

Creates or replaces the shared module instance.

### Destroy

```swift
CheckoutFlowModule.destroy()
```

Clears the shared module instance.

Useful for:
- logout flows
- tests
- environment switching

## Configuration types

### CheckoutFlowConfiguration

Defines SDK-wide configuration used by the shared module.

```swift
public struct CheckoutFlowConfiguration: Sendable, Equatable {
    public let baseURL: URL
    public let publicAPIKey: String
    public let secretAPIKey: String
}
```

#### Fields

- `baseURL`: Checkout API base URL
- `publicAPIKey`: used for card tokenization
- `secretAPIKey`: used for payment creation

### CheckoutFlowPaymentConfiguration

Defines one checkout attempt.

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
- `successURL`: callback URL treated as a successful 3DS completion
- `failureURL`: callback URL treated as a failed 3DS completion
- `payButtonTitle`: button label shown in the card form

## Completion callback

`CheckoutFlowView` finishes through the `onComplete` closure.

```swift
public enum CheckoutFlowCompletionResult: Equatable, Sendable {
    case completedSuccessfully
    case completedWithFailure(message: String?)
    case cancelled
}
```

### Meanings

- `completedSuccessfully`: the flow reached the configured success callback URL
- `completedWithFailure(message:)`: the flow failed before completion or reached the configured failure callback URL
- `cancelled`: the user closed the 3DS challenge flow

## Current flow behavior

The current implementation expects payment creation to return a `pending` status with a redirect URL for 3DS authentication.

More specifically:
- `pending` + redirect URL -> moves to the 3DS web challenge
- `pending` without redirect URL -> shows a failure result
- any unsupported payment status -> shows a failure result

## 3DS callback URL matching

During the 3DS challenge, the SDK monitors web navigation and compares navigated URLs against the configured `successURL` and `failureURL`.

A navigation is considered a match when either:
- the full absolute URL matches exactly, or
- the scheme, host, and path match

That lets the flow work with custom URL schemes and with standard HTTPS callback URLs, as long as they remain stable and uniquely identify success and failure.

## Error mapping

You can customize the user-facing message used for submission-stage failures by passing `mapSubmitErrorMessage` to `CheckoutFlowView`.

```swift
try CheckoutFlowView(
    paymentConfiguration: paymentConfiguration,
    mapSubmitErrorMessage: { error in
        return "We couldn't process your payment. Please try again."
    },
    onComplete: { result in
        // Handle final outcome
    }
)
```

This mapper is currently used for:
- tokenization failures
- payment creation failures

It is not used for 3DS success or failure callback matches themselves.

## Initialization error

`CheckoutFlowView` depends on the shared module created by `CheckoutFlowModule.create(...)`.

If you try to build the view before creating the module, its initializer throws `CheckoutFlowError.moduleNotInitialized`.

```swift
public enum CheckoutFlowError: LocalizedError, Equatable {
    case moduleNotInitialized
}
```

## Custom networking session

The SDK uses `URLSession.shared` by default.

You can inject a custom session when creating the shared module:

```swift
import CheckoutFlow
import iOSCleanNetwork

CheckoutFlowModule.create(
    configuration: checkoutConfiguration,
    session: URLSession.shared
)
```

Use this when you need:
- test doubles
- request interception
- custom transport configuration

## Notes

- `CheckoutFlowView` currently wraps its content in a `NavigationView` and applies `StackNavigationViewStyle()` for iOS 15 compatibility.
- The SDK is SwiftUI-first.
- Payment-specific values such as amount, currency, and callback URLs belong in `CheckoutFlowPaymentConfiguration`.
- SDK-wide values such as API keys and base URL belong in `CheckoutFlowConfiguration`.
