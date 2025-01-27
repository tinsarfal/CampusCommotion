//
//  CampusCommotionWidget.swift
//  CampusCommotionWidget

import WidgetKit
import SwiftUI
import SwiftyJSON
import KeychainSwift
import Alamofire

struct ScheduleEntry: TimelineEntry {
    let date: Date
    let currentBlock: String
    let isUpcoming: Bool
    let allDone: Bool
    let name: String
    let color: String
    let time: String
}

struct Provider: TimelineProvider {
    var allDone: Bool = false
    var selectedclass: String = ""
    func placeholder(in context: Context) -> ScheduleEntry {
        ScheduleEntry(date: Date(), currentBlock: "Loading...", isUpcoming: false, allDone: false, name: "", color: "#000000", time: "")
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ScheduleEntry) -> Void) {
        let entry = ScheduleEntry(date: Date(), currentBlock: "Loading...", isUpcoming: false, allDone: false, name: "", color: "#000000", time: "")
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<ScheduleEntry>) -> Void) {
        var entries: [ScheduleEntry] = []
        print("getTimeline called")
        
        fetchBlocks { blocks in
            for block in blocks {
                let entry = ScheduleEntry(date: block.start, currentBlock: block.id, isUpcoming: block.isUpcoming, allDone: block.allDone, name: block.name, color: block.color, time: block.time)
                entries.append(entry)
            }
            
            let nextRefreshDate = Calendar.current.startOfDay(for: Date()).addingTimeInterval(86400)
            let timeline = Timeline(entries: entries, policy: .after(nextRefreshDate))
            completion(timeline)
        }
    }
    
    private func fetchBlocks(completion: @escaping ([Block]) -> Void) {
        print("fetchBlocks called")
        let sharedDefaults = UserDefaults(suiteName: "group.com.sscheffler.CampusCommotion")!
        let requestData = sharedDefaults.string(forKey: "request_data") ?? ""
        let parsedData = JSON(parseJSON: requestData)
        let now = Date()
        var blocks: [Block] = []
        var lastBlockEnd: Date?

        // Finds today's blocks
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE M/d"
        
        let todayString = dateFormatter.string(from: now)
        print("Today's date string: \(todayString)")
        
        // Searches for blocks in the JSON that match today's date
        let allWeeks = parsedData["all_weeks_blocks"].arrayValue
        for week in allWeeks {
            for (_, day) in week {
                if day[0]["date"].stringValue == todayString {
                    // This is today's set of blocks
                    let blockInfos = day.arrayValue
                    print("Found today's blocks: \(blockInfos)")
                    // Looks for the block currently in session
                    var previousEnd: Date? = nil
                    for blockInfo in blockInfos {
                        let startTimeString = blockInfo["starttime"].stringValue // "h:mm"
                        let endTimeString = blockInfo["endtime"].stringValue
                        let blockId = blockInfo["blockid"].stringValue
                        let pmstart = blockInfo["pmstart"].boolValue
                        let pmend = blockInfo["pmend"].boolValue
                        let selectedclass = blockInfo["classname"].stringValue
                        let name = blockInfo["classname"].stringValue
                        let color = blockInfo["color"].stringValue
                        let time = blockInfo["starttime"].stringValue + " - " + blockInfo["endtime"].stringValue
                        
                        // Converts times to Date
                        if
                            let start = parseTime(startTimeString, isAfternoon: pmstart),
                            let end = parseTime(endTimeString, isAfternoon: pmend)
                        {
                            // Add an entry for the time between blocks if there is a previous block
                            if let previousEnd = previousEnd, previousEnd < start {
                                let betweenBlock = Block(id: blockId, start: previousEnd, end: start, isUpcoming: true, allDone: false, name: name, color: color, time: time)
                                blocks.append(betweenBlock)
                            }
                            
                            let isUpcoming = now < start
                            let allDone = now >= end 
                            let block = Block(id: blockId, start: start, end: end, isUpcoming: isUpcoming, allDone: allDone, name: name, color: color, time: time)
                            blocks.append(block)
                            
                            previousEnd = end
                            lastBlockEnd = end
                        }
                    }
                    if let lastBlockEnd = lastBlockEnd {
                        if !allDone {
                            let afterBlock = Block(id: "allDone", start: lastBlockEnd, end: lastBlockEnd.addingTimeInterval(1), isUpcoming: false, allDone: true, name: "All Done", color: "#000000", time: "")
                            blocks.append(afterBlock)
                        }
                    }
                }
            }
        }
        completion(blocks)
    }
    
    // Example helper for converting "h:mm" string to Date. 
    // Similar to [Shared/Connector.extractTime](Shared/Connector.swift).
    private func parseTime(_ timeString: String, isAfternoon: Bool) -> Date? {
        guard !timeString.isEmpty, timeString != "All Day" else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.timeZone = TimeZone(identifier: "America/New_York") // Adjust to your time zone

        // Append AM/PM based on the isAfternoon flag
        let timeWithPeriod = isAfternoon ? "\(timeString) PM" : "\(timeString) AM"
        let today = Date()
        let dateString = DateFormatter.localizedString(from: today, dateStyle: .short, timeStyle: .none)
        let combinedString = "\(dateString) \(timeWithPeriod)"
        let combinedFormatter = DateFormatter()
        combinedFormatter.dateFormat = "M/d/yy h:mm a"
        combinedFormatter.timeZone = formatter.timeZone
        let parsedDate = combinedFormatter.date(from: combinedString)
        print("Parsed time string: \(timeString) with period: \(timeWithPeriod) to date: \(String(describing: parsedDate))")
        return parsedDate
    }
}

