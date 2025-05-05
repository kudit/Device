//
//  AppleWatches.swift
//  Device
//
//  Created by Ben Ku on 4/18/25.
//

import Compatibility

public struct AppleWatch: IdiomType, HasScreen, HasCellular {
    public let device: Device
    public init(knownDevice: Device) {
        self.device = knownDevice
    }

    public var bandSize: WatchSize.BandSize {
        watchSize.bandSize
    }
    public enum WatchSize: CaseNameConvertible, Sendable {
        case unknown
        case mm38
        case mm40
        case mm41
        case mm42
        case mm42s // 2024 series 10 small version
        case mm44
        case mm45
        case mm46
        case mm49 // ultra
        
        public enum BandSize: CaseNameConvertible, Sendable {
            case small // 38mm, 40mm, 41mm
            case large // 42mm, 44mm, 45mm, 49mm
        }
        public var bandSize: BandSize {
            switch self {
            case .mm38,.mm40, .mm41, .mm42s:
                return .small
            default: // everything else
                return .large
            }
        }
        public var screen: Screen {
            switch self {
            case .unknown: return .wUnknown // placeholder
            case .mm38: return .w38
            case .mm40: return .w40
            case .mm41: return .w41
            case .mm42: return .w42
            case .mm42s: return .w42s
            case .mm44: return .w44
            case .mm45: return .w45
            case .mm46: return .w46
            case .mm49: return .w49
            }
        }
    }
    
    public init(
        officialName: String,
        identifiers: [String],
        introduction: DateString? = nil,
        supportId: String,
        launchOSVersion: Version,
        unsupportedOSVersion: Version?,
        image: String?,
        capabilities: Capabilities = [],
        models: [String] = [],
        colors: [MaterialColor],
        cpu: CPU, // TODO: Add cellular?
        size: WatchSize
    ) {
        device = Device(
            idiom: .watch,
            officialName: officialName,
            identifiers: identifiers,
            introduction: introduction,
            supportId: supportId,
            launchOSVersion: launchOSVersion,
            unsupportedOSVersion: unsupportedOSVersion,
            image: image,
            capabilities: capabilities.union(Device.Idiom.watch.capabilities).union([.screen(size.screen), .watchSize(size)]),
            models: models,
            colors: colors,
            cpu: cpu
        )
    }
    
    init(identifier: String) {
        self.init(
            officialName: "Unknown  Watch",
            identifiers: [identifier],
            supportId: .unknownSupportId,
            launchOSVersion: "11",
            unsupportedOSVersion: nil,
            image: nil,
            colors: .default,
            cpu: .unknown,
            size: .unknown)
    }
    
    /// An SF Symbol name for an icon representing the device.  If no specific variant exists, uses a generic symbol for device idiom.
    public var symbolName: String {
        return "applewatch"
    }
    
    public var watchSize: WatchSize {
        return capabilities.watchSize ?? .unknown // should always be present
    }

