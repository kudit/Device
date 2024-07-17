//
//  Version.swift
//  
//
//  Created by Ben Ku on 7/3/24.
//

import Compatibility

// MARK: - Named OS versions
public extension Version {
    var macOSCodename: String {
        switch majorVersion {
        case 15: return "Sequoia"
        case 14: return "Sonoma"
        case 13: return "Ventura"
        case 12: return "Monterey"
        case 11: return "Big Sur"
        case 10: // Mac OS X
            switch minorVersion {
            case 15: return "Catalina"
            case 14: return "Mojave"
            case 13: return "High Sierra"
            case 12: return "Sierra"
            case 11: return "El Capitan"
            case 10: return "Yosemite"
            case 9: return "Mavericks"
            case 8: return "Mountain Lion"
            case 7: return "Lion"
            case 6: return "Snow Leopard"
            case 5: return "Leopard"
            case 4: return "Tiger"
            case 3: return "Panther"
            case 2: return "Jaguar"
            case 1: return "Puma"
            case 0: return "Cheetah"
            default: break
            }
        default: break
        }
        return "\(majorVersion)"
    }
    var macOSName: String {
        return "macOS \(macOSCodename)"
    }
}
