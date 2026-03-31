# Checkout.com iOS Mobile Challenge — Reviewer Notes

This document is the evaluator-facing overview for the submission.

It is intentionally **not** the SDK README and **not** the Sample Application README. Its purpose is to explain the architectural decisions, implementation boundaries, trade-offs, and the reasoning behind the solution.

## Executive summary

The repository is split into two deliverables:

1. **`CheckoutFlow`** — a reusable Swift Package that encapsulates the payment flow:
   - card input
   - tokenization
   - payment creation
   - 3DS challenge handling
   - native result presentation
2. **`SampleApplication`** — a thin host app that:
   - reads environment-specific secrets and base URL
   - builds the SDK configuration
   - creates the shared module used by the flow
   - presents the checkout flow
   - listens to the final result

A small but important implementation detail: the current sample app creates the shared module from `SampleCheckoutHostView.resolveState()` when the checkout host is built. The SDK design still supports one-time bootstrap and reuse across many payment attempts, but the sample app keeps setup close to the demo flow entry point.

---

## What I optimized for

The brief explicitly calls out user experience, maintainability, readability, scalability, testability, and error handling. This implementation was designed around those qualities first.

The main priorities were:

- **A small host-app integration surface** so the app does not couple itself to internal flow steps.
- **Layered architecture** (`Composition` / `Domain` / `Data` / `Presenter`) so networking, mapping, and presentation can evolve independently.
- **A reusable module design** where shared SDK bootstrap is separated from per-payment data.
- **A thin demo app** that delegates payment logic and flow handling to the package.
- **Explicit failure states** instead of crashes or hidden transitions.

---

## Architecture at a glance

