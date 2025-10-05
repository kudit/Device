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

v2.10.7 10/5/2025
Additional fixes for WASM.
`CaseNameConvertible` and `DateString` weren't enabled in WASM, so updated Compatibility to add stubs so this could compile, but note that anything that uses these will not truly be supported by Device in WASM unless we can create a backport in Compatibility that doesn't require Mirror or Date (since those are not available in WASM).

v2.10.6 10/4/2025
Updated Compatibility & Color to improve WASM compatiblity.
Removed Codable conformance from WASM and added backport implementation.
Added Foundation checks on SwiftUI code to facilitate WASM testing.
** All Swift Package Index tests passed except WASM **

v2.10.5 10/2/2025
Updated Compatibility & Color to improve WASM compatiblity.

v2.10.4 10/2/2025
Updated Compatibility & Color to improve WASM compatiblity.

v2.10.3 10/1/2025
Updated Compatibility & Color.
**App Store**
Fixed missing images and support links for new Apple Watch models.
Changed name of iPad mini from "iPad Mini".

v2.10.2 9/27/2025
Updated Compatibility.
Fixed watchOS AppIcon warning by splitting into separate item.
Updated IdentifyModelParsing to match model numbers when split.
Fixed issues with "SE (3nd generation)".
Fixed iPod screen sizes, resolutions, and cameras.
**App Store**
Fixed launch version for 2025 iPhones.
Fixed incorrect name for Apple Watch SE (3rd generation).
Fixed missing always-on display for Apple Watch SE (3rd generation) 40mm.
Fixed issue where several iPad models were erroneously listed as having a notch.
Updated change in official naming convention of Apple Watch SE (3rd generation) to Apple Watch SE 3.
Removed duplicate iPod2,1 entry causing it to sometimes be mislabeled as "Unknown“.
Updated watch images to be more consistent (uses the stainless or titanium version for the larger version and aluminum for the smaller ones).

v2.10.1 9/21/2025
Updated App Store descritption.
Fixed DeviceKitLoader extension accidentally being included in release.
**App Store**
Added new September 2025 devices.
Added missing Compass feature to Apple Watch > Series 3.
Added information for several devices that do not support xOS 26.
Fixed missing Touch ID flag for several MacBook models.
Fixed MacBook generation and MagSafe 1 availability on several MacBook models.
Several additional minor data corrections.

v2.10.0 9/21/2025
Updated camera naming to specify the MP and zoom levels do better differentiate cameras.  Note that this renames several which may be a breaking change, but it's unlikely people are using those camera names so not quite worth a major version number update.
Completely re-worked Conversions to allow for better code reuse and more flexible and streamlined checks using fetched project files rather than including files.
Ensured all conversions pass (as of now)
Added DeviceKit comparison.
Made Device conform to Codable.
Added PropertyIterable to DeviceBridge.
Updated Compatibility.

v2.9.0 8/13/2025
Should have renumbered the last version since features were added.  Fixed issues with included Compatibility version.  Fixed CarPlay and Apple Intelligence legacy symbol file format.  (Legacy SF Symbols should be Symbol export (not Template) for Xcode version 12)  ** ALL SWIFTPACKAGEINDEX TESTS PASSED! ** 

v2.8.10 8/11/2025
Added macOS Tahoe and recompiled to correctly report iOS 26 vs iOS 19.
Added fall detection, ecg, and oxygen sensor to device capabilities.
Added CarPlay symbol.
Added Apple Intelligence legacy symbol (not great, but better than nothing).
Removed several symbols from the resources that exist in SF Symbols so we can use the built in version when available and fall back only when not present.  Removed custom modern symbols where there isn't any additions like coloring in the modern version.
App Store Changes:
Added many Apple Watch models.
Added Fall Detection, ECG, and Oxygen Sensor to device capabilities.
Added macOS Tahoe and recompiled to correctly report iOS 26 vs iOS 19.
Added CarPlay symbol.
Added software unsupported versions for devices that won't support xOS 26 (very few devices were dropped!)

