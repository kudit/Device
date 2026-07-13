# Identifying Devices

Look up an Apple device and query the capabilities recorded in Device's hardware catalog.

## Overview

Create a ``Device`` with a model identifier when the operating system or another data source provides one:

```swift
import Device

let phone = Device(identifier: "iPhone16,1")

print(phone.officialName)
print(phone.cpu)
print(phone.colors)
```

Unknown identifiers still produce a usable value. This lets an app retain and display an identifier introduced after the version of Device bundled with the app instead of failing the lookup.

## Search by Product Name

Use ``Device/lookup(officialNameHint:)`` when a support page, import, or user-facing source provides a product name rather than an identifier:

```swift
let matches = Device.lookup(
    officialNameHint: "Apple Watch Series 10 (GPS + Cellular) 42mm"
)

if let watch = matches.first {
    print(watch.identifiers)
}
```

Lookup returns an ordered array because product names can be incomplete or shared by regional and hardware variants. Prefer an exact identifier whenever one is available.

## Query Capabilities

Use ``Device/has(_:)`` to ask whether a model supports a ``Capability``:

```swift
let device = Device(identifier: "iPhone16,1")

if device.has(.gps) {
    // Enable a feature whose hardware requirement is GPS.
}

if device.cellular == .fiveG {
    // Describe the device as supporting 5G cellular service.
}
```

Capability data describes the hardware model. Availability of an operating-system API can have additional requirements, so continue to use Swift availability checks where the API itself requires them.
