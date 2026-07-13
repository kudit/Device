# Inspecting the Current Device

Read live hardware and operating-system information from the device running your app.

## Overview

``Device/current`` exposes the singleton that represents the current hardware. Because live device APIs interact with platform frameworks and observable state, access it from the main actor:

```swift
import Device

@MainActor
func describeCurrentDevice() {
    let current = Device.current

    print(current.officialName)
    print(current.systemInfo)
    print(current.thermalState)
}
```

The current device combines the static hardware catalog with values supplied by the operating system. Some values are optional because a platform may not expose them or the current model may not contain the relevant hardware.

## Battery and Storage

Check for a battery before reading battery information:

```swift
@MainActor
func reportPower() {
    guard let battery = Device.current.battery else {
        return
    }

    print(battery.currentLevel)
    print(battery.currentState)
}
```

Macs running an iPad app in Designed for iPad mode intentionally report battery information as unavailable. The iOS compatibility layer can otherwise expose a misleading value that does not describe the host Mac's battery.

Storage properties such as `volumeAvailableCapacity` are also optional. Treat `nil` as unavailable rather than as zero capacity.

## Present Device Information

Device includes SwiftUI views for diagnostics and support interfaces:

```swift
import Device
import SwiftUI

struct DiagnosticsView: View {
    var body: some View {
        CurrentDeviceInfoView(
            device: Device.current,
            includeStorage: true
        )
    }
}
```

Use ``DeviceInfoView`` to present catalog information for a specific ``Device`` that is not necessarily the current hardware.
