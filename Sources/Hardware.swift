// String constants for SF Symbols
public extension String {
    static let symbolUnknownEnvironment = "questionmark.circle"
    static let symbolSimulator = "squareshape.squareshape.dotted"
    static let symbolPlayground = "swift"
    static let symbolPreview = "curlybraces.square"
    static let symbolRealDevice = "square.fill"
    static let symbolDesignedForiPad = "ipad.badge.play"
    static let symbolUnknownDevice = "questionmark.square.dashed"
}

// MARK: CPU
// https://en.wikipedia.org/wiki/List_of_Mac_models_grouped_by_CPU_type
public enum CPU: Comparable {
    // Only 2013+ really need to be included since Swift won't run on devices prior to this.
    case unknown
    // Mac
    case i3
    case xeonE5
    case i5
    case i7
    case m1
    case m1pro
    case m1max
    case m1ultra
    case m2 // also  Vision
    case m2pro
    case m2max
    case m2ultra
    case m3
    case m3pro
    case m3max
    // iPod
    case a4
    case a5
    case a5x
    case a6
    case a6x
    case a7
    // iPhone
    // iPad
    case a8x
    case a9
    case a9x
    case a10
    case a11
    case a12x
    case a12z
    case a13
    case a14
    case a16
    case a17pro
    //  TV
    case a8
    case a10x
    case a12
    case a15
    //  Watch
    case s1
    case s1p
    case s2
    case s3
    case s4
    case s5
    case s6
    case s7
    case s8
    case s9
}

// MARK: Biometrics
public enum Biometrics {
    case none
    case touchID
    case faceID
    case opticID
}

// MARK: Cellular
public enum Cellular {
    case none
    case gprs // 1G
    case edge // 2G
    case threeG // 3G
    case lte // 4G LTE
    case fiveG // 5G
}
