# ChangeLog

NOTE: Version needs to be updated in the following places:
- [ ] Xcode project version (in build settings - normal and watch targets should inherit)
- [ ] Package.swift iOSApplication product displayVersion.
- [ ] Device.version constant (must be hard coded since inaccessible in code)
- [ ] Update changelog and tag with matching version in GitHub.

Tests:
Playgrounds Preview Mac
Playgrounds Preview iPad
Preview Xcode (only in Xcode project in app not framework)
Playgrounds App Mac
Playgrounds App iPad
Simulator visionOS
Simulator visionOS (for iPad)
Simulator iPhone 15 Pro
Simulator Apple Watch
Simulator Apple TV
Real Device macOS
Real Device macOS (catalyst)
Real Device macOS (for iPad)
Real Device iPad
Real Device iPhone
Real Device Apple Watch
Real Device Apple TV

v2.3.4 7/19/2024 Added Identifiable to Battery protocol which I think works because ObservableObject requires AnyObject.  Added details for battery tests so that description can be seen and small screens can see all details.  Moved fontSize off of individual views in batteryView in preparation for extracting size entirely so can use sizes externally without having to specify font size (unfortunately, still can't due to not being able to specify relative sizes compared to base, but at least we cleaned up the code some).  Fixed so setting low power mode doesn't cause view to publish changes while rendering.

v2.3.3 7/17/2024 Updated to make sure ObservableObject fallback is present from compatibility when needed for Linux compatibility.  Re-worked environment checks so they can be called as static functions on Device that don't need to be actor-isolated.  This also has the benefit of providing DeviceKit compatibility and thus we have un-deprecated those static functions.  Removed several unused functions and moved some to Compatibility.  Set minimum Compatibility version to 1.0.18. 

v2.3.2 7/15/2024 Updated compatibility to fix linux and watchOS support.  Updated icons to use new themeing.  Improved ScreenInfoView on visionOS (and removed completely from DeviceInfoView since really irrelevant on visionOS).

v2.3.1 7/14/2024 Decided not to @_exported Compatibility here.  Removed duplicative EdgeInsets.zero.  Updated Compatibility inclusion.  Added compatibility version to text description and test app.  Migrated BytesView to Compatibility.

v2.3.0 7/11/2024 Re-worked so that now depends on Compatibility rather than including duplicate compatibility code in the framework.  Increased legacy support back to iOS 11 and watchOS 4 to match DeviceKit (without SwiftUI or CurrentDevice features since CurrentDevice requires ObservableObject to be supported...perhaps create stateless wrappers?).  Fixed so that Swift Playgrounds works even when package supports an older iOS version.  If someone needs this, let us know otherwise we'll assume it's not important for legacy projects.

v2.2.2 7/4/2024 Fixed issue where Linux build was failing and some additional concurrency warnings.

v2.2.1 7/4/2024 Added Sendable conformance to IdiomType by making structs immutable and thus easily sendable.  Moved Migration out of Device framework so not included in client code.  Fixed some additional methods to be public that were not.  Added additional contrast to Device idiom icons.

v2.2 7/4/2024 Removed CustomStringConvertible conformance from Device since we want to have CurrentDevice implement this (so we can have for both Mocks as well as ActualDevice) and we don't want confusion between the two implementations.  Fixed identifiability of mocks.  Added Version.swift and additional extensions on OperatingSystemVersion for better output and compatibility of version information on ALL devices.  Added hostSystemVersion and hostSystemName for macCatalyst and Designed for iPad and Linux systems.  Changed version returns from string to OperatingSystemVersion (or Version structs).  Added compatibility so that old uses should work without changing code (though if you store in typed variables that were previously strings, this may require code updates).  Removed `Device.description` and `Device.safeDescription` to prevent conflicts with `CurrentDevice.description` since CurrentDevice inherits from DeviceType.  Renamed to `safeOfficialName` for clarity and deprecated `safeDescription`.  Added macOS system name hard-coded component lookup for better system software info display.  Removed green background on visionOS.  Fixed `isDesignedForiPad` code on visionOS.  Fixed SomeCurrentDeviceView by making the device an @ObservedObject.

v2.1.19 7/3/2024 Ensured CurrentDevice objects are @MainActor isolated so can be used in concurrent code.

v2.1.18 7/3/2024 Converted several static variables from `var` to `let` for clarity.  Added availability check for renamed API from kIOMasterPortDefault to kIOMainPortDefault.

v2.1.17 6/19/2024 Updated code to enble strict concurrency checking.  Changed several constants to lets to make clear they won't change.  Made ActualHardwareDevice and MockDevice final.  Made public enums conform to Sendable since they do not by default.  Ignored enableMonitoring functionality on MockDevice since not used.  Set up for creating tests using Swift Testing.

v2.1.16 6/3/2024 Removed code for Swift 5.7 & 5.8 since conditional code in the Package.swift file doesn't seem to work.

v2.1.15 6/3/2024 Separated out legacy symbols so could exclude new templates for Swift 5.7 & 5.8.  Added exposition of Swift version number.  Replaced CGFloat values in framework with Double since toll-free bridged and CGFloat is less swifty...  Now including note when low power mode is active in battery description.  Added  Pencil names.

v2.1.14 6/2/2024 Fixed so that MockBattery and MockDevice are visible in Linux.

v2.1.13 6/1/2024 Fixed issues with tvOS and tap gesture recognizer not being available.  Added several @Published and notification checks for things that aren't available on Linux.  Changed alignment of "Total Capacity:" label so it's not floating by itself.  Created constant for `devicePanelRadius` for consistency.  Fixed issue with PreferenceKey monitoring and changed to onAppear and onChange modifiers which is simpler and works better.

v2.1.12 6/1/2024 Re-worked so MonitoredDeviceBattery is not required by Linux.

v2.1.11 6/1/2024 Completely re-worked Storage view to be more compact and expand for more information.

v2.1.10 5/31/2024 Forgot to update versions!  Also added legacy symbol for screen size.

v2.1.9 5/31/2024 Fails Linux test (fixed?).  Need a better way of testing on linux.  Added better information for new iPads.  Fixed bug where screen wasn't included on device detail view.  Added information on esim/dual esim capability.  Re-ordered some iPads so they are chronological.  Added full UIDeviceOrientation value set for Screen.Orientation to be more accurate and not lose information.
b - compiler errors buildling for release
v2.1.8 5/31/2024 Fixed project so only one version check is needed not per target.  Set Swift version minimum to 5.9 since that's needed for #Preview {} functionality.  Added additional checks to allow compiling on Linux.  Added dummy ObservableObject protocol when Combine isn't available.  Removed now unnecessary MonitoredBatteryView and simplified API to just BatteryView() for simplicity and clarity.  Fixed thermal layout.  Fixed issue with enabledMonitoring frequency was ignored (and potentially generating many many timers that could cause memory leak).  Moved MockDevice to bottom to make it easier to find mocks.  Fixed error introduced in v2.1.0 where battery.slash.legacy was exported with SF Symbols 5 instead of 2 and thus crashed on devices and previews < iOS 17.
g - no compiler errors buildling for release
v2.1.7 5/25/2024 Added Thunderbolt capability.  Added new iPads.  Re-worked package for better compatibility with swiftpackageindex.com platforms.  Added checks for SwiftUI for compilation compatibilty.  Added support for swift 5.7.

v2.1.6 5/13/2024 Fixed 4 cases where iPod touch was listed as "iPhone touch".  Updated README with better feature list.  Re-worked Package.swift to be cleaner and support `swift package dump-package` for swiftpackageindex.com and enhanced for code re-use.  Added small caps to the processor views.  Fixed so Mac (non-catalyst) shows full description in text editor to make it easier to see everything and select text.  Allowed searching by processor.

v2.1.5 5/7/2024 Added spaces to changelog to improve formatting in github.  Added notifications when changing orientation and brightness.  Removed brightness from macCatalyst and macOS since it doesn't appear to work.  Change icon to Icon.png instead of Icon%20Design.1024.png.  Added CPU to the SystemInfoView.  Added search to the device list tool.  Updated iPad Pro 6th gen images.

v2.1.4 4/29/2024 Added `v` to version in description.  Added some separation between SystemInfo view (and removed unused ZStack wrapper).  Added back text description to HardwareView to ensure testing (refreshes when toggling to ensure that the text is updated to current which is further helpful for debugging).  Added environment information to description.  Removed redundant battery description code.

v2.1.3 4/22/2024 Moved Environments view in CurrentDeviceInfoView.

v2.1.2 4/21/2024 Updating version numbers.  Updating Environments to be centered and visible in tests.  Updated Backport and other UI functions that should be version-restricted.  Tested Apple Watch version (missed in 2.1 testing).  Fixed issue with storage Ints being too small (so specified Int64).  Fixed updates for macCatalyst.

v2.1.1 4/21/2024 Updated to enable showing environments in CurrentDeviceInfoView.

v2.1.0 4/20/2024 Updated ChangeLog location and formatting.  Added CurrentDeviceInfoView.  Added Device.Environment enum to represent the various environment states so they can be included in the hardware list.  Created a CurrentDeviceInfoView.  Added better description for debugging and inclusion in external data.  Changed DeviceType.name to officialName to differentiate from the user's specified name and maintain compatibility with DeviceKit syntax.  Improved symbols and added modern and legacy symbols for hierarchical display.  Changed so battery status can be compared in macOS.  Included resource processing in the test app so can test using Swift Playgrounds.  Changed so battery monitors can access the type of change that was detected.  Batteries now store a local value and will automatically monitor for changes so that UI can update without adding a separate monitor.  Reworked naming of monitor to be clearer when using just the closure.  Removed the `Battery.add(monitor)` function in favor of a new `Battery.monitor` function that provides the update type when triggered.  I don't think anyone was using this so this shouldn't be a breaking change and is easy to fix.  Increased macOS requirement to 12 (too many issues where foregroundStyle isn't supported.)  Reworked BatteryTestsView to enable toggling lowPowerMode and includesBacking parameter to enable transparency.  Added several backport compabilitiy functions to simplify code for older versions. Had to remove UI compatibility for watchOS < 8 due to too many compatibility issues.  Reordered CurrentDevice properties to be better grouped.  Added isMacCatalyst environment check.  Created monitored views to take any Battery or any CurrentDevice and update as the device or battery updates.  For battery test views, added a toggle for low power mode to change mocks.