v2.8.9 7/8/2025
Updated AppleDevice json since it fixed several mismatches.  Added Apple Watch Ultra 2 naming conversion.

v2.8.8 6/12/2025
Addressed missing utsname and uname in Android.

v2.8.7 6/11/2025
Fixed typo in example license code in README.
Fixed issue with AttributesListView that was introduced in 2.8.5.
Updated Compatibility for WASM and Android support.
For App Store:
Added software unsupported versions for devices that won't support xOS 26 (very few devices were dropped!)

v2.8.6 6/4/2025
Updated change log with SWIFTPACKAGEINDEX test format to be part of description and not separate lines.
Updated the README to have an updated list of Capabilities to match the new additions in a similar order.
Removed DTS Case-ID: 8753208 since it appears this no longer applies in current version of Xcode.
Moved Apple Pay capability to be first under additional features.
Added initial screenshot feature (likely should be improved like including the status bar) but should work on iOS & macOS & tvOS.

v2.8.5 5/17/2025
Odd error with Swift 5.9 about attributes being used before being initialized.  This led to the solution to fix: https://stackoverflow.com/questions/58758370/how-could-i-initialize-the-state-variable-in-the-init-function-in-swiftui (setting initial values for state values before being initailized.  Guessing that there was some update in Swift 5.10 that made this unnecessary for @State values).  ** ALL SWIFTPACKAGEINDEX TESTS PASSED! ** - caused capabilities list UI to break!

v2.8.4 5/16/2025
Added a more generic optional fallback to account for problems in Swift 5.9... *Failed Swift 5.9 all except Linux*

v2.8.3 5/15/2025
Forgot to un-comment `main { }` code for disabling idle timer. *Failed Swift 5.9 all except Linux*

v2.8.2 5/14/2025
Improved error suppression for `@retroactive` conformances.
Moved `swiftVersion` to Compatibility.
Fixed missing `@availability` checks and standardized order (iOS, macOS, tvOS, watchOS).
*Failed Swift 5.10 and 5.9 for all except Linux* 

v2.8.1 5/14/2025
Added `.disableIdleTimer()` method to view since this should be run in UI after appearing rather than in an init.
Improved Swift Playground support with more compatible code.
Updated Compatibility.  *FAILS SWIFTPACKAGEINDEX TESTS: 5.10, 5.9, Linux*

v2.8.0 5/4/2025
Added `introduction` to devices (need to pull from everymac) and created test export for superepicstudios/apple-devices data format.
Broke up Device models into smaller swift files for easier updates and to go easier on the compiler.
Added `ethernet`, `alwaysOnDisplay`, `appleIntelligence`, and `compass` to hardware capabilities.
Reordered `.applePay` to end under software features.
Created default capabilities list for idioms so can automatically remove from capabilities in definition.
Added capability lists for sorting and grouping.
Added ability to get all devices for an idiom.
Added many Apple Watch models.
Fixed bug with color set se.
Improved so search terms are disjoint and will match devices that contain all terms.
For App Store:
Added introduction date to devices.
Allowed searching by introduction year.
Added Apple Intelligence, Compass, Ethernet, and Always On Display flags for device capabilities.
Hid animated test to prevent confusion.
Added several model codes for devices and added ability to search by model code.

v2.7.0 3/12/2025 App Store Changes:
Added new 2025 MacBook Air, iPad Air, and iPad models and all Mac Studios.
Updated images, support links, and models for many many devices.
Not reported changes:
Renamed to "Device Info" to be shorter app name.
Changed so colors parameter is required on all devices.
Changed how System Versions is coded to make updating easier.
Added `constructor` String to `Device.Idiom`.
Reordered Apple TV devices from newest to oldest.
Replaced non-breaking hyphen ("‑") with normal hyphen ("-").

v2.6.5 3/5/2025 App Store changes:
Added iPhone 16e.
Fixed some incorrect support IDs.
Added Application tracking for demo app.
Changed to use duckduckgo feeling ducky feature to direct to product technical support pages with unknown identifiers.
*PASSES ALL SWIFTPACKAGEINDEX TESTS*