```text
SampleApplication
  └── reads secrets from xcconfig / Info.plist
  └── builds CheckoutFlowConfiguration
  └── creates CheckoutFlowModule
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

I wanted the package to expose a feature-level contract, not its internal mechanics.

That is why the intended integration point is deliberately small:

- `CheckoutFlowModule.create(configuration:)`
- `CheckoutFlowView(...)`
- `CheckoutFlowConfiguration`
- `CheckoutFlowPaymentConfiguration`
- `CheckoutFlowCompletionResult`

The host application does **not** need to know about:

- request DTOs
- endpoint setup
- tokenization details
- payment session mapping
- internal step transitions
- internal view models

That keeps the integration cleaner and makes the package easier to evolve.

---

## The most important design decision: shared setup vs per-payment configuration

A key design point is the split between:

### 1. Shared module setup

`CheckoutFlowModule.create(configuration:)`

This is for values that belong to the SDK/module lifecycle:

- base URL
- public API key
- secret API key
- optionally, a custom network session

These values are infrastructure concerns and normally do **not** change for every payment.

### 2. Per-payment configuration

`CheckoutFlowPaymentConfiguration`

This is for values that belong to an individual checkout attempt:

- amount
- currency
- success callback URL
- failure callback URL
- pay button title

That separation makes the package reusable. A host app can build the module once and present `CheckoutFlowView` multiple times with different payment inputs, even though the current sample app keeps module creation close to the presentation entry point.

This keeps the mental model clean:

- **module configuration** = infrastructure concern
- **payment configuration** = use-case concern

---

## End-to-end flow

The flow implemented in the package is:

1. The user enters card number, expiry date, and CVV.
2. `CardFormViewModel` validates and sanitizes the input.
3. The package tokenizes the card using Checkout’s token endpoint.
4. The package creates the payment request.
5. If the payment response is `pending` and contains a redirect URL, the flow moves to the 3DS challenge screen.
6. A web view loads the redirect URL.
7. Navigation is observed until the configured success or failure callback URL is detected.
8. The flow transitions to a native result screen.
9. The host app receives a final completion callback when the result screen action is taken.

### Important current behavior

The implementation is intentionally narrow around the challenge flow:

- `pending` + redirect URL is the happy path into 3DS.
- `pending` without redirect URL becomes a native failure state.
- any unsupported payment status becomes a native failure state.

So this submission is optimized around the 3DS-oriented flow exercised by the challenge, rather than around a full multi-status payment state machine.

---

## Layer-by-layer explanation

## Composition

The `Composition` folder acts as the package assembly boundary.

### `CheckoutFlowConfiguration`
Represents SDK-level configuration.

### `CheckoutFlowPaymentConfiguration`
Represents a single checkout attempt.

### `CheckoutFlowModule`
Acts as the package bootstrap / factory.

Responsibilities:

- creates the concrete provider graph
- holds the shared module instance
- wires the public view to internal dependencies
- prevents the sample app from constructing internal objects directly

This was intentional. I wanted the package to own its object graph instead of exposing implementation-detail constructors publicly.

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

The important point here is that the rest of the package works with domain concepts rather than raw API payloads.

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
Request and response DTOs isolate transport payload shapes from the rest of the codebase.

That gives a few benefits:

- API naming conventions stay in one place
- domain models remain clean
- mapping logic is explicit and testable
- future API changes have a clear containment zone

### `CheckoutAPIProvider`
Concrete implementation of `PaymentFlowProviderProtocol`.

Responsibilities:

- tokenize card
- create payment
- decode response payloads
- return domain models to the presenter layer

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

This split avoids one large “god view model” and keeps responsibilities focused.

---

## Why the internal view models are not public

This was a deliberate API design choice.

The host app should be able to:

- configure the SDK
- present the flow
- receive the final outcome

It should not need to know how the card form works internally, how 3DS navigation is resolved, or how result screens are composed.

That keeps encapsulation strong and makes the package closer to a production-style internal SDK.

---

## Why I used my own `iOSCleanNetwork` package

The only external package used here is **`iOSCleanNetwork`**, which is my own reusable networking package.

I used it because it improves the structure of the solution in practical ways:

- it provides a request abstraction via `ApiSetupProtocol`
- it keeps `URLSession` behind a protocol boundary
- it makes request-building and transport easier to test
- it lets the Checkout package focus on payment-flow concerns instead of generic networking infrastructure

In other words, I did **not** use a third-party payment SDK or UI package to shortcut the challenge. I used my own infrastructure layer to keep the submission modular and testable.

---

## Testing strategy

The automated coverage is not limited to the data layer anymore.

The current test suite covers both:

### Data-layer behavior

- request construction
- authorization headers
- endpoint paths
- response decoding
- mapping to domain models
- injected transport failures

### Presenter-layer behavior

- card form validation and sanitization
- card scheme detection
- checkout step transitions
- 3DS callback matching
- native result behavior
- completion callback outcomes

This gives confidence in both the integration boundary and the internal flow orchestration without relying on live network calls.

---

## Current trade-offs and known scope limits

A few implementation choices are intentionally narrow and worth calling out explicitly:

### Card-scheme behavior is partial

The package currently detects a few schemes for presentation purposes:
- Visa
- Mastercard
- Amex
- Discover

But the input behavior is still generic:
- card number formatting is grouped in blocks of 4
- CVV validation uses a generic minimum length of 3
- there is no scheme-specific Amex formatting or validation path yet

### Payment-status handling is intentionally narrow

The current code handles:
- `pending` + redirect URL
- `pending` without redirect URL -> failure
- unknown status -> failure

That is enough for the challenge flow here, but it is not yet a broader production payment status model.

---

## Sample application responsibilities

The sample app is intentionally thin and demo-focused.

It currently does five things:

1. reads secrets and base URL from configuration
2. builds `CheckoutFlowConfiguration`
3. creates the shared module used by the flow
4. presents the package view in a sheet
5. shows the final outcome text after dismissal

The app does **not**:

- build API requests manually
- tokenize cards itself
- own 3DS web navigation logic
- parse API payloads
- decide checkout flow steps internally

That logic belongs in the package.

The sample also intentionally keeps some demo-level shortcuts, for example hardcoded payment data and force-unwrapped demo callback URLs in `CheckoutFlowSetup.samplePayment`.

---

## Closing note

This submission was built to solve the exercise, but also to demonstrate how I think about SDK boundaries, feature modularization, presentation architecture, and pragmatic reuse.

The implementation is intentionally more structured than a “just make it work” sample. It is designed to show:

- how I separate feature logic from infrastructure
- how I protect module boundaries
- how I keep host apps thin
- how I design for testability from the beginning

If I were joining a team working on payments, internal SDKs, or complex mobile flows, this is the kind of structure I would want as a starting point.
