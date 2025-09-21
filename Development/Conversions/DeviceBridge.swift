//
//  DeviceBridge.swift
//  Device
//
//  Created by Ben Ku on 4/27/25.
//

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
/// An object representing a native version of a conversion item for comparison.
protocol DeviceBridge: Identifiable, Equatable, Sendable, Codable, PropertyIterable {
    /// filter out and ignore these paths when calculating exact match - for things like DeviceKit comments or images/support URLs since those may be different and aren't as easily constructed
    static var diffIgnoreKeys: [String] { get }
    /// A string representation of the source (HTML clipping, JSON row, Text row
    var source: String { get }
    /// A specific Device that is the best match for this bridge data.  If multiple potentially match, we should pick the best match for this item (if this may happen, create multiple device bridges which will match with different devices).
    var matched: Device { get }
    /// A Device with updated fields based on this Bridge's values filling the matched device's values only when bridge values are missing.  Should be primarily the bridge's values though in case there is no device match or there is a conflict.
    var merged: Device { get }
    /// create a bridged version of a Device (will use to create diff views from matched and merged)
    func bridge(from device: Device) -> Self
}
protocol DeviceBridgeLoader: Sendable {
    associatedtype Bridge
    /// Get a list of the Bridge device type devices (likely from text that is parsed hence async)
    func devices() async throws -> [Bridge]
}
import SwiftUI
enum MatchType {
    case identical
    case compatible // important fields match
    case mismatched // important fields mismatch
    
