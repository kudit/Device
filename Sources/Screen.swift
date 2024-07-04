import Foundation

public struct Screen: Hashable, Sendable {
    static let undefined = Screen(resolution: (-1,-1))
    public struct Size: Hashable, Sendable {
        public var width: Int
        public var height: Int
        public init(width: Int, height: Int) {
            self.width = width
            self.height = height
        }
        /// Reduce the size into a ratio of whole numbers.  TODO: fix so works in both dimensions
        public var ratio: Size {
            let ratio = Double(width) / Double(height)
            if 68...79 ~= Int(round(100 * ratio)) { // 75
                return Size(width: 3, height: 4)
            }
            if Int(100 * ratio) == 56 {
                return Size(width: 9, height: 16)
            }
            if Int(100 * ratio) == 46 { // 9:19.5 - new iPhones
                return Size(width: 18, height: 39)
            }
            if Int(10 * ratio) == 8 {
                return Size(width: 4, height: 5)
            }
            if ratio < 1.7 && ratio > 1.5 { // mac screens
                return Size(width: 16, height: 10)
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
    
    public var diagonal: Double?
    public var resolution: Size // width, height in pixels
    public var ppi: Int?
    
//    public static func == (lhs: Screen, rhs: Screen) -> Bool {
//        lhs.diagonal == rhs.diagonal
//        && lhs.resolution == rhs.resolution
//        && lhs.ppi == rhs.ppi
//    }
    
    public init(
        diagonal: Double? = nil,
        resolution: (Int, Int),
        ppi: Int? = nil
    ) {
        self.diagonal = diagonal
        self.resolution = Size(width: resolution.0, height: resolution.1)
        self.ppi = ppi
    }
    
    public static let tv = Screen(resolution: (16,9))
    public static let p720 = Screen(resolution: (1280,720))
    public static let p1080 = Screen(resolution: (1920,1080))
    public static let vision = Screen(resolution: (3660,3200))
    // MARK: iPhones
    // original iPhone
    public static let i35o = Screen(diagonal: 3.5, resolution: (320,480), ppi: 163)
    // iPhone 4
    public static let i35 = Screen(diagonal: 3.5, resolution: (640,960), ppi: 326)
    // iPod Touch, iPhone 5
    public static let i4 = Screen(diagonal: 4, resolution: (640,1136), ppi: 326)
    // iPhone 6
    public static let i47 = Screen(diagonal: 4.7, resolution: (750,1334), ppi: 326)
    // iPhone 12 mini
    public static let i54 = Screen(diagonal: 5.4, resolution: (1080,2340), ppi: 476)
    // iPhone 6 Plus
    public static let i55 = Screen(diagonal: 5.5, resolution: (1080,1920), ppi: 401)
    // iPhone X
    public static let i58 = Screen(diagonal: 5.8, resolution: (1125,2436), ppi: 458)
    // iPhone Xs Max
    public static let i65 = Screen(diagonal: 6.5, resolution: (1242,2688), ppi: 458)
    // iPhone Xʀ
    public static let i61x828 = Screen(diagonal: 6.1, resolution: (828,1792), ppi: 326)
    // iPhone 11 Pro
    public static let i61x1125 = Screen(diagonal: 6.1, resolution: (1125,2436), ppi: 458)
    // iPhone 12 Pro, 13 Pro, 14
    public static let i61x1170 = Screen(diagonal: 6.1, resolution: (1170,2532), ppi: 460)
    // iPhone 14 Pro
    public static let i61x1179 = Screen(diagonal: 6.1, resolution: (1179,2556), ppi: 460)
    // iPhone 12 Pro Max, iPhone 14 Plus
    public static let i67x1284 = Screen(diagonal: 6.7, resolution: (1284,2778), ppi: 458)
    // iPhone 14,15 Pro Max
    public static let i67x1290 = Screen(diagonal: 6.7, resolution: (1290,2796), ppi: 460)
    // MARK: iPads
    // iPad 2
    public static let i97x768 = Screen(diagonal: 9.7, resolution: (768,1024), ppi: 132)
    // iPad 3
    public static let i97x1536 = Screen(diagonal: 9.7, resolution: (1536,2048), ppi: 264)
    // iPad Air 3rd gen
    public static let i105 = Screen(diagonal: 10.5, resolution: (1668,2224), ppi: 264)
    // iPad 7th gen
    public static let i102 = Screen(diagonal: 10.2, resolution: (1620,2160), ppi: 264)
    // iPad 10th gen
    public static let i109 = Screen(diagonal: 10.9, resolution: (1640,2360), ppi: 264)
    // iPad mini
    public static let i79x768 = Screen(diagonal: 7.9, resolution: (768,1024), ppi: 163)
    // iPad mini 2
    public static let i79x1536 = Screen(diagonal: 7.9, resolution: (1536,2048), ppi: 326)
    // iPad mini 6
    public static let i83 = Screen(diagonal: 8.3, resolution: (1488,2266), ppi: 326)
    // iPad Pro 11
    public static let i11 = Screen(diagonal: 11.0, resolution: (1668,2388), ppi: 264)
    // iPad Pro
    public static let i129 = Screen(diagonal: 12.9, resolution: (2048,2732), ppi: 264)
    // iPad Pro
    public static let i13 = Screen(diagonal: 13, resolution: (2064,2752), ppi: 264)
    // MARK: Watches
    public static let wUnknown = Screen(
        diagonal: 2.0,
        resolution: (396,484),
        ppi: 326) // placeholder
    public static let w38 = Screen(diagonal: 1.5, resolution: (272,340), ppi: 290) // 326?
    public static let w40 = Screen(diagonal: 1.8, resolution: (324,394), ppi: 326)
    public static let w41 = Screen(diagonal: 1.8, resolution: (352,430), ppi: 326)
    public static let w42 = Screen(diagonal: 1.65, resolution: (312,390), ppi: 303) // 326?
    public static let w44 = Screen(diagonal: 2.0, resolution: (368,448), ppi: 326)
    public static let w45 = Screen(diagonal: 2.0, resolution: (396,484), ppi: 326)
    public static let w49 = Screen(diagonal: 2.2, resolution: (410,502), ppi: 338)
    
    /**
     This enum describes the state of the orientation.
     - Landscape: The device is in Landscape Orientation
     - Portrait:  The device is in Portrait Orientation
     */
    public enum Orientation: Int, Hashable, SymbolRepresentable, CaseIterable, Sendable {
        case unknown = 0

        case portrait = 1 // Device oriented vertically, home button on the bottom

        case portraitUpsideDown = 2 // Device oriented vertically, home button on the top

        case landscapeLeft = 3 // Device oriented horizontally, home button on the right

        case landscapeRight = 4 // Device oriented horizontally, home button on the left

        case faceUp = 5 // Device oriented flat, face up

        case faceDown = 6 // Device oriented flat, face down

        public var symbolName: String {
            switch self {
            case .unknown:
                "questionmark.square"
            case .portrait:
                "rectangle.portrait"
            case .portraitUpsideDown:
                "rectangle.portrait.slash"
            case .landscapeLeft:
                "rectangle"
            case .landscapeRight:
                "rectangle.fill"
            case .faceUp:
                "square.fill"
            case .faceDown:
                "square.slash"
            }
        }
        
        public var isLandscape: Bool {
            return [.landscapeLeft, .landscapeRight].contains(self)
        }

        public var isPortrait: Bool {
            return [.portrait, .portraitUpsideDown].contains(self)
        }
    }
}
