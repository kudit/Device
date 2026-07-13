# Understanding Build Environments

Use Compatibility's `Build` checks for process context and Device for hardware characteristics.

## Overview

A simulator, preview, or Swift Playgrounds session is a property of the running process—not a capability of an iPhone, Mac, or mock device. Device therefore uses the `Build` API provided by its Compatibility dependency as the canonical source for environment detection:

```swift
import Device

if Build.isSimulator {
    // Substitute data that requires unavailable simulator hardware.
}

if Build.isPreview {
    // Supply stable content to an actual preview session.
}

let activeEnvironments = Build.environments()
```

Available checks include simulator, Swift Playgrounds, preview, real hardware, Mac Catalyst, Designed for iPad, debugging, testing, and application or command-line execution.

## Migrate Legacy Device Checks

Older versions exposed environment checks through `Device` and ``CurrentDevice``. Those wrappers remain deprecated for source compatibility:

```swift
// Deprecated compatibility spelling:
let wasPreview = Device.isPreview

// Preferred spelling:
let isPreview = Build.isPreview
```

New code should use `Build` directly. Mock devices intentionally do not carry artificial environment flags, so displaying a mock model never changes the environments reported for the running process.
