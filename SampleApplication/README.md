# Sample App

This app is a minimal demo for the `CheckoutFlow` SDK.

It exists only to show a basic SDK integration:

- read Checkout sandbox configuration from local xcconfig values
- initialize `CheckoutFlowModule`
- present `CheckoutFlowView`
- display the final checkout result when the flow finishes

## What it is for

Use this app to:

- verify the SDK builds correctly
- test the checkout flow manually
- see a simple SwiftUI integration example

It is not intended to be production-ready.

## Run the demo

1. Open `SampleApplication/SampleApplication.xcodeproj`.
2. Update `SampleApplication/SampleApplication/Configuration/Secrets.local.xcconfig` with your Checkout sandbox keys.
3. Run the app on an iPhone simulator.
4. Tap **Start Checkout**.

## Configuration

The sample app reads these values from the app configuration:

- `CheckoutPublicKey`
- `CheckoutSecretKey`
- `CheckoutBaseURL`

These values are exposed through `Info.plist` and used to build `CheckoutFlowConfiguration`.

## Notes

- The sample presents the SDK inside a sheet.
- When the sheet is dismissed, the app shows the final result message.
- The payment values used by the demo are hardcoded in `CheckoutFlowSetup.swift`.
