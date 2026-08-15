# Cesium example

This example is a minimal Flutter app demonstrating how to use the `cesium` package's
`HttpResource` to fetch and display a list of items.

Run the example from the repository root:

```bash
cd example
flutter pub get
flutter run
```

The app fetches a small sample list from `https://api.sampleapis.com/coffee/hot` and
shows how to reload and display results using a `ValueListenableBuilder`.
