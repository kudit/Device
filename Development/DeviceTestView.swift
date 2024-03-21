import SwiftUI
#if canImport(Device) // since this is needed in XCode but is unavailable in Playgrounds.
import Device
#endif

extension Device.Idiom {
    var color: Color {
        switch self {
        case .unspecified:
                .gray
        case .mac:
                .blue
        case .pod:
                .mint
        case .phone:
                .red
        case .pad:
                .purple
        case .tv:
                .brown
        case .homePod:
                .pink
        case .watch:
                .red
        case .carPlay:
                .green
        case .vision:
                .yellow
        }
    }
}

struct TimeClockView: View {
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State var time = Date()
    var body: some View {
        VStack {
            Text("Current time: \(time.formatted(date: .long, time: .complete))")
            if let battery = Device.current.battery {
                Text("Battery Info: \(battery.description)")
                HStack {
                    BatteryView(battery: battery, fontSize: 80)
                    Image(systemName: Device.current.symbolName)
                        .font(.system(size: 80))
                }
            } else {
                Text("No Battery")
                Image(systemName: Device.current.symbolName)
                    .font(.system(size: 80))
            }
        }
        .onReceive(timer, perform: { _ in
            //debug("updating \(time)")
            time = Date()
        })
    }
}

struct StackedLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            configuration.icon.font(.title2)
            configuration.title.font(.caption2)
        }
    }
}

struct Placard: View {
    @State var color = Color.gray
    var body: some View {
        // if platform missing, this causes crash.  Also, this needs the stroke(_:lineWidth:antialiased version which is only iOS 17+ to work in previews.
        if #available(iOS 17.0, macOS 14.0, macCatalyst 17.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *) {
            return RoundedRectangle(cornerRadius: 10)
                .stroke(.primary, lineWidth: 3)
                .fill(color)
        } else {
            return RoundedRectangle(cornerRadius: 10)
                .strokeBorder(.primary, lineWidth: 3)
                .background(RoundedRectangle(cornerRadius: 10).fill(color))
        }
    }
}

struct TestCard: View {
    @State var label = "Unknown"
    @State var highlighted = true
    @State var color = Color.gray
    @State var symbolName = String.symbolUnknownEnvironment
    var body: some View {
        Placard(color: highlighted ? color : .clear)
            .overlay {
                Label(label, systemImage: symbolName)
                    .font(.caption)
                    .symbolRenderingMode(highlighted ? .hierarchical : .monochrome)
            }
    }
}

