# CheckoutFlow

`CheckoutFlow` is an iOS Swift Package that wraps a small card payment flow on top of Checkout.com's tokenization and payment endpoints.

The package is structured so app code can stay simple while the networking layer remains testable and replaceable.

## Requirements

- iOS 17+
- Swift 6.2
- Xcode 16+

## Installation

### Swift Package Manager

Add the package in Xcode using **File > Add Package Dependencies...** and point it to your repository.

Or add it to `Package.swift`:

```swift
.package(url: "<your-checkoutflow-repository-url>", from: "1.0.0")
```

Then add the product dependency:

```swift
.product(name: "CheckoutFlow", package: "CheckoutFlow")
```

## Usage

### 1. Import the package

```swift
import CheckoutFlow
```

### 2. Build the configuration

```swift
let configuration = CheckoutFlowConfiguration(
    baseURL: URL(string: "https://api.sandbox.checkout.com")!,
    publicAPIKey: "pk_sbox_example",
    secretAPIKey: "sk_sbox_example"
)
```

### 3. Initialize the module

```swift
CheckoutFlowModule.create(configuration: configuration)
```

By default, the module uses `URLSession.shared` as its `NetworkSessionProtocol` implementation.

If you need a custom session, inject it during initialization:

```swift
CheckoutFlowModule.create(
    configuration: configuration,
    session: URLSession.shared
)
```

### 4. Access the shared module

```swift
let checkoutFlow = try CheckoutFlowModule.shared
```

### 5. Tokenize the card

```swift
let cardDetails = CardDetails(
    cardNumber: "4242424242424242",
    expirationMonth: "10",
    expirationYear: "2025",
    securityCode: "100"
)

let paymentToken = try await checkoutFlow.tokenizeCard(cardDetails)
```

### 6. Create the payment

```swift
let cardPayment = CardPayment(
    paymentToken: paymentToken,
    amountInMinorUnits: 6540,
    currencyCode: "GBP",
    successURL: URL(string: "https://example.com/payments/success")!,
    failureURL: URL(string: "https://example.com/payments/fail")!
)

let paymentSession = try await checkoutFlow.createPayment(cardPayment)
```

### 7. Handle the response

```swift
switch paymentSession.status {
case .pending:
    if let redirectURL = paymentSession.redirectURL {
        // Present 3DS web flow
        print("Redirect user to: \(redirectURL)")
    }
case .unknown(let rawValue):
    print("Unhandled payment status: \(rawValue)")
}
```

## Thread safety

`CheckoutFlowModule` stores its shared instance behind an internal concurrent queue with barrier writes.

That means:

- module initialization is serialized
- shared access is synchronized
- callers should still treat initialization as an app bootstrap concern and perform it once in a controlled place

## Architecture notes

The package follows a simple layered structure:

- `Domain`: business-facing models and protocols
- `Data`: API setup, DTOs, response mapping, concrete provider
- `Presenter`: Empty
- `Composition`: SDK bootstrap and wiring

This keeps the public contract stable while allowing the API implementation to evolve independently.
