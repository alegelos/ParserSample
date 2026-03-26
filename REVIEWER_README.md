# Checkout.com iOS Mobile Challenge — Reviewer Notes

This document is the evaluator-facing overview for the submission.

It is intentionally **not** the SDK README and **not** the Sample Application README. Its purpose is to explain the architectural decisions, implementation boundaries, trade-offs, and the reasoning behind the solution.

## Executive summary

The repository is split into two deliverables:

1. **`CheckoutFlow`** — a reusable Swift Package that encapsulates the entire payment flow:
   - card input
   - tokenization
   - payment creation
   - 3DS challenge handling
   - native payment result states
2. **`SampleApplication`** — a very thin host app whose only job is to:
   - inject environment-specific secrets and base URL
   - configure the SDK once
   - present the checkout flow
   - listen to the final result

The sample app stays deliberately small. The payment logic, UI state transitions, request construction, domain mapping, and 3DS handling all live inside the package.

---

## What I optimized for

The brief explicitly calls out user experience, maintainability, readability, scalability, testability, and error handling. This implementation was designed around those qualities first.

The main priorities were:

- **A small public API surface** so the host app cannot accidentally couple itself to internal flow details.
- **Layered architecture** Presenter/Domain/Data so networking, mapping, domain models, and presentation can evolve independently.
- **Reusable payment flow setup** where one-time SDK bootstrap is separated from per-payment data.
- **Thin integration point** in the sample app, matching the spirit of the challenge.
- **Clear failure states** instead of crashes, hidden side effects, or “magic” transitions.

---

## Architecture at a glance

```text
SampleApplication
  └── reads secrets from xcconfig / Info.plist
  └── creates CheckoutFlowModule once
  └── presents CheckoutFlowView with payment-specific configuration

CheckoutFlow (Swift Package)
  ├── Composition
  │   ├── CheckoutFlowConfiguration
  │   ├── CheckoutFlowPaymentConfiguration
  │   └── CheckoutFlowModule
  │
  ├── Domain
  │   ├── CardDetails
  │   ├── PaymentToken
  │   ├── CardPayment
  │   ├── ThreeDSPaymentSession
  │   ├── PaymentStatus
  │   └── PaymentFlowProviderProtocol
  │
  ├── Data
  │   ├── CheckoutAPISetup
  │   ├── request DTOs
  │   ├── response DTOs
  │   └── CheckoutAPIProvider
  │
  └── Presenter
      ├── CardForm
      ├── CheckoutFlow coordinator view model
      ├── 3DS challenge module
      └── Payment result module
```

### Why this split

I wanted the package to expose a **product-facing contract**, not its internal mechanics.

That is why the public surface is intentionally small:

- `CheckoutFlowModule.create(configuration:)`
- `CheckoutFlowView(...)`
- `CheckoutFlowConfiguration`
- `CheckoutFlowPaymentConfiguration`
- completion result types

The host application does **not** know about:

- request DTOs
- endpoint setup
- tokenization details
- payment session mapping
- internal step transitions
- internal view models

That keeps the integration clean and makes the package easier to evolve without breaking adopters.

---

## The most important design decision: bootstrap vs per-payment configuration

A key design point is the split between:

### 1. One-time module bootstrap

`CheckoutFlowModule.create(configuration:)`

This is for values that belong to the SDK/module lifecycle:

- base URL
- public API key
- secret API key
- optionally, a custom network session

These values are environment-level concerns and normally do **not** change for every payment.

### 2. Per-payment configuration

`CheckoutFlowPaymentConfiguration`

This is for values that belong to an individual checkout session:

- amount
- currency
- success callback URL
- failure callback URL
- pay button title

That separation makes the package much more reusable. An app can initialize the module once and present `CheckoutFlowView` multiple times for different payment attempts without rebuilding the SDK state every time.

This also keeps the mental model clean:

- **module configuration** = app/infrastructure concern
- **payment configuration** = feature/use-case concern

---

## End-to-end flow

The flow implemented in the package is:

1. User enters card number, expiry date, and CVV.
2. `CardFormViewModel` validates and sanitizes the input.
3. The package tokenizes the card using Checkout’s token endpoint.
4. After receiving the token, the package creates the payment request.
5. If the payment response is `Pending` and contains a redirect URL, the flow moves to the 3DS challenge screen.
6. A web view loads the redirect URL.
7. Navigation is observed until the success or failure callback URL is detected.
8. The web challenge is dismissed logically inside the flow.
9. A native result screen is shown.
10. The host app receives a final completion callback.

---

## Layer-by-layer explanation

## Composition

The `Composition` folder acts as the package’s assembly boundary.

### `CheckoutFlowConfiguration`
Represents SDK-level configuration.

### `CheckoutFlowPaymentConfiguration`
Represents a single checkout attempt.

### `CheckoutFlowModule`
Acts as the package bootstrap/factory.