struct Block {
    let id: String
    let start: Date
    let end: Date
    let isUpcoming: Bool
    let allDone: Bool
    let name: String
    let color: String
    let time: String
}

struct ScheduleWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    var body: some View {
        ZStack {
            Color.clear
            switch family {
            case .systemSmall:
                if !entry.allDone {
                    VStack {
                        if entry.isUpcoming {
                            Text("Upcoming Block")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .bold()
                        } else {
                            Text("Current Block")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .bold()
                        }
                        Text(entry.currentBlock)
                            .font(.system(size: 70, weight: .bold))
                            .foregroundColor(Color(hexStringToUIColor(hex: entry.color)))
                            .lineLimit(3)
                            .minimumScaleFactor(0.5)
                        Text(entry.time)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding()
                } else {
                    Text("All Done!")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                }
            case .accessoryRectangular:
                VStack {
                    if entry.isUpcoming {
                        Text("Upcoming Block")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .bold()
                    } else {
                        Text("Current Block")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .bold()
                    }
                    Text(entry.currentBlock)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(hexStringToUIColor(hex: entry.color)))
                    Text(entry.time)
                        .font(.headline)
                        .foregroundColor(.white)
                }
            case .accessoryInline:
                Text(entry.currentBlock + ": " + entry.time)
                    .font(.headline)
                    .foregroundColor(Color(hexStringToUIColor(hex: entry.color)))
            default:
                if !entry.allDone {
                    HStack {
                        VStack(alignment: .center, spacing: 0) {
                            if entry.isUpcoming {
                                Text("Upcoming Block")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .bold()
                            } else {
                                Text("Current Block")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .bold()
                            }
                            Text(entry.currentBlock)
                                .font(.system(size: 80, weight: .bold))
                                .foregroundColor(Color(hexStringToUIColor(hex: entry.color)))
                        }
                        Spacer()
                        VStack(alignment: .leading, spacing: 0) {
                            Text(entry.name.components(separatedBy: " - ").count > 1 ? entry.name.components(separatedBy: " - ").dropLast().joined(separator: " - ").trimmingCharacters(in: .whitespacesAndNewlines) : entry.name.trimmingCharacters(in: .whitespacesAndNewlines))
                                .font(.headline)
                                .foregroundColor(Color(hexStringToUIColor(hex: entry.color)))
                                .minimumScaleFactor(0.5)
                                .padding(.bottom, 0)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(entry.time)
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.top, 0)
                                .edgesIgnoringSafeArea(.top)
                        }
                    }
                    .padding(.horizontal)
                } else {
                    Text("All Done!")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .applyContainerBackgroundIfAvailable()
    }
}

@main
struct CampusCommotionWidget: Widget {
    let kind: String = "CampusCommotionWidget"

    var body: some WidgetConfiguration {
        if #available(iOSApplicationExtension 16.0, *) {
            StaticConfiguration(kind: kind, provider: Provider()) { entry in
                ScheduleWidgetEntryView(entry: entry)
            }
            .configurationDisplayName("Campus Commotion Widget")
            .description("Displays the current block and the number of assignments due.")
            .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline])
            .disableContentMarginsIfNeeded()
        } else {
            StaticConfiguration(kind: kind, provider: Provider()) { entry in
                ScheduleWidgetEntryView(entry: entry)
            }
            .configurationDisplayName("Campus Commotion Widget")
            .description("Displays the current block and the number of assignments due.")
            .supportedFamilies([.systemSmall, .systemMedium])
            .disableContentMarginsIfNeeded()        }
    }
}

extension WidgetConfiguration {
    func disableContentMarginsIfNeeded() -> some WidgetConfiguration {
        if #available(iOSApplicationExtension 17.0, *) {
            return self.contentMarginsDisabled()
        } else {
            return self
        }
    }
}

extension View {
    @ViewBuilder
    func applyContainerBackgroundIfAvailable() -> some View {
        if #available(macOS 14.0, iOS 17.0, *) {
            self.containerBackground(for: .widget) {
                Color.black
            }
        } else {
            self
        }
    }
}

func hexStringToUIColor (hex:String) -> UIColor {
    var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

    if (cString.hasPrefix("#")) {
        cString.remove(at: cString.startIndex)
    }

    if ((cString.count) != 6) {
        return UIColor.gray
    }

    var rgbValue:UInt64 = 0
    Scanner(string: cString).scanHexInt64(&rgbValue)

    return UIColor(
        red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
        green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
        blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
        alpha: CGFloat(1.0)
    )
}
