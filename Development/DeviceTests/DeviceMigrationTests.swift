// Development-only bridges intentionally stay outside the public Device library.
// The Apple-host test target compiles their real sources alongside these regressions.
@_exported import Compatibility
@_exported import Device

#if DEBUG && canImport(SwiftUI) && canImport(Testing)
import Testing

@Suite
@MainActor
struct DeviceMigrationTests {
    /// Apple's combined row is valid input; its output must retain both identifier/CPU relationships.
    @Test func groupedMacsPreserveVariants() {
        for identifiers in [["Mac17,7", "Mac17,9"], ["Mac17,6", "Mac17,8"]] {
            let source = mac(identifiers: identifiers)
            #expect(source.groupedDevices.count == 2)
            #expect(source.matchType == .compatible)
            #expect(Set(source.mergedDevices.map { $0.cpu }) == Set([CPU.m5pro, .m5max]))
            #expect(source.mergedDevices.allSatisfy { $0.identifiers.count == 1 })
            #expect(Set(source.mergedDevices.flatMap { $0.identifiers }) == Set(identifiers))
            #expect(source.deviceCode.contains(".m5pro") && source.deviceCode.contains(".m5max"))
            #expect(source.deltaReport.hasPrefix("Grouped source:"))
            #expect(!source.deltaReport.contains("[conflict]"))
            #expect(source.models == identifiers) // Comparison must never mutate the source record.
        }
    }

    /// Support metadata validates a relationship, not arbitrary new IDs, CPU claims or part numbers.
    @Test func groupingDoesNotHideErrors() {
        let unknown = mac(identifiers: ["Mac17,7", "Mac99,999"])
        #expect(unknown.groupedDevices.isEmpty)
        #expect(unknown.matchType == .mismatched)
        let unrelated = mac(identifiers: ["Mac17,7", "Mac17,6"])
        #expect(unrelated.groupedDevices.isEmpty)
        var wrongCPU = mac(identifiers: ["Mac17,7", "Mac17,9"])
        wrongCPU.name = "MacBook Pro (14-inch, M4 Pro or M4 Max, 2026)"
        #expect(wrongCPU.groupedDevices.isEmpty)
        #expect(wrongCPU.matchType == .mismatched)
        var unknownPart = mac(identifiers: ["Mac17,7", "Mac17,9"])
        unknownPart.parts = ["UNRECOGNIZED-PART"]
        #expect(unknownPart.groupedDevices.count == 2)
        #expect(unknownPart.matchType == .mismatched)
        // Partial overlap used to discard the unfamiliar part during merge.
        unknownPart.parts.append("MGDN4xx/A")
        #expect(unknownPart.matchType == .mismatched)
        #expect(unknownPart.deltaReport.contains("UNRECOGNIZED-PART"))
        // The current draft devices have placeholder support IDs; those are not a family relationship.
        #expect(Device.sourceGroup(identifiers: ["iPhone19,2", "iPhone19,3"]).isEmpty)
    }

    /// Apple's HTML bridge uses exactly the same grouping path as MacLookup.
    @Test func applePageGroupingUsesSharedPolicy() {
        let source = ParsedItem(
            officialName: "MacBook Pro (14-inch, M5 Pro or M5 Max)",
            idiom: .mac, identifiers: ["Mac17,7", "Mac17,9"], supportId: "126318",
            source: "Original combined Apple section")
        #expect(source.groupedDevices.count == 2)
        #expect(source.matchType == .compatible)
        #expect(Set(source.mergedDevices.map { $0.cpu }) == Set([CPU.m5pro, .m5max]))
        #expect(source.source == "Original combined Apple section")
    }

    /// Already-split rows remain ordinary comparisons, including multi-identifier single definitions.
    @Test func separatedRecordsAndCPUParsing() {
        let separated = mac(identifiers: ["Mac17,9"])
        #expect(separated.groupedDevices.isEmpty)
        #expect(separated.merged.cpu == .m5max)
        #expect(CPU.sourceChoices(in: "MacBook Pro (M5 Pro)") == [.m5pro])
        #expect(Set(CPU.sourceChoices(in: "M5 Pro or M5 Max")) == Set([CPU.m5pro, .m5max]))
        #expect(Device.sourceGroup(identifiers: ["iPhone3,1", "iPhone3,2"]).isEmpty)
    }

