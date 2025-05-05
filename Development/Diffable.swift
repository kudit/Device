//
//  Diffable.swift
//  Device
//
//  Created by Ben Ku on 4/26/25.
//

// TODO: Remove all this?  Not necessary?

// Figure out how to compare two Devices.  ~= operator which has a looser interpretation on the right side since it might have bad data.  Go through each attribute.

// THIS IS SPECIFIC TO Device since we keep the left side as the "truth" and the right side as the parsed (potentially faulty) data.

func ~=<Foo:Equatable> (lhs: Foo?, rhs: Foo?) -> Bool {
    // Test for optionals that have nil.  If parsed is nil, continue.
    guard let rhs else {
        return true // if there is no value here, whether our device has a value or not, we're good
    }
    guard let lhs else {
        return false // the parsed version has data that we don't have!  New data!
    }
    // Additional checks here.
    return lhs == rhs
}

func ~= (lhs: Capabilities?, rhs: Capabilities?) -> Bool {
    // Test for optionals that have nil.  If parsed is nil, continue.
    guard let rhs else {
        return true // if there is no value here, whether our device has a value or not, we're good
    }
    guard let lhs else {
        return false // the parsed version has data that we don't have!  New data!
    }
    // Additional checks here.
    // make sure the lhs is a superset of the rhs
    // Breakpoint - make sure this code is executed
    for value in rhs {
        guard lhs.contains(value) else {
            return false
        }
    }
    return true
}

func ~= (lhs: DateString?, rhs: DateString?) -> Bool {
    // Test for optionals that have nil.  If parsed is nil, continue.
    guard let rhs else {
        return true // if there is no value here, whether our device has a value or not, we're good
    }
    guard let lhs else {
        return false // the parsed version has data that we don't have!  New data!
    }
    // Additional checks here.
    if lhs != rhs {
        // if we match or new data, then we're good, but if we have a mismatch, check if the year matches what we have and the introduction date is January 1 since nothing is ever introduced then and so that's the default year.
        guard rhs.mysqlDate == "\(lhs.date?.year ?? 0)".introductionYear else {
            return false
        }
    }
    return true
}

// Returns `true` if there is no new information in the parsed device over the device.  If the device has more information than the parsedDevice, that's fine.  We only care if there is new or different information in the parsedDevice (returns `false` in this case meaning they're not the same.
@MainActor
func ~= (device: Device, parsedDevice: Device) -> Bool {
    // check all fields.  If value missing on the right, then we're still good
    guard device.idiom ~= parsedDevice.idiom else { return false }
    guard device.officialName ~= parsedDevice.officialName else { return false }
    guard device.introduction ~= parsedDevice.introduction else { return false }
    guard device.supportId ~= parsedDevice.supportId else { return false }
    guard device.launchOSVersion ~= parsedDevice.launchOSVersion else { return false }
    guard device.unsupportedOSVersion ~= parsedDevice.unsupportedOSVersion else { return false }
    guard device.image ~= parsedDevice.image else { return false }
    guard device.capabilities ~= parsedDevice.capabilities else { return false }
    guard device.models ~= parsedDevice.models else { return false }
    guard device.colors ~= parsedDevice.colors else { return false }
    guard device.cpu ~= parsedDevice.cpu else { return false }
    // if the value matches, we're good to go
    return true
}
