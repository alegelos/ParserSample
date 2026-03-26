# SampleApplication

## Local sandbox configuration

1. Open `SampleApplication/Configuration/Secrets.local.xcconfig`.
2. Replace the placeholder values with your Checkout sandbox keys.
3. Build and run the sample app.

The sample app reads the values from xcconfig, exposes them through the generated Info.plist, and injects them into `CheckoutFlowModule.create(...)`.

Only `Secrets.example.xcconfig` is meant to be committed.
`Secrets.local.xcconfig` is ignored by Git.
