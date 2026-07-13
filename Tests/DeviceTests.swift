#if canImport(Testing) && canImport(Device)
@testable import Device
import Testing
//asdf (apparently testing code isn't run in playgrounds at all.)

struct DeviceTests {
    init() async throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    @Test
    @MainActor
    func testExample() {
        let device = Device.current
        
//        let expectedDevice = Device(identifier: "iPhone16,1")
        let expectedDevice = Device(identifier: "Mac14,10")

        #expect(Device.current.officialName == expectedDevice.officialName)
        #expect(device.idiom == .mac)
        #expect(device.idiom == expectedDevice.idiom)
        #expect(device.identifier == "Mac14,10")
        #expect(expectedDevice.identifiers.contains(device.identifier))
        #expect(!device.has(.force3DTouch))
        #expect(device.is(.pro))
        #expect(!device.is(.plus))
        #expect(device.has(.battery))
        #expect(device.has(.headphoneJack))
        // Environment checks describe this test process, not the detected hardware model.
        #expect(!Build.isSimulator)
        #expect(!Build.isPreview)
        #expect(Build.isRealDevice)
        if let battery = Device.current.battery {
            #expect(battery.currentState == .unplugged)
            #expect(battery.currentLevel  >= 75)
            #expect(!battery.lowPowerMode)
        }
        #expect(Device.current.device.screenBrightness < 50)
        #expect(Device.current.volumeAvailableCapacityForOpportunisticUsage ?? 0 > Int64(1_000_000))
        #expect(Device.current.volumeAvailableCapacityForImportantUsage ?? 0 > Int64(1_000))
    }

    @Test
    func testGPSCapabilityDefaultsAndExceptions() {
        // GPS is modeled at the idiom level for iPhones and Apple Watches because all
        // known devices in those families include GPS, avoiding repeated per-model flags.
        #expect(Device.Idiom.phone.capabilities.contains(.gps))
        #expect(Device.Idiom.watch.capabilities.contains(.gps))

        // Wi-Fi-only iPads and iPods should stay GPS-free; the listed identifiers come
        // from DeviceKit's no-GPS discussion and protect the defaulting logic.
        let noGPSIdentifiers: Set<String> = [
            "iPad2,1", "iPad2,4", "iPad3,1", "iPad3,4", "iPad6,11", "iPad7,5",
            "iPad7,11", "iPad11,6", "iPad12,1", "iPad13,18", "iPad4,1", "iPad5,3",
            "iPad11,3", "iPad13,1", "iPad13,16", "iPad14,8", "iPad14,10", "iPad2,5",
            "iPad4,4", "iPad4,7", "iPad5,1", "iPad11,1", "iPad14,1", "iPad6,7",
            "iPad6,3", "iPad7,3", "iPad7,1", "iPad8,1", "iPad8,2", "iPad8,5",
            "iPad8,6", "iPad8,9", "iPad8,11", "iPad13,4", "iPad13,8", "iPad14,3",
            "iPad14,5", "iPad16,3", "iPad16,5", "iPod1,1", "iPod2,1", "iPod3,1",
            "iPod4,1", "iPod5,1", "iPod7,1", "iPod9,1"
        ]

        for identifier in noGPSIdentifiers {
            #expect(!Device(identifier: identifier).has(.gps))
        }

        // Walk every known iPad identifier so any model not in the no-GPS exception
        // list must expose GPS, matching the cellular/Wi-Fi split in the model data.
        for device in iPad.allDevices {
            for identifier in device.identifiers {
                if identifier.hasPrefix("iPad") && !noGPSIdentifiers.contains(identifier) {
                    #expect(Device(identifier: identifier).has(.gps))
                }
            }
        }

        // Cellular iPads get GPS from their cellular generation, while iPhones inherit
        // GPS from the phone idiom default.
        #expect(Device(identifier: "iPad2,2").has(.gps))
        #expect(Device(identifier: "iPhone1,1").has(.gps))
        #expect(Device(identifier: "Watch1,1").has(.gps))
    }

