# Sample App

This app is a minimal demo for the `CheckoutFlow` SDK.

Its job is to show a very small host-app integration:
- read Checkout sandbox configuration from xcconfig / `Info.plist`
- create `CheckoutFlowConfiguration`
- create the shared `CheckoutFlowModule`
- present `CheckoutFlowView` inside a sheet
- show the final result after the sheet is dismissed

It is intentionally small and demo-focused. It is not meant to represent a production app architecture.

## What the sample currently does

The sample app currently:
- reads `CheckoutPublicKey`, `CheckoutSecretKey`, and `CheckoutBaseURL` from the app configuration
- builds the SDK configuration in `CheckoutFlowSetup.swift`
- creates the shared module inside `SampleCheckoutHostView.resolveState()`
- uses a hardcoded demo payment from `CheckoutFlowSetup.samplePayment`
- presents the SDK flow inside a sheet from `SampleApplicationRootView`

The demo payment currently uses:
- amount: `6540`
- currency: `GBP`
- success URL: `https://example.com/payments/success`
- failure URL: `https://example.com/payments/fail`
- button title: `Pay £65.40`

## Run the demo

1. Open `SampleApplication/SampleApplication.xcodeproj`.
2. Review or replace the values in `SampleApplication/SampleApplication/Configuration/Secrets.local.xcconfig`.
3. Run the app on an iPhone simulator.
4. Tap **Start Checkout**.

## Configuration flow

The sample app uses this configuration chain:

`Secrets.local.xcconfig` -> build settings -> `Info.plist` -> `CheckoutFlowSetup`

The keys read by the sample are:
- `CheckoutPublicKey`
- `CheckoutSecretKey`
- `CheckoutBaseURL`

## Notes

- The sample app creates the SDK module when the checkout host view resolves its state.
- The SDK itself supports a longer-lived shared module, but this demo keeps the setup close to the flow entry point.
- The final result message is shown in the root view after the sheet dismissal callback runs.