    /// The new schema defaults and legacy positional records describe the same device.
    @Test func deviceKitFormatsAndRoundTrip() throws {
        let named = #"Device("iPodTouch5", "comment, with punctuation)", "https://example.com/?a=b", ["iPod5,1"], 4, (9,16), "iPod touch (5th generation)", "iPod touch (5th generation)", 326, cpu="a5", cameras=1)"#
        let legacy = #"Device("iPodTouch5", "comment, with punctuation)", "https://example.com/?a=b", ["iPod5,1"], 4, (9,16), "iPod touch (5th generation)", "iPod touch (5th generation)", 326, False, False, False, False, False, False, False, False, False, False, 0, False, 1, False, "a5", False, False)"#
        let parsed = try DeviceKitLoader.parse(named)
        #expect(parsed == (try DeviceKitLoader.parse(legacy)))
        #expect(parsed == (try DeviceKitLoader.parse(parsed[0].source)))
        #expect(throws: (any Error).self) { try DeviceKitLoader.parse(named.replacingOccurrences(of: "cpu=", with: "unknownCPU=")) }
        #expect(throws: (any Error).self) { try DeviceKitLoader.parse("Device(\"truncated\"") }
    }

    /// A combined Watch record stays available as source, with GPS/cellular members separately accessible.
    @Test func deviceKitKeepsSourceGrouping() throws {
        let source = #"Device("appleWatchSE2", "comment", "image", ["Watch6,10", "Watch6,12"], 1.8, (324,394), "Apple Watch SE (2nd generation) 40mm", "Apple Watch SE (2nd generation) 40mm", 326, cpu="s8")"#
        let records = try DeviceKitLoader.parse(source)
        #expect(records.count == 1)
        #expect(records[0].identifiers == ["Watch6,10", "Watch6,12"])
        #expect(records[0].groupedDevices.count == 2)
        #expect(records[0].mergedDevices.map { $0.identifiers } == [["Watch6,10"], ["Watch6,12"]])
    }

    /// Source naming errors stay actionable, and the already-supported MagSafe trait maps to hardware.
    @Test func mobileNamesAndAppleTraits() throws {
        let wrong = MobileDevice(identifier: "Watch6,10", officialName: "Apple Watch SE 40mm case (GPS)")
        let correct = MobileDevice(identifier: "Watch6,10", officialName: "Apple Watch SE 2 40mm case (GPS)")
        #expect(wrong.matchType == .mismatched)
        #expect(correct.matchType != .mismatched)
        let magSafe = try JSONDecoder().decode(AppleDeviceTrait.self, from: Data(#""magsafe""#.utf8))
        #expect(Capability(appleDeviceTrait: magSafe) == .magSafe)
        #expect(Capability(appleDeviceTrait: .foldableDisplay) == nil)
    }

    /// Apple lists the Ultra 3 active display as 422 × 514 pixels at 326 ppi.
    @Test func appleWatchUltra3PixelDensityMatchesTechSpecs() {
        let ultra3 = Device(identifier: "Watch7,12")
        #expect(ultra3.screen?.resolution == Screen.Size(width: 422, height: 514))
        #expect(ultra3.screen?.ppi == 326)
    }

    /// A minimal faithful source fixture avoids network dependence and unrelated source metadata churn.
    private func mac(identifiers: [String]) -> MacLookup {
        let size = identifiers.contains("Mac17,6") ? "16" : "14"
        let variant = "\(size)-inch, M5 Pro or M5 Max, 2026"
        return MacLookup(models: identifiers, kind: "MacBook Pro", colors: [],
                         name: "MacBook Pro (\(variant))", notes: [], variant: variant, parts: [])
    }
}
#endif
