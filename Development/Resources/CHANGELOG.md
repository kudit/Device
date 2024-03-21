# ChangeLog

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

[ ] Fix so that previews consistently work in Xcode & Swift Playgrounds.
    - Does not show #Preview("Battery") in Playgrounds on macOS or on iPad Swift Playgrounds.  App Preview is shown.
    - All Previews work in Xcode.
[ ] Designed for iPad running on macOS has all appearance of being an actual iPad and battery level does not work.  Need help on this edge case (or use macCatalyst or macOS development).  Running on macOS (Designed for iPad) reports OS as iPadOS and returns an iPad Pro identifier instead of a Mac identifier and battery information is incorrect.
[ ] Need help getting identifier when buildling for macOS (not catalyst)
[ ] Building from Playground (not using Xcode project), Designed for iPad doesn't report properly but identifier is correct (systemName reports iPadOS) - same when buildling for Mac Catalyst.  Buildling from the Xcode project Designed for iPad does propertly report isDesignedForiPad but the battery indicator and device is wrong.  Buildling for Mac Catalyst does propertly report device and battery.

## Roadmap:
Planned features and anticipated API changes.  If you want to contribute, this is a great place to start.

[ ] Rework features like rounded corners, dynamic island, action button, plus form factor, each camera type, usbc, etc. as `capabilities` variable (option set?).  Have `sensors` variable to have things like lidar, etc.  Implement queries as checks for various capability flags.  Flags can then be added to devices without having to have a separate parameter.
[ ] Add weight option for battery text/symbol (title originally was bold and now that we're doing font size, add weight parameter)
[ ] Add macOS devices (ongoing).  Pull from here: https://github.com/voyager-software/MacLookup/blob/master/Sources/MacLookup/Resources/all-macs.json
[ ] Add new devices (ongoing).
[ ] Improve test app user interface/layout.
[ ] Add tests to complete code coverage.
[ ] Create tests in such a way that they can be run in Previews and in the example App (may require a project dependency).
[ ] See if there's a way to automate tests on various platform combinations.
[ ] Support landscape on iPhone for test view and use size classes to re-layout.
[ ] For devices that support multiple orientations, automatically apply current orientation to the symbol name for current device.
[ ] Create replacement for rounded display corners since faceID is a good proxy but misses modern touchID power button iPads.  Have as capability.

## Proposals:
This is where proposals can be discussed for potential movement to the roadmap.

[ ] Change Battery from Protocol to the DeviceBattery code and have MockBattery be a subclass that overrides functions?
[ ] Create better way of scaling battery so that it can scale with dynamic type?
[ ] Add a way to check that privacy checks have been added when using APIs that need privacy permissions (have a configuration flag that needs to be set to ensure that privacy flags have been set).
[ ] Convert SF Symbol names to an enum to allow version checking?
[ ] If there's a way to fetch the actual model number (like MN572LL/A), then we can use this to give information of the state of the device (new, refurb, replaced, personalized, etc): https://osxdaily.com/2018/01/27/determine-iphone-new-refurbished-replaced/