Responsibilities:

- creates the concrete provider graph
- holds the shared module instance
- wires the public view to internal dependencies
- prevents the sample app from constructing internal objects directly

This was intentional. I wanted the package to own its internal object graph and avoid exposing implementation detail constructors publicly.

---

## Domain

The `Domain` layer contains the business-facing models and protocol contract.

Examples:

- `CardDetails`
- `PaymentToken`
- `CardPayment`
- `ThreeDSPaymentSession`
- `PaymentStatus`
- `PaymentFlowProviderProtocol`

The important point here is that the rest of the system works with domain concepts rather than raw API JSON.

That keeps UI logic focused on UI decisions, not transport details.

---

## Data

The `Data` layer is responsible for turning domain intent into HTTP requests and mapping API responses back into domain models.

### `CheckoutAPISetup`
Encapsulates request construction for the Checkout endpoints.

Responsibilities:

- path selection
- HTTP method
- headers
- authorization strategy
- body encoding

### DTOs
Request/response DTOs isolate API payload shapes from the rest of the codebase.

That gives a few benefits:

- API naming conventions stay in one place
- domain models remain clean
- mapping logic is explicit and testable
- future API changes have a single containment zone

### `CheckoutAPIProvider`
Concrete implementation of `PaymentFlowProviderProtocol`.

Responsibilities:

- tokenize card
- create payment
- decode response payloads
- return domain models to the presenter layer

This provider is intentionally small because request construction and mapping are already delegated to the setup and DTO layers.

---

## Presenter

The `Presenter` layer contains the full user-facing flow.

### `CardFormViewModel`
Owns:

- field state
- form validation
- input sanitization
- card scheme detection
- loading state
- tokenization trigger
- submit error state

### `CheckoutFlowViewModel`
This is the orchestration point for the package.

It coordinates the high-level step machine:

- card form
- 3DS challenge
- payment result

It deliberately owns the transition logic so child modules stay focused on their own single responsibility.

### `ThreeDSChallengeViewModel`
Owns:

- web loading state
- web failure state
- navigation callback interpretation
- cancellation handling

### `PaymentResultViewModel`
Owns the native result presentation for:

- success
- failure
- cancellation

This split keeps each presenter simple and prevents one large “god view model”.

---

## Why the internal view models are not public

This was a deliberate API design choice.

The challenge says the host app should inject secrets and listen to the final result. I interpreted that as a signal that the package should expose the flow as a **feature**, not as a bag of internal types.

So the integration point is:

- configure once
- present view
- receive completion

The host app should not need to know how the card form works internally, how 3DS decisions are resolved, or how result screens are composed.

That keeps encapsulation strong and makes the package feel closer to a production-ready internal SDK.

---

## Why I used my own `iOSCleanNetwork` package (writen by me and still needs some tweaking on the AI part)

The only external package used here is **`iOSCleanNetwork`**, which is my own reusable networking package.

I included it because it improves the architectural quality of the solution in a few very practical ways:

- it provides a clean request abstraction via `ApiSetupProtocol`
- it keeps `URLSession` behind a protocol boundary
- it makes request-building and transport easier to test
- it lets the Checkout package focus on payment domain logic instead of generic networking infrastructure

In other words, I did **not** use a third-party payment SDK or a UI dependency to shortcut the challenge.
I used my own infrastructure package to keep the submission cleaner, more modular, and more testable.

---

## Testing strategy

The existing automated test coverage focuses on the most deterministic and most valuable low-level boundaries first:

- request construction
- authorization headers
- endpoint paths
- provider behavior
- response mapping to domain models

This is where the highest signal-to-noise ratio exists for a small challenge project.

The data layer is tested with mocked networking through the infrastructure abstraction rather than through live network calls.

That means the tests validate:

- the token request is built correctly
- the payment request is built correctly
- decoded fixtures map into the expected domain objects
- failures can be injected and asserted in isolation

This gives confidence in the most failure-prone integration boundary without requiring end-to-end environment dependence.

## Sample application responsibilities

The sample app is intentionally thin, dump and no arch. It also uses force unwraping urls URL()!

It does three things:

1. reads secrets and base URL from configuration
2. bootstraps the module
3. presents the package view and shows the final outcome

The app does **not**:

- build payment requests manually
- perform tokenization itself
- own 3DS web navigation logic
- parse API payloads
- decide flow steps internally

That logic belongs in the package.

---

## Closing note

This submission was built to solve the exercise, but also to demonstrate how I think about SDK boundaries, feature modularization, presentation architecture, and pragmatic reuse.

The implementation is intentionally not “just enough to work.”
It is structured to show:

- how I separate product logic from infrastructure
- how I protect module boundaries
- how I keep host apps thin
- how I design for testability from the beginning

If I were joining a team working on payments, internal SDKs, or complex mobile flows, this is the kind of structure I would want as a starting point.
