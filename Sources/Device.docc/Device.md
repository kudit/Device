# Device

Identify Apple hardware and describe its capabilities through one consistent, cross-platform Swift API.

## Overview

Device provides a maintained catalog of Apple hardware together with APIs for identifying the current device, looking up other devices by identifier or product name, inspecting hardware capabilities, monitoring battery information, and presenting device details with SwiftUI.

Use ``Device`` when you need stable model information such as an official product name, idiom, processor, colors, cellular generation, screen characteristics, or supported capabilities. Use ``CurrentDevice`` when you need information supplied by the device that is running your code, such as its system version, battery, brightness, thermal state, or available storage.

Device uses the Compatibility package's `Build` API for process environments such as simulator, Swift Playgrounds, previews, Mac Catalyst, and Designed for iPad. This keeps build context separate from the hardware model being described.

## Topics

### Essentials

- <doc:IdentifyingDevices>
- <doc:InspectingTheCurrentDevice>
- <doc:UnderstandingBuildEnvironments>

### Device Models

- ``DeviceType``
- ``Capability``
- ``Cellular``
- ``Screen``

### Live Device Information

- ``CurrentDevice``
- ``Battery``
- ``BatteryState``
- ``ThermalState``

### SwiftUI

- ``DeviceInfoView``
- ``CurrentDeviceInfoView``
- ``BatteryView``
