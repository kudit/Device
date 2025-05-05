//
//  iPods.swift
//  Device
//
//  Created by Ben Ku on 4/21/25.
//

import Compatibility

public struct iPod: IdiomType, HasScreen {
    public let device: Device
    public init(knownDevice: Device) {
        self.device = knownDevice
    }

    public init(
        officialName: String,
        identifiers: [String],
        introduction: DateString,
        supportId: String,
        launchOSVersion: Version,
        unsupportedOSVersion: Version?,
        image: String?,
        capabilities: Capabilities = [],
        models: [String] = [],
        colors: [MaterialColor],
        cpu: CPU
    ) {
        device = Device(
            idiom: .pod,
            officialName: officialName,
            identifiers: identifiers,
            introduction: introduction,
            supportId: supportId,
            launchOSVersion: launchOSVersion,
            unsupportedOSVersion: unsupportedOSVersion,
            image: image,
            capabilities: capabilities.union(Device.Idiom.pod.capabilities),
            models: models,
            colors: colors,
            cpu: cpu
        )
    }
    
    init(identifier: String) {
        self.init(
            officialName: "Unknown iPod",
            identifiers: [identifier],
            introduction: .defaultBlank,
            supportId: .unknownSupportId,
            launchOSVersion: "0.0",
            unsupportedOSVersion: "0.0",
            image: nil,
            // capabilities
            // models
            colors: [.white],
            cpu: .unknown)
    }
    
    /// An SF Symbol name for an icon representing the device.  If no specific variant exists, uses a generic symbol for device idiom.
    public var symbolName: String {
        return "ipodtouch"
    }
    
    static let all = [
    
        iPod(
//            officialName: "iPod touch (1st generation)", // Apple tech specs page seems to have gone back to dropping 1st gen here.
            officialName: "iPod touch",
            identifiers: ["iPod1,1"],
            introduction: 2007.introductionYear,
            supportId: "112532",
            launchOSVersion: "1.0",
            unsupportedOSVersion: "4",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipod/ipod-touch/ipod-touch-1st-gen.png",
            capabilities: [.headphoneJack, .thirtyPin, .cameras([.twoMP])], // please check specs
            models: ["A1213"],
            colors: [.silver],
            cpu: .s5L8900),
        iPod(
            officialName: "iPod touch (2nd generation)",
            identifiers: ["iPod2,1"],
            introduction: 2008.introductionYear,
            supportId: "112319",
            launchOSVersion: "2.1",
            unsupportedOSVersion: "5",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipod/ipod-touch/ipod-touch-2nd-gen.png",
            capabilities: [.headphoneJack, .thirtyPin, .cameras([.twoMP])], // please check specs
            models: ["A1288", "A1319"],
            colors: [.silver],
            cpu: .s5L8720),
        iPod(
            officialName: "iPod touch (3rd generation)",
            identifiers: ["iPod3,1"],
            introduction: 2009.introductionYear,
            supportId: "pp115",
            launchOSVersion: "3.1.1",
            unsupportedOSVersion: "6",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipod/ipod-touch/ipod-touch-3rd-gen.png",
            capabilities: [.headphoneJack, .thirtyPin, .cameras([.threeMP])], // please check specs
            models: ["A1318"],
            colors: [.silver],
            cpu: .s5L8922),
        iPod(
            officialName: "iPod touch (4th generation)",
            identifiers: ["iPod4,1"],
            introduction: 2010.introductionYear,
            supportId: "112431",
            launchOSVersion: "4.1",
            unsupportedOSVersion: "7",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipod/ipod-touch/ipod-touch-4th-gen.png",
            capabilities: [.headphoneJack, .thirtyPin, .cameras([.iSight, .faceTimeHD720p])], // please check specs
            models: ["A1367"],
            colors: [.white, .black],
            cpu: .a4),
        iPod(
            officialName: "iPod touch (5th generation)",
            identifiers: ["iPod5,1"],
            introduction: 2012.introductionYear,
            supportId: "SP657",
            launchOSVersion: "6",
            unsupportedOSVersion: "10",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipod/ipod-touch/ipod-touch-5th-gen-second-release.png",
            models: ["A1509", "A1421"],
            colors: .iPodTouch5thGen,
            cpu: .a5),
        iPod(
            officialName: "iPod touch (5th generation 16 GB, Mid 2013)",
            identifiers: ["iPod5,1"],
            introduction: 2013.introductionYear,
            supportId: "118467",
            launchOSVersion: "6",
            unsupportedOSVersion: "10",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipod/ipod-touch/ipod-touch-5th-gen.png",
            models: ["A1509"],
            colors: .iPodTouch5thGen,
            cpu: .a5),
        iPod(
            officialName: "iPod touch (6th generation)",
            identifiers: ["iPod7,1"],
            introduction: 2015.introductionYear,
            supportId: "SP720",
            launchOSVersion: "8.4",
            unsupportedOSVersion: "13",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipod/ipod-touch/ipod-touch-6th-gen.png",
            models: ["A1574"],
            colors: .iPodTouch6thGen,
            cpu: .a8),
        iPod(
            officialName: "iPod touch (7th generation)",
            identifiers: ["iPod9,1"],
            introduction: 2019.introductionYear,
            supportId: "SP796",
            launchOSVersion: "12.3.1",
            unsupportedOSVersion: "16",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipod/ipod-touch/ipod-touch-7th-gen.jpg",
            models: ["A2178"],
            colors: .iPodTouch7thGen,
            cpu: .a10),
             
    ]
}
