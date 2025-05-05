import SwiftUI

// Replace this with CustomStringConvertible?

protocol StringRepresentable {
    var str: String { get }
}
extension String: StringRepresentable {
    var str: String { self }
}
extension [String]: StringRepresentable {
    var str: String { self.joined(separator: ", ") }
}
extension Optional: StringRepresentable {
    public var str: String {
        if self == nil {
            return "nil"
        }
        if let version = self as? Version? {
            guard let version else {
                // latest version should apply
                let currentVersion = Array(Version.macOSs.keys).last!
                return currentVersion.macOSName
            }
            let previous = version.previousMacOS()
            return previous.macOSName
        }
        if let string = self as? String?, let string {
            return string
        }
        if let strings = self as? [String]?, let strings {
            return strings.str
        }
        return "Unknown"
    }
}


public extension Text {
    @inlinable
    static func += (lhs: inout Text, rhs: Text) {
        lhs = lhs + rhs
    }
}
public extension [Text] {
    func joined(separator: Text = Text("")) -> Text {
        var joined = Text("")
        for element in self {
            joined += element
            if element != self.last! {
                joined += separator
            }
        }
        return joined
    }
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
struct DiffView: View {
    var left: String?
    var merged: String?
    var right: String?
    var source: String
    enum DiffMode: CaseIterable {
        case left
        case merged
        case diff
        case right
        case source
    }
    @State var viewMode: DiffMode = .merged
    func mergedLine(left: String?, merged: String?, right: String?, diff: Bool) -> Text {
        // make sure each have a value and are non-optional
        let left = left ?? "MISSING"
        let merged = merged ?? "MISSING"
        let right = right ?? "MISSING"
        
        if left == merged && merged == right {
            // no change
            return Text(merged)
        }
        var output: [Text] = []
        // not all the same
        if left == merged {
            // we have a different parsed value but we decided to go with the left value
            output += [Text(merged)
                .foregroundColor(.green)]
        } else if diff { // if not diff, only output the right side
            output += [Text(left)
                .foregroundColor(.blue)]
        } else if merged != right {
            // merged may be different but we still want to output and highlight that it's neither the original nor the new exclusively
            output += [Text(merged)
                .foregroundColor(.red)]
        }
        if diff || merged == right {
            // output right side
            output += [Text(right)
                .foregroundColor(.magenta)]
        }
        return output.joined(separator: Text("\n"))
    }
    
    func merged(diff: Bool) -> Text {
        let left = left?.lines ?? []
        let merged = merged?.lines ?? []
        let right = right?.lines ?? []
        var output: [Text] = []
        let maxLineCount = max(left.count, merged.count, right.count)
        for i in 0..<maxLineCount {
            output += [
                mergedLine(
                    left: left[safe: i],
                    merged: merged[safe: i],
                    right: right[safe: i],
                    diff: diff)
                ]
        }
        return output.joined(separator: Text("\n"))
    }
    
    var body: some View {
        Picker("Show", selection: $viewMode) {
            ForEach(DiffMode.allCases, id: \.self) { mode in
                Text(String(describing: mode))
                    .tag(mode)
            }
        }
        .pickerStyle(.segmentedBackport)
        ScrollView {
            Group {
                switch viewMode {
                case .left:
                    Text(left ?? "EMPTY")
                case .merged:
                    merged(diff: false)
                case .diff:
                    merged(diff: true)
                case .right:
                    Text(right ?? "EMPTY")
                case .source:
                    Text(source)
                }
            }
            //                    .lineLimit(nil) // TODO: Should we add this?
            .backport.textSelection(.enabled)
        }
        .backport.scrollDisabled() // so that we don't have issues but ScrollView is necessary for resizing when switching tabs.
    }
}

import Device
@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
#Preview {
    List {
        DiffView(
            left: Device(identifier: "iPhone16,1").definition,
            merged: Device(identifier: "iPhone16,2").definition,
            right: Device(
                idiom: .phone,
                officialName: "Parsed iPhone",
                identifiers: ["iPhone16,2"],
                introduction: 2025.introductionYear,
                supportId: .unknownSupportId,
                launchOSVersion: .zero,
                unsupportedOSVersion: nil,
                capabilities: [.dynamicIsland],
                colors: [],
                cpu: .a4
            ).definition,
            source: """
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris ut commodo lectus. Pellentesque ut turpis ligula. Nullam non viverra sapien. Sed nec risus non neque facilisis mattis eu eu tortor. Nam rutrum venenatis ex. Vestibulum rutrum, dui sed gravida consequat

, metus lectus tristique eros, a gravida ex orci sit amet lectus. Mauris placerat gravida convallis. Integer semper diam sit amet lorem ultrices, vel convallis mauris consequat. Mauris pellentesque finibus suscipit.  In vestibulum est feugiat varius congue. Ut at erat auctor, varius lectus ac, sollicitudin ante. Curabitur et justo mauris. In scelerisque arcu ante, a dictum diam sagittis nec. Maecenas ac ligula in mi blandit facilisis eget vitae justo. In hac habitasse platea dictumst. Pellentesque at eros quis n

ibh fringilla sollicitudin in in ipsum. Donec eget metus non felis sagittis sagittis eu a turpis. Nullam ornare suscipit risus et condimentum.  Suspendisse elementum hendrerit odio, ac maximus sem tristique sed. Mauris dapibus finibus mauris. Nullam eu libero sapien. Nullam n

ulla nisl, venenatis eu orci sed, blandit condimentum enim. Nullam vel interdum felis. Sed tempor mattis condimentum. Donec pulvinar purus eu elementum consectetur.  Sed iaculis interdum laoreet. Mauris sagittis volutpat risus, at venenatis mauris tempor id. Proin ac auctor risus. In vel augue eu eros faucibus commodo nec quis risus. Nullam sollicitudin, est at pretium lobortis, nisi nibh ultricies ex, et efficitur augue tortor vel mauris. Pellentesque tincidunt accumsan iaculis. Mauris elementum hendrerit lorem a

 molestie. Interdum et malesuada fames ac ante ipsum primis in faucibus. Suspendisse sodales enim in lectus ultrices mollis. Suspendisse sit amet sem quis turpis iaculis vehicula nec eu ex. Pellentesque sit amet libero pellentesque, pharetra tellus sit amet, facilisis nibh. Duis eu magna dapibus, sagittis ligula non, tincidunt dolor.
""")
    }
}


@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
struct DiffRowView: View {
    var fieldName: String
    var leftValue: String
    var rightValue: String
    
    var body: some View {
        VStack {
            Text(fieldName)
                .font(.caption.bold())
            Text(leftValue)
            Text(rightValue)
        }
    }
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
#Preview {
    DiffRowView(fieldName: "TestField", leftValue: "Left", rightValue: "Right")
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
struct DiffObjectView<Object: PropertyIterable>: View {
    var left: Object
    var right: Object
    var combinedProperties: [String:(String,String)] {
        var results = [String:(String,String)]()
        let leftProperties = left.allProperties
        let rightProperties = right.allProperties
        for key in leftProperties.keys {
            results[key] = (String(describing: leftProperties[key]), String(describing: rightProperties[key]))
        }
        return results
    }
    var body: some View {
        List {
            ForEach(combinedProperties.sorted(by: { $0.key > $1.key }), id: \.key) { (key, tuple) in
                DiffRowView(
                    fieldName: key,
                    leftValue: tuple.0,
                    rightValue: tuple.1
                )
            }
        }
    }
}

#Preview {
    DiffObjectView(
        left: Device(identifier: "iPhone1,1"),
        right: Device(identifier: "iPod1,1")
    )
}