public struct DeviceTestView: View {
    public var version: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "Unknown"        
    }
    public var idiomList: some View {
        ForEach(Device.Idiom.allCases) { idiom in
            TestCard(
                label: idiom.description,
                highlighted: Device.current.idiom == idiom,
                color: Device.current.idiom.color,
                symbolName: idiom.symbolName)
        }
    }
    
    public var body: some View {
        ScrollView {
            VStack {
                Group { // so not more than 7 items
                    Text("Kudit/Device v\(version)")
                    TimeClockView()
                    Text("Current device: \(Device.current.description)")
                    Text("Identifier: \(Device.current.identifier)")
                    Text("Device Name: \(Device.current.name ?? "nil")")
                    Text("System Name: \(Device.current.systemName ?? "nil")")
                    Button("Import") {
                        importContent()
                    }
                }
                Group {
                    HStack {
                        //                    TestCard(label: "TEST", highlighted: true, color: .yellow, symbolName: "star.fill")
                        TestCard(
                            label: "Preview",
                            highlighted: Device.current.isPreview,
                            color: .orange,
                            symbolName: .symbolPreview
                        )
                        TestCard(
                            label: "Playground",
                            highlighted: Device.current.isPlayground,
                            color: .pink,
                            symbolName: .symbolPlayground)
                        TestCard(
                            label: "Simulator",
                            highlighted: Device.current.isSimulator,
                            color: .blue,
                            symbolName: .symbolSimulator)
                        TestCard(
                            label: "Real Device",
                            highlighted: Device.current.isRealDevice,
                            color: .green,
                            symbolName: .symbolRealDevice)
                        if [.mac, .vision].contains(Device.current.idiom) {
                            TestCard(
                                label: "Designed for iPad",
                                highlighted: Device.current.isDesignedForiPad,
                                color: .purple,
                                symbolName: .symbolDesignedForiPad)
                        }
                    }
                    .labelStyle(StackedLabelStyle())
                    .frame(height: 60)
                    HStack {
                        VStack {
                            BatteryTestView(useSystemColors: true, fontSize: 40)
                        }
                        VStack {
                            idiomList
                        }
                        VStack {
                            BatteryTestView(includePercent: false, fontSize: 40)
                        }
                    }
                }
                .padding()
                Spacer()
            }
        }
    }
    
    enum MaterialColor {
        case silver, pink, blue, green
    }
    
    struct MacLookup: Codable {
        var models: [String] // identifiers
        var kind: String // label
        var colors: [String] // Convert to MaterialColors
        var name: String
        var variant: String
        var parts: [String] // part numbers MGTF3xx/a
    }
    func importContent() {
        let macsRaw = """
[
    {
        "models" : [
            "iMac21,2"
        ],
        "kind" : "iMac",
        "colors" : [
            "Silver",
            "pink",
            "blue",
            "green"
        ],
        "name" : "iMac (24-inch, M1, 2021)",
        "variant" : "24-inch, M1, 2021",
        "parts" : [
            "MGTF3xx/a",
            "MJV83xx/a",
            "MJV93xx/a",
            "MJVA3xx/a"
        ]
    },
    {
        "models" : [
            "iMac20,1",
            "iMac20,2"
        ],
        "kind" : "iMac",
        "colors" : [
            
        ],
        "name" : "iMac (Retina 5K, 27-inch, 2020)",
        "variant" : "Retina 5K, 27-inch, 2020",
        "parts" : [
            "MXWT2xx/A",
            "MXWU2xx/A",
            "MXWV2xx/A"
        ]
    },
    {
        "models" : [
            "iMac19,1"
        ],
        "kind" : "iMac",
        "colors" : [
            
        ],
        "name" : "iMac (Retina 5K, 27-inch, 2019)",
        "variant" : "Retina 5K, 27-inch, 2019",
        "parts" : [
            "MRQYxx/A",
            "MRR0xx/A",
            "MRR1xx/A"
        ]
    },
    {
        "models" : [
            "iMac19,2"
        ],
        "kind" : "iMac",
        "colors" : [
            
        ],
        "name" : "iMac (Retina 4K, 21.5-inch, 2019)",
        "variant" : "Retina 4K, 21.5-inch, 2019",
        "parts" : [
            "MRT3xx/A",
            "MRT4xx/A",
            "MHK23xx/A"
        ]
    },
    {
        "models" : [
            "iMacPro1,1"
        ],
        "kind" : "iMac Pro",
        "colors" : [
            
        ],
        "name" : "iMac Pro",
        "variant" : "",
        "parts" : [
            "MQ2Y2xx/A",
            "MHLV3xx/A"
        ]
    },
    {
        "models" : [
            "iMac18,3"
        ],
        "kind" : "iMac",
        "colors" : [
            
        ],
        "name" : "iMac (Retina 5K, 27-inch, 2017)",
        "variant" : "Retina 5K, 27-inch, 2017",
        "parts" : [
            "MNE92xx/A",
            "MNEA2xx/A",
            "MNED2xx/A"
        ]
    },
    {
        "models" : [
            "iMac18,2"
        ],
        "kind" : "iMac",
        "colors" : [
            
        ],
        "name" : "iMac (Retina 4K, 21.5-inch, 2017)",
        "variant" : "Retina 4K, 21.5-inch, 2017",
        "parts" : [
            "MNDY2xx/A",
            "MNE02xx/A"
        ]
    },
    {
        "models" : [
            "iMac18,1"
        ],
        "kind" : "iMac",
        "colors" : [
            
        ],
        "name" : "iMac (21.5-inch, 2017)",
        "variant" : "21.5-inch, 2017",
        "parts" : [
            "MMQA2xx/A",
            "MHK03xx/A"
        ]
    },
    {
        "models" : [
            "iMac17,1"
        ],
        "kind" : "iMac",
        "colors" : [
            
        ],
        "name" : "iMac (Retina 5K, 27-inch, Late 2015)",
        "variant" : "Retina 5K, 27-inch, Late 2015",
        "parts" : [
            "MK462xx/A",
            "MK472xx/A",
            "MK482xx/A"
        ]
    },
    {
        "models" : [
            "iMac16,2"
        ],
        "kind" : "iMac",
        "colors" : [
            
        ],
        "name" : "iMac (Retina 4K, 21.5-inch, Late 2015)",
        "variant" : "Retina 4K, 21.5-inch, Late 2015",
        "parts" : [
            "MK452xx/A"
        ]
    },
    {
        "models" : [
            "iMac16,1"
        ],
        "kind" : "iMac",
        "colors" : [
            
        ],
        "name" : "iMac (21.5-inch, Late 2015)",
        "variant" : "21.5-inch, Late 2015",
        "parts" : [
            "MK142xx/A",
            "MK442xx/A"
        ]
    },
    {
        "models" : [
            "iMac15,1"
        ],
        "kind" : "iMac",
        "colors" : [
            
        ],
        "name" : "iMac (Retina 5K, 27-inch, Mid 2015)",
        "variant" : "Retina 5K, 27-inch, Mid 2015",
        "parts" : [
            "MF885xx/A"
        ]
    },
    {
        "models" : [
            "iMac15,1"
        ],
        "kind" : "iMac",
        "colors" : [
            
        ],
        "name" : "iMac (Retina 5K, 27-inch, Late 2014)",
        "variant" : "Retina 5K, 27-inch, Late 2014",
        "parts" : [
            
        ]
    },
    {
        "models" : [
            "iMac14,4"
        ],
        "kind" : "iMac",
        "colors" : [
            
        ],
        "name" : "iMac (21.5-inch, Mid 2014)",
        "variant" : "21.5-inch, Mid 2014",
        "parts" : [
            
        ]
    },
    {
        "models" : [
            "iMac14,2"
        ],
        "kind" : "iMac",
        "colors" : [
            
        ],
        "name" : "iMac (27-inch, Late 2013)",
        "variant" : "27-inch, Late 2013",
        "parts" : [
            
        ]
    },
    {
        "models" : [
            "iMac14,1"
        ],
        "kind" : "iMac",
        "colors" : [
            
        ],
        "name" : "iMac (21.5-inch, Late 2013)",
        "variant" : "21.5-inch, Late 2013",
        "parts" : [
            
        ]
    },
    {
        "models" : [
            "iMac13,2"
        ],
        "kind" : "iMac",
        "colors" : [
            
        ],
        "name" : "iMac (27-inch, Late 2012)",
        "variant" : "27-inch, Late 2012",
        "parts" : [
            
        ]
    },
    {
        "models" : [
            "iMac13,1"
        ],
        "kind" : "iMac",
        "colors" : [
            
        ],
        "name" : "iMac (21.5-inch, Late 2012)",
        "variant" : "21.5-inch, Late 2012",
        "parts" : [
            
        ]
    },
    {
        "models" : [
            "iMac12,2"
        ],
        "kind" : "iMac",
        "colors" : [
            
        ],
        "name" : "iMac (27-inch, Mid 2011)",
        "variant" : "27-inch, Mid 2011",
        "parts" : [
            
        ]
    },
    {
        "models" : [
            "iMac12,1"
        ],
        "kind" : "iMac",
        "colors" : [
            
        ],
        "name" : "iMac (21.5-inch, Mid 2011)",
        "variant" : "21.5-inch, Mid 2011",
        "parts" : [
            
        ]
    },
    {
        "models" : [
            "iMac11,3"
        ],
        "kind" : "iMac",
        "colors" : [
            
        ],
        "name" : "iMac (27-inch, Mid 2010)",
        "variant" : "27-inch, Mid 2010",
        "parts" : [
            
        ]
    },
    {
        "models" : [
            "iMac11,2"
        ],
        "kind" : "iMac",
        "colors" : [
            
        ],
        "name" : "iMac (21.5-inch, Mid 2010)",
        "variant" : "21.5-inch, Mid 2010",
        "parts" : [
            
        ]
    },
    {
        "models" : [
            "iMac10,1"
        ],
        "kind" : "iMac",
        "colors" : [
            
        ],
        "name" : "iMac (27-inch, Late 2009)",
        "variant" : "27-inch, Late 2009",
        "parts" : [
            
        ]
    },
    {
        "models" : [
            "iMac10,1"
        ],
        "kind" : "iMac",
        "colors" : [
            
        ],
        "name" : "iMac (21.5-inch, Late 2009)",
        "variant" : "21.5-inch, Late 2009",
        "parts" : [
            
        ]
    },
    {
        "models" : [
            "iMac9,1"
        ],
        "kind" : "iMac",
        "colors" : [
            
        ],
        "name" : "iMac (24-inch, Early 2009)",
        "variant" : "24-inch, Early 2009",
        "parts" : [
            
        ]
    },
    {
        "models" : [
            "iMac9,1"
        ],
        "kind" : "iMac",
        "colors" : [
            
        ],
        "name" : "iMac (20-inch, Early 2009)",
        "variant" : "20-inch, Early 2009",
        "parts" : [
            
        ]
    },
    {
        "models" : [
            "MacBook10,1"
        ],
        "kind" : "MacBook",
        "colors" : [
            "Rose gold",
            "space gray",
            "gold",
            "silver"
        ],
        "name" : "MacBook (Retina, 12-inch, 2017)",
        "variant" : "Retina, 12-inch, 2017",
        "parts" : [
            "MNYF2XX/A",
            "MNYG2XX/A",
            "MNYH2XX/A",
            "MNYJ2XX/A",
            "MNYK2XX/A",
            "MNYL2XX/A",
            "MNYM2XX/A",
            "MNYN2XX/A"
        ]
    },
    {
        "models" : [
            "MacBook9,1"
        ],
        "kind" : "MacBook",
        "colors" : [
            "Rose gold",
            "space gray",
            "gold",
            "silver"
        ],
        "name" : "MacBook (Retina, 12-inch, Early 2016)",
        "variant" : "Retina, 12-inch, Early 2016",
        "parts" : [
            "MLH72xx/A",
            "MLH82xx/A",
            "MLHA2xx/A",
            "MLHC2xx/A",
            "MLHE2xx/A",
            "MLHF2xx/A",
            "MMGL2xx/A",
            "MMGM2xx/A"
        ]
    },
    {
        "models" : [
            "MacBook8,1"
        ],
        "kind" : "MacBook",
        "colors" : [
            "Space gray",
            "gold",
            "silver"
        ],
        "name" : "MacBook (Retina, 12-inch, Early 2015)",
        "variant" : "Retina, 12-inch, Early 2015",
        "parts" : [
            "MF855xx/A",
            "MF865xx/A",
            "MJY32xx/A",
            "MJY42xx/A",
            "MK4M2xx/A",
            "MK4N2xx/A"
        ]
    },
    {
        "models" : [
            "MacBook7,1"
        ],
        "kind" : "MacBook",
        "colors" : [
            
        ],
        "name" : "MacBook (13-inch, Mid 2010)",
        "variant" : "13-inch, Mid 2010",
        "parts" : [
            "MC516xx/A"
        ]
    },
    {
        "models" : [
            "MacBook6,1"
        ],
        "kind" : "MacBook",
        "colors" : [
            
        ],
        "name" : "MacBook (13-inch, Late 2009)",
        "variant" : "13-inch, Late 2009",
        "parts" : [
            "MC207xx/A"
        ]
    },
    {
        "models" : [
            "MacBook5,2"
        ],
        "kind" : "MacBook",
        "colors" : [
            
        ],
        "name" : "MacBook (13-inch, Mid 2009)",
        "variant" : "13-inch, Mid 2009",
        "parts" : [
            "MC240xx/A"
        ]
    },
    {
        "models" : [
            "MacBook5,2"
        ],
        "kind" : "MacBook",
        "colors" : [
            
        ],
        "name" : "MacBook (13-inch, Early 2009)",
        "variant" : "13-inch, Early 2009",
        "parts" : [
            "MB881xx/A"
        ]
    },
    {
        "models" : [
            "Mac14,2"
        ],
        "kind" : "MacBook Air",
        "colors" : [
            "Silver",
            "starlight",
            "space gray",
            "midnight"
        ],
        "name" : "MacBook Air (M2, 2022)",
        "variant" : "M2, 2022",
        "parts" : [
            "MLXW3xx/A",
            "MLXX3xx/A",
            "MLXY3xx/A",
            "MLY03xx/A",
            "MLY13xx/A",
            "MLY23xx/A",
            "MLY33xx/A",
            "MLY43xx/A"
        ]
    },
    {
        "models" : [
            "MacBookAir10,1"
        ],
        "kind" : "MacBook Air",
        "colors" : [
            "Space gray",
            "gold",
            "silver"
        ],
        "name" : "MacBook Air (M1, 2020)",
        "variant" : "M1, 2020",
        "parts" : [
            "MGN63xx/A",
            "MGN93xx/A",
            "MGND3xx/A",
            "MGN73xx/A",
            "MGNA3xx/A",
            "MGNE3xx/A"
        ]
    },
    {
        "models" : [
            "MacBookAir9,1"
        ],
        "kind" : "MacBook Air",
        "colors" : [
            "Space gray",
            "gold",
            "silver"
        ],
        "name" : "MacBook Air (Retina, 13-inch, 2020)",
        "variant" : "Retina, 13-inch, 2020",
        "parts" : [
            "MVH22xx/A",
            "MVH42xx/A",
            "MVH52xx/A",
            "MWTJ2xx/A",
            "MWTK2xx/A",
            "MWTL2xx/A"
        ]
    },
    {
        "models" : [
            "MacBookAir8,2"
        ],
        "kind" : "MacBook Air",
        "colors" : [
            "Space gray",
            "gold",
            "silver"
        ],
        "name" : "MacBook Air (Retina, 13-inch, 2019)",
        "variant" : "Retina, 13-inch, 2019",
        "parts" : [
            "MVFH2xx/A",
            "MVFJ2xx/A",
            "MVFK2xx/A",
            "MVFL2xx/A",
            "MVFM2xx/A",
            "MVFN2xx/A",
            "MVH62xx/A",
            "MVH82xx/A"
        ]
    },
    {
        "models" : [
            "MacBookAir8,1"
        ],
        "kind" : "MacBook Air",
        "colors" : [
            "Space gray",
            "gold",
            "silver"
        ],
        "name" : "MacBook Air (Retina, 13-inch, 2018)",
        "variant" : "Retina, 13-inch, 2018",
        "parts" : [
            "MRE82xx/A",
            "MREA2xx/A",
            "MREE2xx/A",
            "MRE92xx/A",
            "MREC2xx/A",
            "MREF2xx/A",
            "MUQT2xx/A",
            "MUQU2xx/A",
            "MUQV2xx/A"
        ]
    },
    {
        "models" : [
            "MacBookAir7,2"
        ],
        "kind" : "MacBook Air",
        "colors" : [
            
        ],
        "name" : "MacBook Air (13-inch, 2017)",
        "variant" : "13-inch, 2017",
        "parts" : [
            "MQD32xx/A",
            "MQD42xx/A",
            "MQD52xx/A"
        ]
    },
    {
        "models" : [
            "MacBookAir7,2"
        ],
        "kind" : "MacBook Air",
        "colors" : [
            
        ],
        "name" : "MacBook Air (13-inch, Early 2015)",
        "variant" : "13-inch, Early 2015",
        "parts" : [
            "MJVE2xx/A",
            "MJVG2xx/A",
            "MMGF2xx/A",
            "MMGG2xx/A"
        ]
    },
    {
        "models" : [
            "MacBookAir7,1"
        ],
        "kind" : "MacBook Air",
        "colors" : [
            
        ],
        "name" : "MacBook Air (11-inch, Early 2015)",
        "variant" : "11-inch, Early 2015",
        "parts" : [
            "MJVM2xx/A",
            "MJVP2xx/A"
        ]
    },
    {
        "models" : [
            "MacBookAir6,2"
        ],
        "kind" : "MacBook Air",
        "colors" : [
            
        ],
        "name" : "MacBook Air (13-inch, Early 2014)",
        "variant" : "13-inch, Early 2014",
        "parts" : [
            "MD760xx/B",
            "MD761xx/B"
        ]
    },
    {
        "models" : [
            "MacBookAir6,1"
        ],
        "kind" : "MacBook Air",
        "colors" : [
            
        ],
        "name" : "MacBook Air (11-inch, Early 2014)",
        "variant" : "11-inch, Early 2014",
        "parts" : [
            "MD711xx/B",
            "MD712xx/B"
        ]
    },
    {
        "models" : [
            "MacBookAir6,2"
        ],
        "kind" : "MacBook Air",
        "colors" : [
            
        ],
        "name" : "MacBook Air (13-inch, Mid 2013)",
        "variant" : "13-inch, Mid 2013",
        "parts" : [
            "MD760xx/A",
            "MD761xx/A"
        ]
    },
    {
        "models" : [
            "MacBookAir6,1"
        ],
        "kind" : "MacBook Air",
        "colors" : [
            
        ],
        "name" : "MacBook Air (11-inch, Mid 2013)",
        "variant" : "11-inch, Mid 2013",
        "parts" : [
            "MD711xx/A",
            "MD712xx/A"
        ]
    },
    {
        "models" : [
            "MacBookAir5,2"
        ],
        "kind" : "MacBook Air",
        "colors" : [
            
        ],
        "name" : "MacBook Air (13-inch, Mid 2012)",
        "variant" : "13-inch, Mid 2012",
        "parts" : [
            "MD231xx/A",
            "MD232xx/A"
        ]
    },
    {
        "models" : [
            "MacBookAir5,1"
        ],
        "kind" : "MacBook Air",
        "colors" : [
            
        ],
        "name" : "MacBook Air (11-inch, Mid 2012)",
        "variant" : "11-inch, Mid 2012",
        "parts" : [
            "MD223xx/A",
            "MD224xx/A"
        ]
    },
    {
        "models" : [
            "MacBookAir4,2"
        ],
        "kind" : "MacBook Air",
        "colors" : [
            
        ],
        "name" : "MacBook Air (13-inch, Mid 2011)",
        "variant" : "13-inch, Mid 2011",
        "parts" : [
            "MC965xx/A",
            "MC966xx/A"
        ]
    },
    {
        "models" : [
            "MacBookAir4,1"
        ],
        "kind" : "MacBook Air",
        "colors" : [
            
        ],
        "name" : "MacBook Air (11-inch, Mid 2011)",
        "variant" : "11-inch, Mid 2011",
        "parts" : [
            "MC968xx/A",
            "MC969xx/A"
        ]
    },
    {
        "models" : [
            "MacBookAir3,2"
        ],
        "kind" : "MacBook Air",
        "colors" : [
            
        ],
        "name" : "MacBook Air (13-inch, Late 2010)",
        "variant" : "13-inch, Late 2010",
        "parts" : [
            "MC503xx/A",
            "MC504xx/A"
        ]
    },
    {
        "models" : [
            "MacBookAir3,1"
        ],
        "kind" : "MacBook Air",
        "colors" : [
            
        ],
        "name" : "MacBook Air (11-inch, Late 2010)",
        "variant" : "11-inch, Late 2010",
        "parts" : [
            "MC505xx/A",
            "MC506xx/A"
        ]
    },
    {
        "models" : [
            "MacBookAir2,1"
        ],
        "kind" : "MacBook Air",
        "colors" : [
            
        ],
        "name" : "MacBook Air (Mid 2009)",
        "variant" : "Mid 2009",
        "parts" : [
            "MC505xx/A",
            "MC233xx/A",
            "MC234xx/A"
        ]
    },
    {
        "models" : [
            "Mac14,5",
            "Mac14,9"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            "Silver",
            "space gray"
        ],
        "name" : "MacBook Pro (14-inch, 2023)",
        "variant" : "14-inch, 2023",
        "parts" : [
            "MPHE3xx/A",
            "MPHF3xx/A",
            "MPHG3xx/A",
            "MPHH3xx/A",
            "MPHJ3xx/A",
            "MPHK3xx/A"
        ]
    },
    {
        "models" : [
            "Mac14,6",
            "Mac14,10"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            "Silver",
            "space gray"
        ],
        "name" : "MacBook Pro (16-inch, 2023)",
        "variant" : "16-inch, 2023",
        "parts" : [
            "MNWG3xx/A",
            "MNW93xx/A",
            "MNWK3xx/A",
            "MNWD3xx/A",
            "MNWF3xx/A",
            "MNW83xx/A",
            "MNWJ3xx/A",
            "MNWC3xx/A"
        ]
    },
    {
        "models" : [
            "Mac14,7"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            "Silver",
            "space gray"
        ],
        "name" : "MacBook Pro (13-inch, M2, 2022)",
        "variant" : "13-inch, M2, 2022",
        "parts" : [
            "MNEH3xx/A",
            "MNEJ3xx/A",
            "MNEP3xx/A",
            "MNEQ3xx/A"
        ]
    },
    {
        "models" : [
            "MacBookPro18,3",
            "MacBookPro18,4"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            "Silver",
            "space gray"
        ],
        "name" : "MacBook Pro (14-inch, 2021)",
        "variant" : "14-inch, 2021",
        "parts" : [
            "MKGP3xx/A",
            "MKGQ3xx/A",
            "MKGR3xx/A",
            "MKGT3xx/A"
        ]
    },
    {
        "models" : [
            "MacBookPro18,1",
            "MacBookPro18,2"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            "Silver",
            "space gray"
        ],
        "name" : "MacBook Pro (16-inch, 2021)",
        "variant" : "16-inch, 2021",
        "parts" : [
            "MK183xx/A",
            "MK193xx/A",
            "MK1A3xx/A",
            "MK1E3xx/A",
            "MK1F3xx/A",
            "MK1H3xx/A"
        ]
    },
    {
        "models" : [
            "MacBookPro17,1"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            "Silver",
            "space gray"
        ],
        "name" : "MacBook Pro (13-inch, M1, 2020)",
        "variant" : "13-inch, M1, 2020",
        "parts" : [
            "MYD83xx/A",
            "MYD92xx/A",
            "MYDA2xx/A",
            "MYDC2xx/A"
        ]
    },
    {
        "models" : [
            "MacBookPro16,3"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            "Silver",
            "space gray"
        ],
        "name" : "MacBook Pro (13-inch, 2020, Two Thunderbolt 3 ports)",
        "variant" : "13-inch, 2020, Two Thunderbolt 3 ports",
        "parts" : [
            "MXK32xx/A",
            "MXK52xx/A",
            "MXK62xx/A",
            "MXK72xx/A"
        ]
    },
    {
        "models" : [
            "MacBookPro16,2"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            "Silver",
            "space gray"
        ],
        "name" : "MacBook Pro (13-inch, 2020, Four Thunderbolt 3 ports)",
        "variant" : "13-inch, 2020, Four Thunderbolt 3 ports",
        "parts" : [
            "MWP42xx/A",
            "MWP52xx/A",
            "MWP62xx/A",
            "MWP72xx/A",
            "MWP82xx/A"
        ]
    },
    {
        "models" : [
            "MacBookPro16,1",
            "MacBookPro16,4"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            "Silver",
            "space gray"
        ],
        "name" : "MacBook Pro (16-inch, 2019)",
        "variant" : "16-inch, 2019",
        "parts" : [
            "MVVJ2xx/A",
            "MVVK2xx/A",
            "MVVL2xx/A",
            "MVVM2xx/A"
        ]
    },
    {
        "models" : [
            "MacBookPro15,4"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            "Silver",
            "space gray"
        ],
        "name" : "MacBook Pro (13-inch, 2019, Two Thunderbolt 3 ports)",
        "variant" : "13-inch, 2019, Two Thunderbolt 3 ports",
        "parts" : [
            "MUHN2xx/A",
            "MUHP2xx/a",
            "MUHQ2xx/A",
            "MUHR2xx/A",
            "MUHR2xx/B"
        ]
    },
    {
        "models" : [
            "MacBookPro15,1",
            "MacBookPro15,3"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            "Silver",
            "space gray"
        ],
        "name" : "MacBook Pro (15-inch, 2019)",
        "variant" : "15-inch, 2019",
        "parts" : [
            "MV902xx/A",
            "MV912xx/A",
            "MV922xx/A",
            "MV932xx/A",
            "MV942xx/A",
            "MV952xx/A"
        ]
    },
    {
        "models" : [
            "MacBookPro15,2"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            "Silver",
            "space gray"
        ],
        "name" : "MacBook Pro (13-inch, 2019, Four Thunderbolt 3 ports)",
        "variant" : "13-inch, 2019, Four Thunderbolt 3 ports",
        "parts" : [
            "MV962xx/A",
            "MV972xx/A",
            "MV982xx/A",
            "MV992xx/A",
            "MV9A2xx/A"
        ]
    },
    {
        "models" : [
            "MacBookPro15,1"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            "Silver",
            "space gray"
        ],
        "name" : "MacBook Pro (15-inch, 2018)",
        "variant" : "15-inch, 2018",
        "parts" : [
            "MR932xx/A",
            "MR942xx/A",
            "MR952xx/A",
            "MR962xx/A",
            "MR972xx/A",
            "MUQH2xx/A"
        ]
    },
    {
        "models" : [
            "MacBookPro15,2"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            "Silver",
            "space gray"
        ],
        "name" : "MacBook Pro (13-inch, 2018, Four Thunderbolt 3 ports)",
        "variant" : "13-inch, 2018, Four Thunderbolt 3 ports",
        "parts" : [
            "MR9Q2xx/A",
            "MR9R2xx/A",
            "MR9T2xx/A",
            "MR9U2xx/A",
            "MR9V2xx/A"
        ]
    },
    {
        "models" : [
            "MacBookPro14,3"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            "Silver",
            "space gray"
        ],
        "name" : "MacBook Pro (15-inch, 2017)",
        "variant" : "15-inch, 2017",
        "parts" : [
            "MPTR2xx/A",
            "MPTT2xx/A",
            "MPTU2xx/A",
            "MPTV2xx/A",
            "MPTW2xx/A",
            "MPTX2xx/A"
        ]
    },
    {
        "models" : [
            "MacBookPro14,2"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            "Silver",
            "space gray"
        ],
        "name" : "MacBook Pro (13-inch, 2017, Four Thunderbolt 3 ports)",
        "variant" : "13-inch, 2017, Four Thunderbolt 3 ports",
        "parts" : [
            "MPXV2xx/A",
            "MPXW2xx/A",
            "MPXX2xx/A",
            "MPXY2xx/A",
            "MQ002xx/A",
            "MQ012xx/A"
        ]
    },
    {
        "models" : [
            "MacBookPro14,1"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            "Silver",
            "space gray"
        ],
        "name" : "MacBook Pro (13-inch, 2017, Two Thunderbolt 3 ports)",
        "variant" : "13-inch, 2017, Two Thunderbolt 3 ports",
        "parts" : [
            "MPXQ2xx/A",
            "MPXR2xx/A",
            "MPXT2xx/A",
            "MPXU2xx/A"
        ]
    },
    {
        "models" : [
            "MacBookPro13,3"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            "Silver",
            "space gray"
        ],
        "name" : "MacBook Pro (15-inch, 2016)",
        "variant" : "15-inch, 2016",
        "parts" : [
            "MLH32xx/A",
            "MLH42xx/A",
            "MLH52xx/A",
            "MLW72xx/A",
            "MLW82xx/A",
            "MLW92xx/A"
        ]
    },
    {
        "models" : [
            "MacBookPro13,2"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            "Silver",
            "space gray"
        ],
        "name" : "MacBook Pro (13-inch, 2016, Four Thunderbolt 3 ports)",
        "variant" : "13-inch, 2016, Four Thunderbolt 3 ports",
        "parts" : [
            "MLH12xx/A",
            "MLVP2xx/A",
            "MNQF2xx/A",
            "MNQG2xx/A",
            "MPDK2xx/A",
            "MPDL2xx/A"
        ]
    },
    {
        "models" : [
            "MacBookPro13,1"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            "Silver",
            "space gray"
        ],
        "name" : "MacBook Pro (13-inch, 2016, Two Thunderbolt 3 ports)",
        "variant" : "13-inch, 2016, Two Thunderbolt 3 ports",
        "parts" : [
            "MLL42xx/A",
            "MLUQ2xx/A"
        ]
    },
    {
        "models" : [
            "MacBookPro11,4",
            "MacBookPro11,5"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            
        ],
        "name" : "MacBook Pro (Retina, 15-inch, Mid 2015)",
        "variant" : "Retina, 15-inch, Mid 2015",
        "parts" : [
            
        ]
    },
    {
        "models" : [
            "MacBookPro12,1"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            
        ],
        "name" : "MacBook Pro (Retina, 13-inch, Early 2015)",
        "variant" : "Retina, 13-inch, Early 2015",
        "parts" : [
            "MF839xx/A",
            "MF840xx/A",
            "MF841xx/A",
            "MF843xx/A"
        ]
    },
    {
        "models" : [
            "MacBookPro11,2",
            "MacBookPro11,3"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            
        ],
        "name" : "MacBook Pro (Retina, 15-inch, Mid 2014)",
        "variant" : "Retina, 15-inch, Mid 2014",
        "parts" : [
            
        ]
    },
    {
        "models" : [
            "MacBookPro11,1"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            
        ],
        "name" : "MacBook Pro (Retina, 13-inch, Mid 2014)",
        "variant" : "Retina, 13-inch, Mid 2014",
        "parts" : [
            "MGX72xx/A",
            "MGX82xx/A",
            "MGX92xx/A"
        ]
    },
    {
        "models" : [
            "MacBookPro11,2",
            "MacBookPro11,3"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            
        ],
        "name" : "MacBook Pro (Retina, 15-inch, Late 2013)",
        "variant" : "Retina, 15-inch, Late 2013",
        "parts" : [
            
        ]
    },
    {
        "models" : [
            "MacBookPro11,1"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            
        ],
        "name" : "MacBook Pro (Retina, 13-inch, Late 2013)",
        "variant" : "Retina, 13-inch, Late 2013",
        "parts" : [
            "ME864xx/A",
            "ME865xx/A",
            "ME866xx/A"
        ]
    },
    {
        "models" : [
            "MacBookPro10,1"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            
        ],
        "name" : "MacBook Pro (Retina, 15-inch, Early 2013)",
        "variant" : "Retina, 15-inch, Early 2013",
        "parts" : [
            "ME664xx/A",
            "ME665xx/A"
        ]
    },
    {
        "models" : [
            "MacBookPro10,2"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            
        ],
        "name" : "MacBook Pro (Retina, 13-inch, Early 2013)",
        "variant" : "Retina, 13-inch, Early 2013",
        "parts" : [
            "MD212xx/A",
            "ME662xx/A"
        ]
    },
    {
        "models" : [
            "MacBookPro10,2"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            
        ],
        "name" : "MacBook Pro (Retina, 13-inch, Late 2012)",
        "variant" : "Retina, 13-inch, Late 2012",
        "parts" : [
            "MD212xx/A",
            "MD213xx/A"
        ]
    },
    {
        "models" : [
            "MacBookPro10,1"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            
        ],
        "name" : "MacBook Pro (Retina, 15-inch, Mid 2012)",
        "variant" : "Retina, 15-inch, Mid 2012",
        "parts" : [
            
        ]
    },
    {
        "models" : [
            "MacBookPro9,1"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            
        ],
        "name" : "MacBook Pro (15-inch, Mid 2012)",
        "variant" : "15-inch, Mid 2012",
        "parts" : [
            "MD103xx/A",
            "MD104xx/A"
        ]
    },
    {
        "models" : [
            "MacBookPro9,2"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            
        ],
        "name" : "MacBook Pro (13-inch, Mid 2012)",
        "variant" : "13-inch, Mid 2012",
        "parts" : [
            "MD101xx/A",
            "MD102xx/A"
        ]
    },
    {
        "models" : [
            "MacBookPro8,3"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            
        ],
        "name" : "MacBook Pro (17-inch, Late 2011)",
        "variant" : "17-inch, Late 2011",
        "parts" : [
            
        ]
    },
    {
        "models" : [
            "MacBookPro8,2"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            
        ],
        "name" : "MacBook Pro (15-inch, Late 2011)",
        "variant" : "15-inch, Late 2011",
        "parts" : [
            "MD322xx/A",
            "MD318xx/A"
        ]
    },
    {
        "models" : [
            "MacBookPro8,1"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            
        ],
        "name" : "MacBook Pro (13-inch, Late 2011)",
        "variant" : "13-inch, Late 2011",
        "parts" : [
            "MD314xx/A",
            "MD313xx/A"
        ]
    },
    {
        "models" : [
            "MacBookPro8,3"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            
        ],
        "name" : "MacBook Pro (17-inch, Early 2011)",
        "variant" : "17-inch, Early 2011",
        "parts" : [
            
        ]
    },
    {
        "models" : [
            "MacBookPro8,2"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            
        ],
        "name" : "MacBook Pro (15-inch, Early 2011)",
        "variant" : "15-inch, Early 2011",
        "parts" : [
            "MC723xx/A",
            "MC721xx/A"
        ]
    },
    {
        "models" : [
            "MacBookPro8,1"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            
        ],
        "name" : "MacBook Pro (13-inch, Early 2011)",
        "variant" : "13-inch, Early 2011",
        "parts" : [
            "MC724xx/A",
            "MC700xx/A"
        ]
    },
    {
        "models" : [
            "MacBookPro6,1"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            
        ],
        "name" : "MacBook Pro (17-inch, Mid 2010)",
        "variant" : "17-inch, Mid 2010",
        "parts" : [
            
        ]
    },
    {
        "models" : [
            "MacBookPro6,2"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            
        ],
        "name" : "MacBook Pro (15-inch, Mid 2010)",
        "variant" : "15-inch, Mid 2010",
        "parts" : [
            "MC373xx/A",
            "MC372xx/A",
            "MC371xx/A"
        ]
    },
    {
        "models" : [
            "MacBookPro7,1"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            
        ],
        "name" : "MacBook Pro (13-inch, Mid 2010)",
        "variant" : "13-inch, Mid 2010",
        "parts" : [
            "MC375xx/A",
            "MC374xx/A"
        ]
    },
    {
        "models" : [
            "MacBookPro5,2"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            
        ],
        "name" : "MacBook Pro (17-inch, Mid 2009)",
        "variant" : "17-inch, Mid 2009",
        "parts" : [
            
        ]
    },
    {
        "models" : [
            "MacBookPro5,3"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            
        ],
        "name" : "MacBook Pro (15-inch, Mid 2009)",
        "variant" : "15-inch, Mid 2009",
        "parts" : [
            "MB985xx/A",
            "MB986xx/A"
        ]
    },
    {
        "models" : [
            "MacBookPro5,3"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            
        ],
        "name" : "MacBook Pro (15-inch, 2.53GHz, Mid 2009)",
        "variant" : "15-inch, 2.53GHz, Mid 2009",
        "parts" : [
            
        ]
    },
    {
        "models" : [
            "MacBookPro5,5"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            
        ],
        "name" : "MacBook Pro (13-inch, Mid 2009)",
        "variant" : "13-inch, Mid 2009",
        "parts" : [
            "MB991xx/A",
            "MB990xx/A"
        ]
    },
    {
        "models" : [
            "MacBookPro5,2"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            
        ],
        "name" : "MacBook Pro (17-inch, Early 2009)",
        "variant" : "17-inch, Early 2009",
        "parts" : [
            
        ]
    },
    {
        "models" : [
            "MacBookPro5,1"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            
        ],
        "name" : "MacBook Pro (15-inch, Late 2008)",
        "variant" : "15-inch, Late 2008",
        "parts" : [
            
        ]
    },
    {
        "models" : [
            "MacBookPro4,1"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            
        ],
        "name" : "MacBook Pro (17-inch, Early 2008)",
        "variant" : "17-inch, Early 2008",
        "parts" : [
            
        ]
    },
    {
        "models" : [
            "MacBookPro4,1"
        ],
        "kind" : "MacBook Pro",
        "colors" : [
            
        ],
        "name" : "MacBook Pro (15-inch, Early 2008)",
        "variant" : "15-inch, Early 2008",
        "parts" : [
            
        ]
    },
    {
        "models" : [
            "Mac14,12"
        ],
        "kind" : "Mac mini",
        "colors" : [
            
        ],
        "name" : "Mac mini (2023)",
        "variant" : "2023",
        "parts" : [
            "MNH73xx/A"
        ]
    },
    {
        "models" : [
            "Macmini9,1"
        ],
        "kind" : "Mac mini",
        "colors" : [
            
        ],
        "name" : "Mac mini (M1, 2020)",
        "variant" : "M1, 2020",
        "parts" : [
            "MGNR3xx/A",
            "MGNT3xx/A"
        ]
    },
    {
        "models" : [
            "Macmini8,1"
        ],
        "kind" : "Mac mini",
        "colors" : [
            
        ],
        "name" : "Mac mini (2018)",
        "variant" : "2018",
        "parts" : [
            "MRTR2xx/A",
            "MRTT2xx/A",
            "MXNF2xx/A",
            "MXNG2xx/A"
        ]
    },
    {
        "models" : [
            "Macmini7,1"
        ],
        "kind" : "Mac mini",
        "colors" : [
            
        ],
        "name" : "Mac mini (Late 2014)",
        "variant" : "Late 2014",
        "parts" : [
            "MGEM2xx/A",
            "MGEN2xx/A",
            "MGEQ2xx/A"
        ]
    },
    {
        "models" : [
            "Macmini6,1; Macmini6,2"
        ],
        "kind" : "Mac mini",
        "colors" : [
            
        ],
        "name" : "Mac mini (Late 2012)",
        "variant" : "Late 2012",
        "parts" : [
            "MD387xx/A; MD388xx/A",
            "MD389xx/A"
        ]
    },
    {
        "models" : [
            "Macmini5,1; Macmini5,2"
        ],
        "kind" : "Mac mini",
        "colors" : [
            
        ],
        "name" : "Mac mini (Mid 2011)",
        "variant" : "Mid 2011",
        "parts" : [
            "MC815xx/A; MC816xx/A",
            "MC936xx/A"
        ]
    },
    {
        "models" : [
            "Macmini4,1"
        ],
        "kind" : "Mac mini",
        "colors" : [
            
        ],
        "name" : "Mac mini (Mid 2010)",
        "variant" : "Mid 2010",
        "parts" : [
            "MC438xx/A",
            "MC270xx/A"
        ]
    },
    {
        "models" : [
            "Macmini3,1"
        ],
        "kind" : "Mac mini",
        "colors" : [
            
        ],
        "name" : "Mac mini (Late 2009)",
        "variant" : "Late 2009",
        "parts" : [
            "MC238xx/A",
            "MC239xx/A",
            "MC408xx/A"
        ]
    },
    {
        "models" : [
            "Macmini3,1"
        ],
        "kind" : "Mac mini",
        "colors" : [
            
        ],
        "name" : "Mac mini (Early 2009)",
        "variant" : "Early 2009",
        "parts" : [
            "MB464xx/A",
            "MB463xx/A"
        ]
    },
    {
        "models" : [
            "MacPro7,1"
        ],
        "kind" : "Mac Pro",
        "colors" : [
            
        ],
        "name" : "Mac Pro (2019)",
        "variant" : "2019",
        "parts" : [
            
        ]
    },
    {
        "models" : [
            "MacPro7,1"
        ],
        "kind" : "Mac Pro",
        "colors" : [
            
        ],
        "name" : "Mac Pro (Rack, 2019)",
        "variant" : "Rack, 2019",
        "parts" : [
            
        ]
    },
    {
        "models" : [
            "MacPro6,1"
        ],
        "kind" : "Mac Pro",
        "colors" : [
            
        ],
        "name" : "Mac Pro (Late 2013)",
        "variant" : "Late 2013",
        "parts" : [
            "ME253xx/A",
            "MD878xx/A"
        ]
    },
    {
        "models" : [
            "MacPro5,1"
        ],
        "kind" : "Mac Pro",
        "colors" : [
            
        ],
        "name" : "Mac Pro (Mid 2012)",
        "variant" : "Mid 2012",
        "parts" : [
            "MD770xx/A",
            "MD771xx/A"
        ]
    },
    {
        "models" : [
            "MacPro5,1"
        ],
        "kind" : "Mac Pro Server",
        "colors" : [
            
        ],
        "name" : "Mac Pro Server (Mid 2012)",
        "variant" : "Mid 2012",
        "parts" : [
            
        ]
    },
    {
        "models" : [
            "MacPro5,1"
        ],
        "kind" : "Mac Pro",
        "colors" : [
            
        ],
        "name" : "Mac Pro (Mid 2010)",
        "variant" : "Mid 2010",
        "parts" : [
            "MC250xx/A",
            "MC560xx/A",
            "MC561xx/A"
        ]
    },
    {
        "models" : [
            "MacPro5,1"
        ],
        "kind" : "Mac Pro Server",
        "colors" : [
            
        ],
        "name" : "Mac Pro Server (Mid 2010)",
        "variant" : "Mid 2010",
        "parts" : [
            
        ]
    }
]
"""
        let json = macsRaw.data(using: .utf8)!
        let decoder = JSONDecoder()
        let macs = (try? decoder.decode([MacLookup].self, from: json)) ?? []
        print(String(describing: macs))
    }
}

#Preview {
    DeviceTestView()
}
