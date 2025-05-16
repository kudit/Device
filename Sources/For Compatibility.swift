import Compatibility

public extension Optional {
    /// Support displaying string as an alternative in nil coalescing for inline \(optionalNum ?? "String description of nil")
    static func ?? (optional: Wrapped?, defaultValue: @autoclosure () -> String) -> String {
        if let optional {
            return String(describing: optional)
        } else {
            return defaultValue()
        }
    }
}

//// specific version if generic above doesn't work due to conflict with normal String ?? nil coalescing operator definition.
//public extension Optional where Wrapped == Character {
//    /// Support displaying string as an alternative in nil coalescing for inline \(optionalNum ?? "String description of nil")
//    static func ?? (optional: Wrapped?, defaultValue: @autoclosure () -> String) -> String {
//        if let optional {
//            return String(describing: optional)
//        } else {
//            return defaultValue()
//        }
//    }
//}