v2.6.4 1/15/2025 Fixed missing package version update.  Updated resolved package versions. *PASSES ALL SWIFTPACKAGEINDEX TESTS*

v2.6.3 12/20/2024 Set CURRENT_PROJECT_VERSION = ${MARKETING_VERSION} so that it will set the correct value when submitting to Mac App Store.  Fixed missing version update in Device.swift. *PASSES ALL SWIFTPACKAGEINDEX TESTS*
App Store Change Log:
Added MacBook Air 2024 & 2023 models.

v2.6.2 12/15/2024 Added iMac "M4" models.  Renamed `macbookSilver` to `solidSilver`.  Fixed crashes by making sure official names were never identical and images are different and not reused. *PASSES ALL SWIFTPACKAGEINDEX TESTS*
App Store Change Log:
Dependent frameworks updated.
Added iMac M4 models, MacBook Pro M4 models, Mac mini M4 models, and iPad mini A17 Pro models.
Fixed redundant iPadAirM2 (iPadMiniA17) colorset.

v2.6.1 11/26/2024 Added new MacBook Pro M4 and Mac mini M4 models.  Updated dependent frameworks.

v2.6.0 10/25/2024 Added new iPad mini devices.  Test Device with setting idle timer disabled on launch to make sure works as intended (updated instructions to indicate this needs to be done on view appear and NOT in the init).  Updated the idle timer toggle to reference the current state rather than a shadow variable.  Updated Apple Watch images to match the Identify your Apple Watch support page: https://support.apple.com/en-us/108056 *PASSES ALL SWIFTPACKAGEINDEX TESTS*

v2.5.5 10/18/2024 Tried updating minimum Color framework to try to fix Linux support (Does!) *PASSES ALL SWIFTPACKAGEINDEX TESTS*

v2.5.4 10/14/2024 Should fix Linux support by updating Compatibility framework. *PASSES ALL SWIFTPACKAGEINDEX TESTS - except Linux*

v2.5.3 10/13/2024 Fixed Release build information by changing visibility of ActualHardwareDevice.  This addresses DTS Case-ID: 8753208. *PASSES ALL SWIFTPACKAGEINDEX TESTS - except Linux*

v2.5.2 10/13/2024 Moved Xcode project back to original name to prevent opening crash issues.  Fixed missing project marketing version update!  Updated resolved package versions.

v2.5.1 10/8/2024 Needed to rename app for Mac App Store. *PASSES ALL SWIFTPACKAGEINDEX TESTS*

v2.5.0 (build 2) 10/7/2024 - added 512 version of app icon. *PASSES ALL SWIFTPACKAGEINDEX TESTS*

v2.5.0 10/7/2024 Tweaked to allow releasing app on the App Store.  Since must be built for DEBUG, tweaked check for Migration code.  Re-worked AttributeListView so can include in framework.  Added links to support documents.  Including attribute list in device details.  Fixed duplicate Mac14,9.  Fixed so Thunderbolt named devices definitely show thunderbolt capability.  Uploaded to App Store as "Device Information Tool"."

v2.4.4 9/22/2024 Added identifiers to device detail view.  Fixed Apple Watch 10 identifiers. *PASSES ALL SWIFTPACKAGEINDEX TESTS*

