<img src="/Development/Resources/Assets.xcassets/AppIcon.appiconset/Icon%20Design.1024.png" height="128">

# Device.swiftpm
Device is a value-type replacement for device information on all supported platforms.  The primary goals are to be easily maintainable by multiple individuals and employ a consistent API that can be used across platforms.  APIs are present even on platforms that don't support all features so that availability checks do not have to be performed in external code and where irrelevant, code can simply unwrap optionals.  Device definitions include clear initializers so anyone can add new devices and contribute to the project even on an iPad using Swift Playgrounds rather than requiring Xcode.  No need to memorize mapping schema or use additional build tools.

This is actively maintained so if there is a feature request or change, we will strive to address within a week.

## Features

- [x] Clearly labeled device identification
- [x] Device idiom detection
- [x] Simulator detection
- [x] Playground detection
- [x] Preview detection
- [x] Various device metrics (e.g. screen size, screen ratio, PPI)
- [x] Battery state
- [x] Battery level
- [x] Battery symbol
- [x] Battery color
- [x] BatteryView
- [x] Low Power Mode detection
- [x] Guided Access Session detection
- [x] Screen brightness
- [x] Display Zoom detection
- [x] Detect available sensors (Touch ID, Face ID, Optic ID)
- [x] Detect available disk space
- [x] Apple Pencil support detection
- [x] Images and support links

## Requirements

- iOS 15.2+ (minimum required for Swift Playgrounds support)
- tvOS 14.0+
- watchOS 6.0+
- macOS 11.0+
- macCatalyst 14.0+
- visionOS 1.0+

## Known Issues
Built for macOS "Designed for iPad" does not return expected device results.
Xcode previews do not work when the preview device is set to "My Mac (Mac Catalyst)".
Custom Symbols likely won't work in macOS < 13.
LowPowerMode checks unavailable in macOS < 12.

## Installation
Install by adding this as a package dependency to your code.  This can be done in Xcode or Swift Playgrounds!

### Swift Package Manager

#### Swift 5
```swift
dependencies: [
    .package(url: "https://github.com/kudit/Device.git", from: "2.0.0"),
    /// ...
]
```

You can try these examples in a Swift Playground by adding package: https://github.com/kudit/Device

## Usage
First make sure to import the framework:
```swift
import Device
```

Here are some usage examples.

### Get the device You're Running On
```swift
let device = Device.current

print(device) // prints, for example, "iPhone 6 Plus"

if device.has(.force3dTouch) {
    // do something that needs force-touch.
} else {
    // fallback for devices that do not support this.
}

if device.is(.plus) || device.is(.max) {
    // do something only available for "Plus" model devices.
}

if device.has(.battery) && device.has(.lidar) && device.has(.headphoneJack) {
    // do something only if there is a battery, lidar, and a headphoneJack
}
```
Get the full list of flags that can be queried for under the enum Capability in Hardware.swift.

### Get the device idiom
```swift
let device = Device.current
if device.idiom == .pad {
  // iPad
} else if device.idiom == .phone {
  // iPhone
} else if device.idiom == .vision {
  // Apple Vision device
}
```

### Check if running in a Simulator
```swift
if Device.current.isSimulator {
  // Running on one of the simulators
  // Skip doing something irrelevant for Simulator
} 
```

### Check if running in a Preview
```swift
if Device.current.isPreview {
  // Running in an XCode #Preview
} 
```

### Check if running in a Playground
```swift
if Device.current.isPlayground {
  // Running in an XCode #Preview
} 
```

### Check if running on a physical device
```swift
if Device.current.isRealDevice {
  // Running on physical hardware and not a simulator
} 
```

### Get the Current Battery State
**Note:**

> When getting the current battery state, battery monitoring enabled will be temporarily set to true and then restored to whatever it was beforehand, so no need to manage monitoring separately.  If you need to be notified when the battery state or level changes, you can add a monitor that will call your code whenever the level changes.  However, typically this can just be dropped in as the DeviceBattery is an ObservableObject.

```swift


if let battery = Device.current.battery {
    // do things that need the battery
    if battery.currentState == .full || (battery.currentState == .charging && battery.currentLevel >= 75) {
        print("Your battery is happy! 😊")
    }
    
    // get the current battery level
    if battery.currentLevel >= 50 {
        install_iOS()
    } else {
        showLowBatteryWarning()
    }

    if battery.lowPowerMode {
        print("Low Power mode is enabled! 🔋")
    } else {
        print("Low Power mode is disabled! 😊")
    }

    // add monitor to do something whenever battery level changes (like updating UI)
    battery.addMonitor {
        localBatteryLevel = battery.currentLevel
        localBatteryState = battery.currentState
    }
} else {
    // handle behaviour on devices without a battery
}
```

### Get the Current Battery Level
```swift
if let level = Device.current.battery?.currentLevel, level >= 50 {
  install_iOS()
} else {
  showError()
}
```

### Check if a Guided Access session is currently active
```swift
if Device.current.isGuidedAccessSessionActive {
  print("Guided Access session is currently active")
} else {
  print("No Guided Access session is currently active")
}
```

### Get Screen Brightness
```swift
if Device.current.screenBrightness > 50 {
  print("Take care of your eyes!")
}
```

### Get Available Disk Space
```swift
if Device.current.volumeAvailableCapacityForOpportunisticUsage ?? 0 > Int64(1_000_000) {
  // download that nice-to-have huge file
}

if Device.current.volumeAvailableCapacityForImportantUsage ?? 0 > Int64(1_000) {
  // download that file you really need
}
```

## Source of Information
Some information has been sourced from the following:
https://www.theiphonewiki.com/wiki/Models
https://www.everymac.com
https://github.com/devicekit/DeviceKit

## Contributing
If you have the need for a specific feature that you want implemented or if you experienced a bug, please open an issue.
If you extended the functionality of Device yourself and want others to use it too, please submit a pull request.

## Contributors
The complete list of people who contributed to this project is available [here](https://github.com/device/Device/graphs/contributors).
A big thanks to everyone who has contributed! 🙏
