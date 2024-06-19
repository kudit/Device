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
        #expect(!device.isSimulator)
        #expect(!Device.current.isPreview)
        #expect(Device.current.isRealDevice)
        if let battery = Device.current.battery {
            #expect(battery.currentState == .unplugged)
            #expect(battery.currentLevel  >= 75)
            #expect(!battery.lowPowerMode)
        }
        #expect(Device.current.device.screenBrightness < 50)
        #expect(Device.current.volumeAvailableCapacityForOpportunisticUsage ?? 0 > Int64(1_000_000))
        #expect(Device.current.volumeAvailableCapacityForImportantUsage ?? 0 > Int64(1_000))
    }
}
#endif