    static let all = [ // since various materials use same identifier, by convention, use the aluminum versions for smaller and most expensive versions for larger body version.

        AppleWatch(
            officialName: "Apple Watch (1st generation) 38mm", // Series 0
            identifiers: ["Watch1,1"],
            introduction: 2015.introductionYear,
            supportId: "SP735",
            launchOSVersion: "1",
            unsupportedOSVersion: "5",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/1st-gen-apple-watch-stainless.png",
            capabilities: [.force3DTouch],
            models: ["A1553"],
            colors: .watch0,
            cpu: .s1,
            size: .mm38),
        AppleWatch(
            officialName: "Apple Watch (1st generation) 42mm", // Series 0
            identifiers: ["Watch1,2"],
            introduction: 2015.introductionYear,
            supportId: "SP735",
            launchOSVersion: "1",
            unsupportedOSVersion: "5",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/1st-gen-apple-watch-edition-gold.png",
            capabilities: [.force3DTouch],
            colors: .watch0,
            cpu: .s1,
            size: .mm42),
        AppleWatch(
            officialName: "Apple Watch Series 1 38mm",
            identifiers: ["Watch2,6"],
            introduction: 2016.introductionYear,
            supportId: "SP745",
            launchOSVersion: "3",
            unsupportedOSVersion: "7",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/watch-series1-aluminum.png",
            capabilities: [.force3DTouch],
            models: ["A1802"],
            colors: .watch1,
            cpu: .s1p,
            size: .mm38),
        AppleWatch(
            officialName: "Apple Watch Series 1 42mm",
            identifiers: ["Watch2,7"],
            introduction: 2016.introductionYear,
            supportId: "SP745",
            launchOSVersion: "3",
            unsupportedOSVersion: "7",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/watch-series1-aluminum.png",
            capabilities: [.force3DTouch],
            colors: .watch1,
            cpu: .s1p,
            size: .mm42),
        AppleWatch(
            officialName: "Apple Watch Series 2 38mm",
            identifiers: ["Watch2,3"],
            introduction: 2016.introductionYear,
            supportId: "SP746",
            launchOSVersion: "3",
            unsupportedOSVersion: "7",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/watch-series2-aluminum.png",
            capabilities: [.force3DTouch],
            models: ["A1757", "A1816"], // second is Edition version.
            colors: .watch2,
            cpu: .s2,
            size: .mm38),
        AppleWatch(
            officialName: "Apple Watch Series 2 42mm",
            identifiers: ["Watch2,4"],
            introduction: 2016.introductionYear,
            supportId: "SP746",
            launchOSVersion: "3",
            unsupportedOSVersion: "7",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/watch-series2-edition.png",
            capabilities: [.force3DTouch],
            colors: .watch2,
            cpu: .s2,
            size: .mm42),
        AppleWatch(
            officialName: "Apple Watch Series 3 38mm",
            identifiers: ["Watch3,1", "Watch3,3"],
            introduction: 2017.introductionYear,
            supportId: "SP766",
            launchOSVersion: "4",
            unsupportedOSVersion: "9",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/series3-apple-watch-gps-aluminum.png",
            capabilities: [.force3DTouch],
            models: ["A1858", "A1860"],
            colors: .watch3,
            cpu: .s3,
            size: .mm38),
        AppleWatch(
            officialName: "Apple Watch Series 3 42mm",
            identifiers: ["Watch3,2", "Watch3,4"],
            introduction: 2017.introductionYear,
            supportId: "SP766",
            launchOSVersion: "4",
            unsupportedOSVersion: "9",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/series3-apple-watch-cellular-gps-ceramic.png",
            capabilities: [.force3DTouch],
            colors: .watch3,
            cpu: .s3,
            size: .mm42),
        AppleWatch(
            officialName: "Apple Watch Series 4 40mm",
            identifiers: ["Watch4,1", "Watch4,3"],
            introduction: 2018.introductionYear,
            supportId: "SP778",
            launchOSVersion: "5",
            unsupportedOSVersion: "11",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/series4-apple-watch-aluminum-gps.png",
            capabilities: [.force3DTouch],
            models: ["A1977", "A1975"],
            colors: .watch4,
            cpu: .s4,
            size: .mm40),
        AppleWatch(
            officialName: "Apple Watch Series 4 44mm",
            identifiers: ["Watch4,2", "Watch4,4"],
            introduction: 2018.introductionYear,
            supportId: "SP778",
            launchOSVersion: "5",
            unsupportedOSVersion: "11",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/series4-apple-watch-stainless-gps-cellular.png",
            capabilities: [.force3DTouch],
            colors: .watch4,
            cpu: .s4,
            size: .mm44),
        AppleWatch(
            officialName: "Apple Watch Series 5 40mm",
            identifiers: ["Watch5,1", "Watch5,3"],
            introduction: 2019.introductionYear,
            supportId: "SP808",
            launchOSVersion: "6",
            unsupportedOSVersion: "11",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/series5-apple-watch-aluminum-gps.png",
            capabilities: [.force3DTouch, .alwaysOnDisplay],
            models: ["A2092", "A2094"],
            colors: .watch5,
            cpu: .s5,
            size: .mm40),
        AppleWatch(
            officialName: "Apple Watch Series 5 44mm",
            identifiers: ["Watch5,2", "Watch5,4"],
            introduction: 2019.introductionYear,
            supportId: "SP808",
            launchOSVersion: "6",
            unsupportedOSVersion: "11",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/series5-apple-watch-titanium-edition.png",
            capabilities: [.force3DTouch, .alwaysOnDisplay],
            colors: .watch5,
            cpu: .s5,
            size: .mm44),
        AppleWatch(
            officialName: "Apple Watch Series 6 40mm",
            identifiers: ["Watch6,1", "Watch6,3"],
            introduction: 2020.introductionYear,
            supportId: "SP826",
            launchOSVersion: "7",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/apple-watch-series6-aluminum-gps-colors.png",
            capabilities: [.alwaysOnDisplay],
            models: ["A2291", "A2293", "A2375"],
            colors: .watch6,
            cpu: .s6,
            size: .mm40),
        AppleWatch(
            officialName: "Apple Watch Series 6 44mm",
            identifiers: ["Watch6,2", "Watch6,4"],
            introduction: 2020.introductionYear,
            supportId: "SP826",
            launchOSVersion: "7",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/apple-watch-series6-titanium-colors.png",
            capabilities: [.alwaysOnDisplay],
            models: ["A2294", "A2376"],
            colors: .watch6,
            cpu: .s6,
            size: .mm44),
        AppleWatch(
            officialName: "Apple Watch SE 40mm",
            identifiers: ["Watch5,9", "Watch5,11"],
            introduction: 2020.introductionYear,
            supportId: "SP827",
            launchOSVersion: "7",
            unsupportedOSVersion: "11",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/apple-watch-series6-000-aluminum-gps-colors.png",
            models: ["A2351", "A2353"],
            colors: .watchSE,
            cpu: .s5,
            size: .mm40),
        AppleWatch(
            officialName: "Apple Watch SE 44mm",
            identifiers: ["Watch5,10", "Watch5,12"],
            introduction: 2020.introductionYear,
            supportId: "SP827",
            launchOSVersion: "7",
            unsupportedOSVersion: "11",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/apple-watch-series6-000-aluminum-gps-cellular-colors.png",
            colors: .watchSE,
            cpu: .s5,
            size: .mm44),
        AppleWatch(
            officialName: "Apple Watch Series 7 41mm",
            identifiers: ["Watch6,6", "Watch6,8"],
            introduction: 2021.introductionYear,
            supportId: "SP860",
            launchOSVersion: "8",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/2021-apple-watch-series7-aluminum-gps.png",
            capabilities: [.alwaysOnDisplay],
            models: ["A2473", "A2475"],
            colors: .watch7,
            cpu: .s7,
            size: .mm41),
        AppleWatch(
            officialName: "Apple Watch Series 7 45mm",
            identifiers: ["Watch6,7", "Watch6,9"],
            introduction: 2021.introductionYear,
            supportId: "SP860",
            launchOSVersion: "8",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/2021-apple-watch-series7-titanium-gps-cellular.png",
            capabilities: [.alwaysOnDisplay],
            colors: .watch7,
            cpu: .s7,
            size: .mm45),
        AppleWatch(
            officialName: "Apple Watch Series 8 41mm",
            identifiers: ["Watch6,14", "Watch6,16"],
            introduction: 2022.introductionYear,
            supportId: "SP878",
            launchOSVersion: "9",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/fall-2022-watch-series8-aluminum-gps.png",
            capabilities: [.alwaysOnDisplay],
            models: ["A2770", "A2772"],
            colors: .watch8,
            cpu: .s8,
            size: .mm41),
        AppleWatch(
            officialName: "Apple Watch Series 8 45mm",
            identifiers: ["Watch6,15", "Watch6,17"],
            introduction: 2022.introductionYear,
            supportId: "SP878",
            launchOSVersion: "9",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/fall-2022-watch-series8-stainless-gps-cellular.png",
            capabilities: [.alwaysOnDisplay],
            colors: .watch8,
            cpu: .s8,
            size: .mm45),
        AppleWatch(
            officialName: "Apple Watch SE (2nd generation) 40mm",
            identifiers: ["Watch6,10", "Watch6,12"],
            introduction: 2022.introductionYear,
            supportId: "SP877",
            launchOSVersion: "9",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/fall-2022-watch-series8-se-gps.png",
            models: ["A2722", "A2726"],
            colors: .watchSE2,
            cpu: .s8,
            size: .mm40),
        AppleWatch(
            officialName: "Apple Watch SE (2nd generation) 44mm",
            identifiers: ["Watch6,11", "Watch6,13"],
            introduction: 2022.introductionYear,
            supportId: "SP877",
            launchOSVersion: "9",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/fall-2022-watch-series8-se-gps-cellular.png",
            colors: .watchSE2,
            cpu: .s8,
            size: .mm44),
        AppleWatch(
            officialName: "Apple Watch Ultra",
            identifiers: ["Watch6,18"],
            introduction: 2022.introductionYear,
            supportId: "SP879",
            launchOSVersion: "9",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/fall-2022-apple-watch-ultra.png",
            capabilities: [.alwaysOnDisplay, .actionButton],
            colors: .watchUltra,
            cpu: .s8,
            size: .mm49),
        AppleWatch(
            officialName: "Apple Watch Series 9 41mm",
            identifiers: ["Watch7,1", "Watch7,3"],
            introduction: 2023.introductionYear,
            supportId: "SP905",
            launchOSVersion: "10.0.1",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/apple-watch-series-9-gps.png",
            capabilities: [.alwaysOnDisplay, .crashDetection],
            models: ["A2978", "A2982"],
            colors: .watch9,
            cpu: .s9,
            size: .mm41),
        AppleWatch(
            officialName: "Apple Watch Series 9 45mm",
            identifiers: ["Watch7,2", "Watch7,4"],
            introduction: 2023.introductionYear,
            supportId: "SP905",
            launchOSVersion: "10.0.1",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/apple-watch-series-9-stainless-gps-cellular.png",
            capabilities: [.alwaysOnDisplay, .crashDetection],
//            models: ["A2980"], // TODO: Check
            colors: .watch9,
            cpu: .s9,
            size: .mm45),
        AppleWatch(
            officialName: "Apple Watch Ultra 2",
            identifiers: ["Watch7,5"],
            introduction: 2023.introductionYear,
            supportId: "SP906",
            launchOSVersion: "10.0.1",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/apple-watch-ultra-2-colors.png",
            capabilities: [.alwaysOnDisplay, .actionButton, .crashDetection],
            models: ["A2986", "A2987"],
            colors: .watchUltra2,
            cpu: .s9,
            size: .mm49),
        AppleWatch(
            officialName: "Apple Watch Series 10 42mm",
            identifiers: ["Watch7,8", "Watch7,10"],
            introduction: 2024.introductionYear,
            supportId: "121202",
            launchOSVersion: "11",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/apple-watch-series-10-aluminum-gps.png",
            capabilities: [.alwaysOnDisplay, .crashDetection],
            models: ["A2997", "A3001"],
            colors: .watch10,
            cpu: .s10,
            size: .mm42s),
        AppleWatch(
            officialName: "Apple Watch Series 10 46mm",
            identifiers: ["Watch7,9", "Watch7,11"],
            introduction: 2024.introductionYear,
            supportId: "121202",
            launchOSVersion: "11",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/apple-watch-series-10-titanium.png",
            capabilities: [.alwaysOnDisplay, .crashDetection],
            colors: .watch10,
            cpu: .s10,
            size: .mm46),
    ]
}