v2.0.10 4/12/2024 Fixed so previews work in Xcode for Development files (previews will not work within the project Sources in Xcode but all previews work in Swift Playgrounds).  Updated minimum requirments in Xcode project.  Updated Device version in both targets and package.  Simplified description.  Fixed so name, localizedSystemName, etc. are non-optional.  Deprecated Device.identifier (use Device.current.identifier).  Added Device.version constant for referencing version (will need to manually update on version changes unfortunately).

v2.0.9 4/11/2024 Fixed issue with watchOS not being able to disable idle timer.

v2.0.8 4/10/2024 Updated license copyright.  Added ability to disable screen dimming/locking (and ability to monitor battery state to disable idle timer automatically when plugged in).  Added battery.isPluggedIn variable.  Fixed so that a battery monitor is triggered regardless of battery level or battery state changes.

v2.0.7 4/7/2024 Added Watch7,2 and several other missing device identifiers.  Made Migration.migrate() public so accessible from test view.  Wanted to move to development folder but would have required too much private internal access.  Re-added the Device.swiftpm to the Xcode project so it's not labeled DeviceTest.  Added lightning to all iPhones that don't have USB-C.

v2.0.6 4/6/2024 Re-worked resources so that custom symbols are accessable outside module.  Fixed so macOS reports actual identifier (wasn't able to get identifier before).

v2.0.5 4/3/2024 Fixed so works on macOS.  Fixed so works in Swift Playgrounds (had to bring minimum iOS level up to 15.2).  Renamed projects in Package.swift to fix so previews load consistently in Swift Playgrounds and Xcode previews.

v2.0.4 4/2/2024 Renamed project from DeviceTest to Device.  Fixed so supported on tvOS 14.  Added crash detection to newest Apple Watch models.  Backed minimum iOS version to iOS 14.  Changed watchOS minimum to 6.  Updated minimum deployment targets in README.  Added fallbacks for some iOS 15+ only features.

v2.0.3 4/2/2024 Made screen size resolution width and height public.  Removed HardwareListView from Hardware.swift to prevent issues with integrations.

v2.0.2 3/31/2024 Fixed so can run test app on iOS 15/16.  Added custom symbols for nicer UI and to make sure icons work on older iOS devices.  Added NFC, ApplePay, Barometer, and Ringer Switch to iPhones where missing.  Improved the display of the test view.

v2.0.1 3/31/2024 Fixed version warning with String.split() not available on iOS < 16.  Improved package definition with annotations.  Added public initializers for Device views.  Fixed compatibility and buildling for iOS < 16 in test views.  Updated Readme to highlight the new syntax.

v2.0.0 3/27/2024 Re-worked so there are capabilities rather than fixed parameters to make it easier to add features going forward.  Also created Migration code to convert old-format definitions into the new ones (allowing us to easily add definitions from other lists like older Macs).  Removed idiomProperties in favor of consistent capabilities.  Made Placard view apply stroke after fill so that it looks better.  Made supportId optional in most definitions to make it easier to address missing values.  Created function for reducing resolution into a ratio.  Reverted screenRatio legacy function to match DeviceKit implementation.  Added .air model tag.  Added MaterialColors to preserve color model information and allow coloring devices.  Made all hardware hashable so that Device could be Hashable for easy use in ForEach functions.  Added mac devices from https://github.com/voyager-software/MacLookup/blob/master/Sources/MacLookup/Resources/all-macs.json (thank you!).  Added symbol names for capabilities.  Added DeviceInfoView for testing and presentation.

v1.1.2 3/21/2024 Fixed problem where rounded display corners was left in the vision definition.  Preparing for re-write of the capabilities engine.

v1.1.1 3/20/2024 Fixed so readme icon works again due to moved assets to Resources folder.  Added isApplePencilCapable flag for iPads.  Removed legacy unused screen attributes (should add those back in under capabilities once we switch models in v2).

v1.1.0 3/20/2024 Added symbols for device idiom icons and various build modes.  Fixed TestView Any to String conversion issue.  Added dynamicIsland configuration parameter.  Added in missing iPhone 14 Pro Max and updated several screen sizes and some wrong support IDs.  Added isMini flag for HomePods.  Added Mac forms. Created test for (Designed for iPad) mode vs native mode.  Added XCode test project so that we can build on visionOS and tvOS and watchOS and various mac targets.  visionOS (Designed for iPad) properly reports the new isDesignedForiPad flag when using a compatibility app.  Added scroll view so visible on watchOS or in iPhone landscape.  Added tvOS, visionOS, macOS, and watchOS icons.

v1.0.11 3/11/2024 Fixed BatteryView to make sure it updates when DeviceBattery updates.  Fixed so macOS reports charging instead of full when charging.

v1.0.10 3/11/2024 Updated documentation.  Changed phone test color to red since gray is not very obvious.  Re-worked BatteryView so that it can be scaled.

v1.0.9 3/11/2024 Fixed so that BatteryView actually uses the initialization parameters (formerly, would not because they were marked @State).

v1.0.8 3/9/2024 Updated Battery to be protocol instead of just a class so that it can be Mocked.  Added Mocks.  Added BatteryView for displaying battery indicator.

v1.0.7 3/9/2024 Removed accidentally left in debugging code.

v1.0.6 3/8/2024 Replaced checks for OSes with canImport(UIKit).  Added some code so battery level works on macOS Catalyst.  Updated readme to indicate macOS support.  Updated Description of Current Device.  Fixed so identifier works correctly in macCatalyst.

v1.0.5 3/8/2024 Fixed so name that appears in Package List is Device not DeviceTestApp.

v1.0.4 3/8/2024 Fixed so UIDevice is available on visionOS (UIKit wasn't being included on that platform.)

v1.0.3 3/8/2024 Tested for compatibility.  Updated Readme.  Fixed so previews work.  Added Test code.

v1.0.2 3/5/2024 Re-worked so Disk functions are available even before iOS 11 by moving availability checks into functions.

v1.0.1 2/28/2024 Heath's additions and re-working code for IdiomType so that we can subclass and have device initializers while still being value types.

v1.0.0 2/16/2024 Initial Project based off of DeviceKit but designed to be more maintainable and compatible.

## Bugs to fix:
Known issues that need to be addressed.

- [ ] Main-actor isolated warning on .current in CurrentDevice.swift (assuming Device.current but could be UIDevice.current) and this only happens in Swift Playgrounds.
- [ ] Screen view on visionOS text should be black not background since more contrasty and no dark mode.
- [ ] Must be built for debug instead of release configuration when archiving/analyzing due to issue: errors linking for release like "Undefined symbols for architecture arm64:
  "protocol conformance descriptor for Device.ActualHardwareDevice : Device.CurrentDevice in Device" and "type metadata accessor for Device.ActualHardwareDevice".  (Removed checks for #if canImport(Combine) around various classes and that helped some but didn't completely fix.) - possibly issue building against macOS 11?  Possible other #combine check?  Apple Forum Description: https://developer.apple.com/forums/thread/758168?login=true
- [ ] Device fix so brightness and battery update immediately (seems to be working on iOS and visionOS, but not on macOS.)
- [ ] Designed for iPad running on macOS has all appearance of being an actual iPad and battery status seems incorrect.  Need help on this edge case (or use macCatalyst or macOS development).  Building from Playground (not using Xcode project), Designed for iPad doesn't report properly but identifier is correct (systemName reports iPadOS) - same when buildling for Mac Catalyst.  Buildling from the Xcode project Designed for iPad does propertly report isDesignedForiPad but the battery indicator and device is wrong.  Buildling for Mac Catalyst does propertly report device and battery.
- [ ] Retain error on device list scrolling quickly to the bottom on watchOS (simulator and device). Figure out why the all devices list crashes on Apple Watch (simulator and actual device scrolling down to the bottom).
        Info.plist contained no UIScene configuration dictionary (looking for configuration named "Default Configuration")
        ScrollView contentOffset binding has been read; this will cause grossly inefficient view performance as the ScrollView's content will be updated whenever its contentOffset changes. Read the contentOffset binding in a view that is not parented between the creator of the binding and the ScrollView to avoid this.
        Crown Sequencer was set up without a view property. This will inevitably lead to incorrect crown indicator states
        overrelease of detent assertion detected
- [ ] Odd warning: Device.swiftpm/Sources/Resources/SymbolAssets.xcassets: Could not get trait set for device Watch7,2 with version 10.4

## Roadmap:
Planned features and anticipated API changes.  If you want to contribute, this is a great place to start.

- [ ] Create a macOS codename lookup tool (put in number and it should show the codename) in search, or just list all the codenamed systems in reverse order.
- [ ] Device Test: Have a Way of specifying a narrow layout for Apple Watch and iPhone 7 where the thermal section should be separate and wrap rather than HStack.  Improve layout for watchOS.  Make sure description text is visible and scrollable.
- [ ] Device Test: Improve layout and UI in tvOS. (Optimize)
- [ ] Device: Create live activity for battery and screen orientation as example code.
- [ ] Go through and make sure device images (photos) have transparent background instead of white.
- [ ] Add support IDs for macs and anything that has one missing.
- [ ] Double check and update all device color sets. (right click on the color swatches and inspect element for the hex code)  https://www.apple.com/iphone/compare/?modelList=iphone-13-mini,iphone-13,iphone-15-pro
- [ ] Add weight option for battery text/symbol (title originally was bold and now that we're doing font size, add weight parameter)
- [ ] Add new devices (ongoing).
- [ ] Device: Add ability to tap on section headings to collapse (for device list view - default to all collapsed?) auto scroll to current device row?
- [ ] Device: Add code to put PPI in visual range dial like health app (using SwiftCharts if available).
- [ ] Figure out how to query brightness on macOS/macCatalyst (UIScreen.main.brightness does not appear to work).
- [ ] Allow battery symbol view to be different weights.  Have inherit/track with font weights using size relative to.
- [ ] Improve test app user interface/layout.
- [ ] Add tests to complete code coverage.
- [ ] Create tests in such a way that they can be run in Previews and in the example App (may require a project dependency).
- [ ] Device: Have capabilities list slider and toggle be stuck to top of screen when scrolling.
- [ ] Re-work so custom symbols are image constants rather than using strings which may be unavailable (perhaps use with symbol enum package?)
- [ ] See if there's a way to automate tests on various platform combinations.
- [ ] Support landscape on iPhone for test view and use size classes to re-layout.
- [ ] Add a variable for interfaceOrientation (separate from device orientation) that indicates the UI paradigm (portrait or landscape) and when the device switches to face up/down and doesn't rotate, should still report the current value (last known value).  Should report landscape in mac, vision, and tv devices, landscape by default in iPads, portrait by default in iPhone and watch.
- [ ] Create replacement for rounded display corners since faceID is a good proxy but misses modern touchID power button iPads.  Have as capability.
- [ ] Add way of getting battery cycle count and health? https://stackoverflow.com/questions/34571222/get-battery-percentage-on-mac-in-swift
- [ ] Add additional notification monitors that can be subscribed to:
        UIDevice.orientationDidChangeNotification
        UIDevice.proximityStateDidChangeNotification
        NSBundleResourceRequestLowDiskSpace
        NSSystemClockDidChange // A notification posted whenever the system clock is changed.
        NSSystemTimeZoneDidChange // A notification posted when the time zone changes.
        NSProcessInfoPowerStateDidChange // Posts when the power state of a device changes. (isLowPowerModeEnabled)
        thermalStateDidChangeNotification
        ProcessInfo.thermalState
- [ ] Look into creating bar for screen resolution PPI to indicate if it's high resolution or not.  Have area indicated that is considered "retina" - have bar as a conditional presentation if SwiftCharts is available.
- [ ] Add supported versions to indicate the iOS/macOS/etc versions supported by each device.

## Proposals:
This is where proposals can be discussed for potential movement to the roadmap.

- [ ] Create state-less wrappers for CurrentDevice inspection so not dependent on observable object and can provide legacy support?  If ObservableObject available, then create an observable CurrentDevice that can be monitoried for changes?
- [ ] See if there's a way to get visionOS version when designed for iPad mode.  This claims to do the right thing but verified it also doesn't work for visionOS (Designed for iPad): https://swiftpackageindex.com/MarcoEidinger/OSInfo
- [ ] Move privacy manifest to the package sources resources folder so it gets processed? https://github.com/devicekit/DeviceKit/issues/408#event-12991784329
- [ ] Do we need to have a way of tearing down a battery monitor when a monitor host disappears?  Not as relevant now that we're auto-monitoring with an observable object.
- [ ] Find a way to make words WATCH and SERIES appear in smallCaps() text field and make Apple be Apple logo character  in official names?
- [ ] For more example code, Make widget for Device tests for Home Screen view and live activity (battery monitor?) Lock Screen widget?
- [ ] Add easy way to capture screenshots of entire view (have `.screenshottable()` view modifier and then Device.current.captureScreenshot() -> Image that can be attached or exported or whatevered.)
- [ ] Add hook for monitoring when screenshot is taken. `Device.current.monitorForScreenshot { image in } 
- [ ] Create better way of scaling battery so that it can scale with dynamic type?  Use relative type?
- [ ] Add a way to check that privacy checks have been added when using APIs that need privacy permissions (have a configuration flag that needs to be set to ensure that privacy flags have been set).
- [ ] Convert SF Symbol names to an enum to allow version checking?  May need to use other project.
- [ ] If there's a way to fetch the actual model number (like MN572LL/A), then we can use this to give information of the state of the device (new, refurb, replaced, personalized, etc): https://osxdaily.com/2018/01/27/determine-iphone-new-refurbished-replaced/
- [ ] Should forceTouch and touch3d be separated?  Discuss in issues or here.
- [ ] Add volume controls and power button and home button capabilities?  Possibly with rumored camera button?
- [ ] Add orientation and brightness to current device description?
- [ ] Device: have code to make battery monitor dimmed and grayed out if App switches or goes to sleep so the wind coming back it doesn't show misinformation”.  Test with iPhone.  Maybe shouldn’t happen because would be problematic with visionOS?
- [ ] Getting Computer Information (must give reason since can be used for fingerprinting so not included currently):
var processorCount: Int
var activeProcessorCount: Int
var physicalMemory: UInt64
var systemUptime: TimeInterval

- [ ] Model off of Swift Algorithms project.
- [ ] See if anything in Swift Algorithm replaces Kudit or Device collection extensions.

Note: If get `protocol conformance descriptor for` error, this is how to fix:
Still waiting for reply to Apple discussions thread: 
https://developer.apple.com/forums/thread/758168?login=true  

Note: If Swift Playgrounds crashes saying the module Device_Device can't be built, it's probably a bad cache build.  Delete/rename the following: ~/Library/Containers/com.apple.PlaygroundsMac/Data/Library/Caches/com.apple.PlaygroundsMac
Possibly because Bundle.module may not exist???  removed call to see if that fixes our issue (it does not).
