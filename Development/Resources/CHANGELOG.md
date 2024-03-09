# Device
Value type replacement for device information on all platforms with a consistent API.

v1.0.7 3/9/2024 Removed accidentally left in debugging code.
v1.0.6 3/8/2024 Replaced checks for OSes with canImport(UIKit).  Added some code so battery level works on macOS Catalyst.  Updated readme to indicate macOS support.  Updated Description of Current Device.  Fixed so identifier works correctly in macCatalyst.
v1.0.5 3/8/2024 Fixed so name that appears in Package List is Device not DeviceTestApp.
v1.0.4 3/8/2024 Fixed so UIDevice is available on visionOS (UIKit wasn't being included on that platform.)
v1.0.3 3/8/2024 Tested for compatibility.  Updated Readme.  Fixed so previews work.  Added Test code.
v1.0.2 3/5/2024 Re-worked so Disk functions are available even before iOS 11 by moving availability checks into functions.
v1.0.1 2/28/2024 Heath's additions and re-working code for IdiomType so that we can subclass and have device initializers while still being value types.
v1.0.0 2/16/2024 Initial Project based off of DeviceKit but designed to be more maintainable and compatible.

// Ways to generate compiler warnings in code:
#warning("message")
#error("message")

MARK: - Bugs to fix

MARK: - Features to add:
