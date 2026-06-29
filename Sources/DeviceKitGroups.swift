//
//  DeviceKitGroups.swift
//  Device
//
//  DeviceKit-style public group arrays for migration compatibility.
//

import Compatibility

public extension Device {
    // MARK: - DeviceKit-style idiom groups

    /// All known iPod touch devices.
    static var allPods: [Device] { iPod.allDevices }

    /// All known iPhone devices.
    static var allPhones: [Device] { iPhone.allDevices }

    /// All known iPad devices.
    static var allPads: [Device] { iPad.allDevices }

    /// All known Apple TV devices.
    static var allTVs: [Device] { AppleTV.allDevices }

    /// All known Apple Watch devices.
    static var allWatches: [Device] { AppleWatch.allDevices }

    /// All known HomePod devices.
    static var allHomePods: [Device] { HomePod.allDevices }

    /// All known Apple Vision devices.
    static var allVisionDevices: [Device] { AppleVision.allDevices }

    /// All known Mac devices.
    static var allMacs: [Device] { Mac.allDevices }

    /// All known real devices.
    ///
    /// Unlike DeviceKit, `Device` does not model simulators as separate enum cases, so this is equivalent to `Device.all`.
    static var allRealDevices: [Device] { all }

    // MARK: - DeviceKit-style feature groups

    /// All Plus, Max, and similarly large iPhone form factors.
    static var allPlusSizedDevices: [Device] {
        allPhones.filter { device in
            device.has(.plus)
            || device.has(.max)
            || (device.screen?.diagonal ?? 0) >= 6.5
        }
    }

    /// All devices marked as Pro.
    static var allProDevices: [Device] { all.filter { $0.has(.pro) } }

    /// All devices marked as mini.
    static var allMiniDevices: [Device] { all.filter { $0.has(.mini) } }

    /// All Touch ID capable devices.
    static var allTouchIDCapableDevices: [Device] {
        all.filter { $0.biometrics == .touchID }
    }

    /// All Face ID capable devices.
    static var allFaceIDCapableDevices: [Device] {
        all.filter { $0.biometrics == .faceID }
    }

    /// All devices with Touch ID, Face ID, or Optic ID.
    static var allBiometricAuthenticationCapableDevices: [Device] {
        all.filter { device in
            guard let biometrics = device.biometrics else { return false }
            return biometrics != .none
        }
    }

    /// All devices that feature a sensor housing in the screen.
    static var allDevicesWithSensorHousing: [Device] {
        allPhones.filter { $0.has(.notch) || $0.has(.dynamicIsland) }
    }

    /// All X-Series devices.
    @available(*, deprecated, renamed: "allDevicesWithSensorHousing")
    static var allXSeriesDevices: [Device] { allDevicesWithSensorHousing }

    /// All devices that have rounded display corners.
    static var allDevicesWithRoundedDisplayCorners: [Device] {
        all.filter { $0.has(.roundedCorners) }
    }

    /// All devices that have the Dynamic Island.
    static var allDevicesWithDynamicIsland: [Device] {
        all.filter { $0.has(.dynamicIsland) }
    }

    /// All devices that have 3D Touch or Force Touch support.
    static var allDevicesWith3dTouchSupport: [Device] {
        all.filter { $0.has(.force3DTouch) }
    }

    /// All devices that support wireless charging.
    static var allDevicesWithWirelessChargingSupport: [Device] {
        all.filter { $0.has(.wirelessCharging) }
    }

    /// All devices that support 5G cellular.
    static var allDevicesWith5gSupport: [Device] {
        all.filter { $0.cellular == .fiveG }
    }

    /// All devices that have a LiDAR sensor.
    static var allDevicesWithALidarSensor: [Device] {
        all.filter { $0.has(.lidar) }
    }

    /// All devices that have USB-C connectivity.
    static var allDevicesWithUSBCConnectivity: [Device] {
        all.filter { $0.has(.usbC) }
    }

    /// All Apple Watches that have Force Touch support.
    static var allWatchesWithForceTouchSupport: [Device] {
        allWatches.filter { $0.has(.force3DTouch) }
    }
}