    @Test
    func testFiveGTracksCellularGenerationWithoutDuplicateCapability() {
        // 5G is represented by the existing cellular enum, which avoids a duplicate
        // capability flag drifting away from the already-maintained model data.
        #expect(Device(identifier: "iPhone13,2").cellular == .fiveG)
        #expect(Device(identifier: "iPad13,17").cellular == .fiveG)
        #expect(Device(identifier: "iPad13,16").cellular == Cellular.none)
        #expect(Device(identifier: "iPhone12,1").cellular != .fiveG)
    }

    @Test
    func testAppleWatchPairedIdentifiersAreSplitIntoGPSAndCellularDefinitions() {
        let splitPairs: [(gps: String, cellular: String)] = [
            ("Watch3,1", "Watch3,3"),
            ("Watch3,2", "Watch3,4"),
            ("Watch4,1", "Watch4,3"),
            ("Watch4,2", "Watch4,4"),
            ("Watch5,1", "Watch5,3"),
            ("Watch5,2", "Watch5,4"),
            ("Watch6,1", "Watch6,3"),
            ("Watch6,2", "Watch6,4"),
            ("Watch5,9", "Watch5,11"),
            ("Watch5,10", "Watch5,12"),
            ("Watch6,6", "Watch6,8"),
            ("Watch6,7", "Watch6,9"),
            ("Watch6,14", "Watch6,16"),
            ("Watch6,15", "Watch6,17"),
            ("Watch6,10", "Watch6,12"),
            ("Watch6,11", "Watch6,13"),
            ("Watch7,1", "Watch7,3"),
            ("Watch7,2", "Watch7,4"),
            ("Watch7,8", "Watch7,10"),
            ("Watch7,9", "Watch7,11"),
            ("Watch7,13", "Watch7,15"),
            ("Watch7,14", "Watch7,16"),
            ("Watch7,17", "Watch7,19"),
            ("Watch7,18", "Watch7,20"),
        ]

        // Each historical two-identifier watch definition should now live as two
        // adjacent, independently maintained records so adding a future watch still
        // only requires editing AppleWatches.swift data instead of expansion logic.
        for pair in splitPairs {
            let gpsWatch = Device(identifier: pair.gps)
            let cellularWatch = Device(identifier: pair.cellular)

            #expect(gpsWatch.identifiers == [pair.gps])
            #expect(cellularWatch.identifiers == [pair.cellular])
            #expect(!gpsWatch.has(.cellular(.lte)))
            #expect(cellularWatch.has(.cellular(.lte)))
            #expect(gpsWatch.officialName.contains("GPS"))
            #expect(cellularWatch.officialName.contains("GPS + Cellular"))
        }

        // This catches any future re-grouping of GPS and cellular watch identifiers
        // into a single definition, which would hide variant-specific data again.
        for watch in AppleWatch.allDevices {
            #expect(watch.identifiers.count == 1)
        }
    }

    @Test
    func testLookupMatchesSupportPageYearQualifiedMacBookAirNames() {
        // Apple's Identify pages can include the launch year in the MacBook Air M5
        // name even though the library definition omits it, so lookup must still
        // find the local model for color disambiguation and migration diffs.
        let matches = Device.lookup(officialNameHint: "MacBook Air (15-inch, M5, 2026)")

        #expect(matches.first?.identifiers == ["Mac17,4"])
        #expect(matches.first?.colors == .macbookAir2025)
    }

    @Test
    func testLookupFiltersAppleWatchNameFallbackByIdiom() {
        // This intentionally uses name-only lookup to exercise the expensive
        // fallback used when an Apple support model number is missing or unknown.
        let matches = Device.lookup(officialNameHint: "Apple Watch Series 10 (GPS + Cellular) 42mm")

        #expect(!matches.isEmpty)
        #expect(matches.allSatisfy { $0.idiom == .watch })
    }
}
#endif
