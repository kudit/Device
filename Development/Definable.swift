//
//  Definable.swift
//  Device
//
//  Created by Ben Ku on 4/26/25.
//

import Compatibility

// TODO: Move this into a Definable package.  At least move this to a Definable.swift file.
// TODO: Use this to help with code generation more globally?  Add to KuditFrameworks/Compatibility?
public protocol Definable {
    var definition: String { get }
}
public extension Collection where Element: Definable {
    var definition: String {
        "[\(self.map { $0.definition }.joined(separator: ", "))]"
    }
}
extension [String]: Definable {}
public extension Optional where Wrapped: Definable {
    var definition: String {
        if let unwrapped = self {
            return unwrapped.definition
        }
        return "nil"
    }
}
extension Optional: Definable where Wrapped: Definable {}
// Dictionaries
extension [String:Any]: Definable {
    public var definition: String {
        var strings = [String]()
        for (key,value) in self {
            if let v = value as? Definable {
                strings.append("\"\(key)\": \(v.definition)")
            } else {
                debug("UNKNOWN NON-DEFINABLE TYPE: \(key): \(value)", level: .ERROR)
            }
        }
        return "[\(strings.definition)]"
    }
}

// must manually add enum conformance since some may include associated values?  Is there a way to auto-conform?...
// for enums (any types that inherit CaseNameConvertible will also have to inherit Definable or have an extension adding this conformance).
public extension CaseNameConvertible {
    var definition: String {
        "." + self.caseName
    }
}
public extension Bool {
    var definition: String {
        self ? "true" : "false"
    }
}
public extension Int {
    var definition: String {
        "\(self.description)"
    }
}
public extension Double {
    var definition: String {
        "\(self.description)".replacingOccurrences(of: ".0", with: "")
    }
}
public extension LosslessStringConvertible {
    var definition: String {
        return "\"\(self.description)\""
    }
}
extension Bool: Definable {}
extension Int: Definable {}
extension Double: Definable {}
extension String: Definable {}
extension DateString: Definable {
    public var definition: String {
        let year = self.date?.year ?? 0
        if self.mysqlDate == year.introductionYear.mysqlDate {
            return "\(year).introductionYear"
        } else {
            return self.mysqlDate.definition
        }
    }
}
extension DateTimeString: Definable {}
extension Version: Definable {
    public var definition: String {
        if minorVersion == 0 && patchVersion == 0 {
            return "\(majorVersion)".definition // remove the .0
        }
        return self.description.definition
    }
}