    var color: Color {
        switch self {
        case .identical:
            return .green
        case .compatible:
            return .yellow
        case .mismatched:
            return .red
        }
    }
}
struct BridgeFieldDiff {
    let fieldName: String
    let leftValue: String
    let rightValue: String
    let mergedValue: String
    let matchType: MatchType
}
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension DeviceBridge {
    // default implementation
    static var diffIgnoreKeys: [String] {
        [] // filter out and ignore these paths when calculating exact match - for things like DeviceKit comments or images/support URLs since we know those may differ
    }
    var matchType: MatchType {
        var overallMatchType: MatchType = .identical
        for diff in diffs {
            if diff == .mismatched {
                return .mismatched
            }
            if diff == .compatible {
                overallMatchType = .compatible
            }
        }
        return overallMatchType
    }
    private var diffs: [MatchType] {
        var diffs = [MatchType]()
        let matched = matchedBridge
        let merged = mergedBridge
        for (key, path) in self.allKeyPaths {
            var matchType = MatchType.identical
            let left = matched[keyPath: path]
            let right = self[keyPath: path]
            let merged = merged[keyPath: path]
            if !areEqual(left, merged) {
                if Self.diffIgnoreKeys.contains(key) {
                    matchType = .compatible
                } else {
                    matchType = .mismatched
                }
            } else if !areEqual(left, right) {
                // left and merged are equal so will return as identical, but if left and right aren't equal, consider this a compatible match not identical
                matchType = .compatible
            }
            diffs.append(matchType)
        }
        return diffs
    }
    var id: String { source }
    
    var deviceCode: String {
        merged.definition
    }
    
    var matchedBridge: Self {
        self.bridge(from: matched)
    }
    
    var mergedBridge: Self {
        self.bridge(from: merged)
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension Array where Element: DeviceBridge {
    /// Sorted using the order they appear in Device.all list (order as appears in code).
    var sorted: [Element] {
        let orderedIdentifiers = Device.all.map { $0.identifiers }
        return self.sorted {
            orderedIdentifiers.firstIndex(of: $0.merged.identifiers) ?? 0
            < orderedIdentifiers.firstIndex(of: $1.merged.identifiers) ?? 0 }
    }
}

extension String {
    static let unknownIdentifier = "Unknown0,0" // just in case we don't have an identifier, this is a way to set a dummy identifier.
    
    var deviceNormalized: String {
        return self
            .tagsStripped
            .safeDescription // for Xʀ
            .lowercased()
            .replacingOccurrences(of: "generation", with: "gen")
            .replacingOccurrences(of: "2nd", with: "2")
            .replacingOccurrences(of: ["(", ")"], with: "")
    }
}

extension Device {
    public static func forcedLookup(identifier: String? = nil, model: String? = nil, supportId: String? = nil, officialNameHint: String? = nil) -> Device {
        if let device = Device.lookup(identifier: identifier, model: model, supportId: supportId, officialNameHint: officialNameHint).first {
            return device
        }
        let device = Device(identifier: identifier ?? .unknownIdentifier)
        guard device.idiom == .unspecified else {
            return device
        }
        let models: [String] =
        if let model {
            [model]
        } else {
            []
        }
        let identifiers: [String] = if let identifier {
            [identifier]
        } else {
            [.unknownIdentifier]
        }
        // unknown device
        return self.init(
            idiom: .unspecified,
            officialName: officialNameHint ?? "Unknown Device",
            identifiers: identifiers,
            introduction: nil,
            supportId: .unknownSupportId,
            launchOSVersion: .zero,
            unsupportedOSVersion: nil,
            image: nil,
            capabilities: [],
            models: models,
            colors: [],
            cpu: .unknown)
    }

    /// For checking that this device has good values (and if not, use base values)
    func merged(from base: Device) -> Device {
        var idiom = base.idiom
        if self.idiom != .unspecified {
            idiom = self.idiom
        }
        var officialName = base.officialName
        if !self.officialName.contains("Unknown") {
            // possible change in official name.  Ignore if it's similar
            // ignore Gen vs generation
            if officialName.deviceNormalized != self.officialName.deviceNormalized && !officialName.deviceNormalized.contains(self.officialName.deviceNormalized) {
                officialName = self.officialName
            }
        }
        var identifiers = base.identifiers
        if self.identifiers.count > 0 && !Set(self.identifiers).isSubset(of: Set(identifiers)) {
            identifiers.append(contentsOf: self.identifiers)
            identifiers.removeDuplicates()
            identifiers.sort()
        }
        var introduction = base.introduction
        if let selfIntroduction = self.introduction, selfIntroduction != introduction {
            if let baseIntroduction = introduction {
                // we have some difference in dates.  However if we just have a year and the base already has that, ignore.
                if selfIntroduction.mysqlDate == "\(baseIntroduction.date?.year ?? 0)".introductionYear {
                    // leave the base
                } else {
                    // we have conflicting information
                    introduction = selfIntroduction
                }
            } else {
                // if the base is empty but we are not, just assign
                introduction = selfIntroduction
            }
        }
        var supportId = base.supportId
        if self.supportId != .unknownSupportId {
            supportId = self.supportId
        }
        var launchOSVersion = base.launchOSVersion
        if self.launchOSVersion != .zero {
            launchOSVersion = self.launchOSVersion
        }
        var unsupportedOSVersion = base.unsupportedOSVersion
        if let selfUnsupportedOSVersion = self.unsupportedOSVersion, selfUnsupportedOSVersion != .zero {
            unsupportedOSVersion = selfUnsupportedOSVersion
        }
        var image = base.image
        if let selfImage = self.image {
            image = selfImage
        }
        var capabilities = base.capabilities
        if self.capabilities.count > 0 && !self.capabilities.isSubset(of: capabilities) {
            // add the new capabilities in
            capabilities.formUnion(self.capabilities)
        }
        var models = base.models
        // normally we'd flag if different, but since some Apple items are grouped (like Mac16,7), only use the new set if there is no overlap.
        // Apple Watch models may differ and we definitely want the local version in that case to merge.
        if self.models.count > 0 && (Set(self.models).isDisjoint(with: Set(models)) || idiom == .watch) {
            models = self.models
        }
        var colors = base.colors
        if self.colors.count > 0 && self.colors != .default && !Set(self.colors).isSubset(of: Set(colors)) {
            colors.append(contentsOf: self.colors)
            colors.removeDuplicates()
            // order matters
        }
        var cpu = base.cpu
        if self.cpu != .unknown {
            cpu = self.cpu
        }
        return Device(
            idiom: idiom,
            officialName: officialName,
            identifiers: identifiers,
            introduction: introduction,
            supportId: supportId,
            launchOSVersion: launchOSVersion,
            unsupportedOSVersion: unsupportedOSVersion,
            image: image,
            capabilities: capabilities,
            models: models,
            colors: colors,
            cpu: cpu)
    }
}


