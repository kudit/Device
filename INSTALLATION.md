# Installation

## Swift Package Manager

Swift Package Manager is the recommended installation method.

```swift
dependencies: [
    .package(url: "https://github.com/kudit/Device.git", from: "2.0.0"),
]
```

Then add the package product to your app target in Xcode or Swift Playgrounds and import the module:

```swift
import Device
```

## Manual installation

Manual installation is possible, but Swift Package Manager is strongly preferred because `Device` depends on the companion `Color` package and includes resources.

To install manually:

1. Add this repository to your project or workspace.
2. Add the `Sources` directory to a framework target named `Device`.
3. Add the resources in `Sources/Resources` to that target.
4. Add the `Color` package dependency from `https://github.com/kudit/Color`.
5. Link the resulting `Device` framework to your app target.

For most projects, adding the package through Xcode's **File > Add Package Dependencies…** flow is less error-prone than manually wiring the target, resources, and dependency.

## CocoaPods

CocoaPods installation is not currently published for this package. A future `Device.podspec` should include:

- the `Sources/**/*.swift` source files,
- the resources under `Sources/Resources`,
- platform deployment targets matching `Package.swift`, and
- the `Color` dependency.

Until a podspec is added and published, use Swift Package Manager.

## Carthage

Carthage installation is not currently supported. This repository is primarily a Swift Package and does not currently include a shared Xcode framework scheme intended for Carthage builds.

Until a Carthage-compatible project or scheme is added, use Swift Package Manager.
