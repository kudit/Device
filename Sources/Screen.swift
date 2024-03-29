import Foundation

public struct Screen: Hashable {
    public struct Size: Hashable {
        var width: Int
        var height: Int
        /// Reduce the size into a ratio of whole numbers.
        public var ratio: Size {
            if Int(round(100 * Double(width) / Double(height))) == 75 {
                return Size(width: 3, height: 4)
            }
            if Int(100 * Double(width) / Double(height)) == 56 {
                return Size(width: 9, height: 16)
            }
            if Int(10 * Double(width) / Double(height)) == 8 {
                return Size(width: 4, height: 5)
            }

            let min = min(width, height)
            let max = Int(floor(Double(min) / 2.0))
            guard max > 1 else {
                return self // end condition when we can't divide any more
            }
            for divisor in 2...max {
                if width % divisor == 0 && height % divisor == 0 {
                    // even divisor
                    return Size(width: width / divisor, height: height / divisor).ratio // recurse
                }
            }
            // nothing divides evenly.  we're reduced as much as we can be
            return self
        }
    }
    public static func == (lhs: Screen, rhs: Screen) -> Bool {
        lhs.diagonal == rhs.diagonal
        && lhs.resolution == rhs.resolution
        && lhs.ppi == rhs.ppi
    }
    
    public var diagonal: Double?
    public var resolution: Size // width, height in pixels
    public var ppi: Int?
    
    public init(
        diagonal: Double? = nil,
        resolution: (Int, Int),
        ppi: Int? = nil
    ) {
        self.diagonal = diagonal
        self.resolution = Size(width: resolution.0, height: resolution.1)
        self.ppi = ppi
    }
    
    public static var tv = Screen(resolution: (16,9))
    public static var p720 = Screen(resolution: (1280,720))
    public static var p1080 = Screen(resolution: (1920,1080))
    public static var vision = Screen(resolution: (3660,3200))
    // MARK: iPhones
    // iPhone 4
    public static var i35 = Screen(diagonal: 3.5, resolution: (640,960), ppi: 326)
    // iPod Touch, iPhone 5
    public static var i4 = Screen(diagonal: 4, resolution: (640,1136), ppi: 326)
    // iPhone 6
    public static var i47 = Screen(diagonal: 4.7, resolution: (750,1334), ppi: 326)
    // iPhone 12 mini
    public static var i54 = Screen(diagonal: 5.4, resolution: (1080,2340), ppi: 476)
    // iPhone 6 Plus
    public static var i55 = Screen(diagonal: 5.5, resolution: (1080,1920), ppi: 401)
    // iPhone X
    public static var i58 = Screen(diagonal: 5.8, resolution: (1125,2436), ppi: 458)
    // iPhone Xs Max
    public static var i65 = Screen(diagonal: 6.5, resolution: (1242,2688), ppi: 458)
    // iPhone Xʀ
    public static var i61x828 = Screen(diagonal: 6.1, resolution: (828,1792), ppi: 326)
    // iPhone 11 Pro
    public static var i61x1125 = Screen(diagonal: 6.1, resolution: (1125,2436), ppi: 458)
    // iPhone 12 Pro, 13 Pro, 14
    public static var i61x1170 = Screen(diagonal: 6.1, resolution: (1170,2532), ppi: 460)
    // iPhone 14 Pro
    public static var i61x1179 = Screen(diagonal: 6.1, resolution: (1179,2556), ppi: 460)
    // iPhone 12 Pro Max, iPhone 14 Plus
    public static var i67x1284 = Screen(diagonal: 6.7, resolution: (1284,2778), ppi: 458)
    // iPhone 14,15 Pro Max
    public static var i67x1290 = Screen(diagonal: 6.7, resolution: (1290,2796), ppi: 460)
    // MARK: iPads
    // iPad 2
    public static var i97x768 = Screen(diagonal: 9.7, resolution: (768,1024), ppi: 132)
    // iPad 3
    public static var i97x1536 = Screen(diagonal: 9.7, resolution: (1536,2048), ppi: 264)
    // iPad Air 3rd gen
    public static var i105 = Screen(diagonal: 10.5, resolution: (1668,2224), ppi: 264)
    // iPad 7th gen
    public static var i102 = Screen(diagonal: 10.2, resolution: (1620,2160), ppi: 264)
    // iPad 10th gen
    public static var i109 = Screen(diagonal: 10.9, resolution: (1640,2360), ppi: 264)
    // iPad mini
    public static var i79x768 = Screen(diagonal: 7.9, resolution: (768,1024), ppi: 163)
    // iPad mini 2
    public static var i79x1536 = Screen(diagonal: 7.9, resolution: (1536,2048), ppi: 326)
    // iPad mini 6
    public static var i83 = Screen(diagonal: 8.3, resolution: (1488,2266), ppi: 326)
    // iPad Pro
    public static var i129 = Screen(diagonal: 12.9, resolution: (2048,2732), ppi: 264)
    // iPad Pro 11
    public static var i11 = Screen(diagonal: 11.0, resolution: (1668,2388), ppi: 264)
    // MARK: Watches
    public static var wUnknown = Screen(
        diagonal: 2.0,
        resolution: (396,484),
        ppi: 326) // placeholder
    public static var w38 = Screen(diagonal: 1.5, resolution: (272,340), ppi: 290) // 326?
    public static var w40 = Screen(diagonal: 1.8, resolution: (324,394), ppi: 326)
    public static var w41 = Screen(diagonal: 1.8, resolution: (352,430), ppi: 326)
    public static var w42 = Screen(diagonal: 1.65, resolution: (312,390), ppi: 303) // 326?
    public static var w44 = Screen(diagonal: 2.0, resolution: (368,448), ppi: 326)
    public static var w45 = Screen(diagonal: 2.0, resolution: (396,484), ppi: 326)
    public static var w49 = Screen(diagonal: 2.2, resolution: (410,502), ppi: 338)
    
    /**
     This enum describes the state of the orientation.
     - Landscape: The device is in Landscape Orientation
     - Portrait:  The device is in Portrait Orientation
     */
    public enum Orientation: Hashable {
        case landscape
        case portrait
        
        public var isLandscape: Bool {
            return self == .landscape
        }
    }
}

