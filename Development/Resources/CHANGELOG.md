# ChangeLog

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

[ ] Fix so that previews consistently work in Swift Playgrounds.
    - Does not show #Preview("Battery") in Playgrounds on macOS or on iPad Swift Playgrounds.  App Preview is shown.
    - All Previews work in Xcode.

## Roadmap:
Planned features and anticipated API changes.  If you want to contribute, this is a great place to start.

[ ] Add macOS devices (ongoing).
[ ] Add new devices (ongoing).
[ ] Improve test app user interface/layout.
[ ] Add tests to complete code coverage.
[ ] Create tests in such a way that they can be run in Previews and in the example App (may require a project dependency).

## Proposals:
This is where proposals can be discussed for potential movement to the roadmap.

[ ] Change Battery from Protocol to the DeviceBattery code and have MockBattery be a subclass that overrides functions?
[ ] Create better way of scaling battery so that it can scale with dynamic type?