v2.4.3 9/21/2024 Fixed CPU issues with new iPhones and `cameraControl` button and added new Apple Watch stubs and colors.  Added black titanium to Apple Watch Ultra 2.  Fixed deinit task warning with Xcode 16 GM.  Added wrapping on colors to prevent squishing.  Updated colors and added colors for Apple Watches before Series 6 and re-named some colors to match Apple CSS.  Added iPhone colors before iPhone 13.  Updated Apple TV HD image.  Updated iPhone images to all use the identification page for consistency (https://support.apple.com/en-us/108044).

v2.4.2 9/11/2024 Added new iPhones and `cameraControl` button.  Apple Watch updates not available yet.  Attempted to improve background tint to match better.

v2.4.1 8/13/2024 Updated Color/Compatibility versions to address Swift 5.9 issues.  Previous version removed the Resources build when standardizing Package.swift!  Restored.  Explains why Bundle.module was not available since no resources included in the bundle. *PASSES ALL SWIFTPACKAGEINDEX TESTS*

v2.4.0 8/13/2024 Standardized Package.swift, CHANGELOG.md, README.md, and LICENSE.txt files.  Standardized deployment targets.  Switched dependency from Compatibility to Color so we don't have to re-write color parsing code.  Added new HomePod mini Midnight color.  Added supported versions to indicate the preinstalled version and maximum version of iOS/macOS/etc supported by each device.  Have the max version be the version AFTER the version, so for late 2016 Touchbook, `launchOSVersion = "10.12.1"` and `unsupportedOSVersion = "13.0"` (max would be 12.x) - if this is `nil`, this is still currently supported.

v2.3.4 7/19/2024 Added Identifiable to Battery protocol which I think works because ObservableObject requires AnyObject.  Added details for battery tests so that description can be seen and small screens can see all details.  Moved fontSize off of individual views in batteryView in preparation for extracting size entirely so can use sizes externally without having to specify font size (unfortunately, still can't due to not being able to specify relative sizes compared to base, but at least we cleaned up the code some).  Fixed so setting low power mode doesn't cause view to publish changes while rendering. *PASSES ALL SWIFTPACKAGEINDEX TESTS*

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
- [ ] On iPhone 7, Migration button not present.  When going into detail screen for a device, after transitioning, the view resets to the list.
- [ ] Fix so highlighted row inverts primary color text in light mode.
- [ ] Screen view on visionOS text should be black not background since more contrasty and no dark mode.
- [ ] Device fix so brightness and battery update immediately (seems to be working on iOS and visionOS, but not on macOS.  Doesn't work at all for macOS (build for iPad).  Battery works but brightness does not on macOS Catalyst and macOS native)
- [ ] Designed for iPad running on macOS has all appearance of being an actual iPad and battery status seems incorrect.  Need help on this edge case (or use macCatalyst or macOS development).  Building from Playground (not using Xcode project), Designed for iPad doesn't report properly but identifier is correct (systemName reports iPadOS) - same when buildling for Mac Catalyst.  Buildling from the Xcode project Designed for iPad does propertly report isDesignedForiPad but the battery indicator and device is wrong.  Buildling for Mac Catalyst does propertly report device and battery.
- [ ] Retain error on device list scrolling quickly to the bottom on watchOS (simulator and device). Figure out why the all devices list crashes on Apple Watch (simulator and actual device scrolling down to the bottom).
        Info.plist contained no UIScene configuration dictionary (looking for configuration named "Default Configuration")
        ScrollView contentOffset binding has been read; this will cause grossly inefficient view performance as the ScrollView's content will be updated whenever its contentOffset changes. Read the contentOffset binding in a view that is not parented between the creator of the binding and the ScrollView to avoid this.
        Crown Sequencer was set up without a view property. This will inevitably lead to incorrect crown indicator states
        overrelease of detent assertion detected
- [ ] Odd warning: Device.swiftpm/Sources/Resources/SymbolAssets.xcassets: Could not get trait set for device Watch7,2 with version 10.4

## Roadmap:
Planned features and anticipated API changes.  If you want to contribute, this is a great place to start.
- [ ] Add tests like in Compatiblity.
- [ ] Add in symbols into comparison diff views for capabilities rather than the string representations.
- [ ] Create a macOS codename lookup tool (put in number and it should show the codename) in search, or just list all the codenamed systems in reverse order.
- [ ] In definition, have a lookup for pre-defined screens like we do for colorsets so it shows the predefined set reather than the full definition.
- [ ] Add Apple Intelligence as a capability feature.
- [ ] Create migration export that checks values against defaults primarily to check definitions are in the correct order and that named color sets are being used (test to see if color set is equal to named colorset and if so, replace with the named case rather than the listed colors).
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

## Proposals:
This is where proposals can be discussed for potential movement to the roadmap.
- [ ] add a way of searching by capability
- [ ] Add code to device to detect whether screen recording or screenshot is in progress.  Add notification callback?  `addScreenRecordingModeChangeCallback { oldMode, newMode in }`
    https://developer.apple.com/documentation/swiftui/environmentvalues/isscenecaptured#
    https://stackoverflow.com/questions/63954077/swiftui-detect-when-the-user-takes-a-screenshot-or-screen-recording
- [ ] Create state-less wrappers for CurrentDevice inspection so not dependent on observable object and can provide legacy support?  If ObservableObject available, then create an observable CurrentDevice that can be monitoried for changes?
- [ ] See if there's a way to get visionOS version when designed for iPad mode.  This claims to do the right thing but verified it also doesn't work for visionOS (Designed for iPad): https://swiftpackageindex.com/MarcoEidinger/OSInfo
- [ ] Move privacy manifest to the package sources resources folder so it gets processed? https://github.com/devicekit/DeviceKit/issues/408#event-12991784329
- [ ] Do we need to have a way of tearing down a battery monitor when a monitor host disappears?  Not as relevant now that we're auto-monitoring with an observable object.
- [ ] Find a way to make words WATCH and SERIES appear in smallCaps() text field and make Apple be Apple logo character  in official names?
- [ ] For more example code, Make widget for Device tests for Home Screen view and live activity (battery monitor?) Lock Screen widget?
- [ ] Add hook for monitoring when screenshot is taken. `Device.current.monitorForScreenshot { image in } 
- [ ] Create better way of scaling battery so that it can scale with dynamic type?  Use relative type?
- [ ] Add a way to check that privacy checks have been added when using APIs that need privacy permissions (have a configuration flag that needs to be set to ensure that privacy flags have been set).
- [ ] Convert SF Symbol names to an enum to allow version checking?  May need to use other project.
- [ ] If there's a way to fetch the actual model number (like MN572LL/A), then we can use this to give information of the state of the device (new, refurb, replaced, personalized, etc): https://osxdaily.com/2018/01/27/determine-iphone-new-refurbished-replaced/
- [ ] Should forceTouch and touch3d be separated?  Discuss in issues or here.
- [ ] Add always on capability to watches and phones.
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



#AppStore Copy
##Title
Device Information Tool

##Subtitle (30)
123456789012345678901234567890
Detailed device information

##Promotional Text (170)
Download today to get full visibility into your Apple devices, know what’s under the hood, stay ahead of updates, and troubleshoot with confidence.

##Description (4,000)
A fast, accurate, and privacy-first utility that shows everything you want to know about your Apple devices.

This tool has the most complete information available. By downloading, you are supporting a small independent open source developer who makes this information freely available to everyone and keeps it updatable by everyone.

What you get:
• Detailed hardware and software information including model, chip, storage, memory, introduction date, and minimum and maximum OS versions.
• Battery information showing level and charge status.
• Thermal indicator to recognize device temperature.
• Orientation and display data showing how the system reports screen state.
• Idle timer control to prevent the screen from dimming or locking when needed.
• Device capabilities and sensors such as biometrics, LIDAR, ECG, Fall Detection, Oxygen Sensor, and more.
• Direct support and reference links to Apple documentation based on your exact device.

Why you’ll love it:
• Privacy-first design with no data collection. All device information stays on your device.
• Lightweight and fast with minimal battery or resource usage.
• Continuously updated with new Apple devices, sensors, and operating system support.
• Ideal for developers, IT support, and anyone who wants to know the exact capabilities of their Apple devices.

This is a tool for exposing the information in the open source Kudit Device framework.  Feel free to contribute to this project at http://github.com/kudit/Device

If you have any suggestions or feedback, please reach out to us at support+device@kudit.com!

https://www.kudit.com/terms


##Keywords (100)
1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
device,devicekit,framework,github,iphone,identifier,info,ipad,mac,os,screen,capabilities,open,source


#Monetization
for development expenses
$0.99 single purchase.
