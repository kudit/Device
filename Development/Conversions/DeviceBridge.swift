//
//  DeviceBridge.swift
//  Device
//
//  Created by Ben Ku on 4/27/25.
//

import Device

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
protocol DeviceBridge: DeviceType, Identifiable {
    var source: String { get }
    var matched: Device { get } // TODO: Have matched pull multiple so we can return multiple?  May need to break out some with multiple identifiers like the Apple TVs or various year revisions of devices?
    static func generate() -> String
}
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension DeviceBridge {
    var source: String {
        self.device.definition
    }
    // Override this if we need to match on something else like model number
    var matched: Device {
        let identifier = device.identifiers.first ?? .unknown
        return Device(identifier: identifier)
    }
    var merged: Device {
        return device.merged(from: matched)
    }
    var exactMatch: Bool {
        return device.definition == matched.definition
    }
    var id: String { source }
}
extension String {
    var deviceNormalizedName: String {
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
    func merged(from base: Device) -> Device {
        var idiom = base.idiom
        if self.idiom != .unspecified {
            idiom = self.idiom
        }
        var officialName = base.officialName
        if !self.officialName.contains("Unknown") {
            // possible change in official name.  Ignore if it's similar
            // ignore Gen vs generation
            if officialName.deviceNormalizedName != self.officialName.deviceNormalizedName && !officialName.deviceNormalizedName.contains(self.officialName.deviceNormalizedName) {
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
        if self.models.count > 0 && Set(self.models).isDisjoint(with: Set(models)) {
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

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension Array where Element: DeviceBridge {
    /// Sorted using the order they appear in Device.all list (order as appears in code).
    var sorted: [Element] {
        let orderedIdentifiers = Device.all.map { $0.identifiers }
        return self.sorted {
            orderedIdentifiers.firstIndex(of: $0.device.identifiers) ?? 0
            < orderedIdentifiers.firstIndex(of: $1.device.identifiers) ?? 0 }
    }
}
