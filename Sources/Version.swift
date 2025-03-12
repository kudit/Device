//
//  Version.swift
//  
//
//  Created by Ben Ku on 7/3/24.
//

import Compatibility

// TODO: Move to Compatibility


// MARK: - Named OS versions
public extension Version {
    // TODO: Re-work this back into an ordered dictionary so that we only need to add one line when new versions come out rather than having to update in 2 places.
    static let macOSs: OrderedDictionary<Version, String> = [
        // Mac OS X
        "10.0": "Cheetah",
        "10.1": "Puma",
        "10.2": "Jaguar",
        "10.3": "Panther",
        "10.4": "Tiger",
        "10.5": "Leopard",
        "10.6": "Snow Leopard",
        "10.7": "Lion",
        "10.8": "Mountain Lion",
        "10.9": "Mavericks",
        "10.10": "Yosemite",
        "10.11": "El Capitan",
        // macOS
        "10.12": "Sierra",
        "10.13": "High Sierra",
        "10.14": "Mojave",
        "10.15": "Catalina",
        "11": "Big Sur",
        "12": "Monterey",
        "13": "Ventura",
        "14": "Sonoma",
        "15": "Sequoia",
    ]
    
    func matchesMac(version: Version) -> Bool {
        return version.majorVersion == majorVersion && (majorVersion != 10 || self.minorVersion == version.minorVersion)
    }
    
    func previousMacOS() -> Version {
        var previousVersion: Version = "0.0"
        for (version, _) in Version.macOSs {
            if matchesMac(version: version) {
                return previousVersion
            }
            previousVersion = version
        }
        return previousVersion
    }
    var macOSCodename: String {
        for (key, value) in Version.macOSs {
            if matchesMac(version: key) {
                return value
            }
        }
        return "\(majorVersion) Codename"
    }
    var macOSName: String {
        if majorVersion == 10 && minorVersion < 12 {
            return "OS X \(macOSCodename)"
        } else {
            return "macOS \(macOSCodename)"
        }
    }
}
