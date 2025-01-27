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
    let assignmentsDue: Int
    let allDone: Bool
    let name: String
    let color: String
    let time: String
}

struct Provider: TimelineProvider {
    var allDone: Bool = false
    var selectedclass: String = ""
    func placeholder(in context: Context) -> ScheduleEntry {
        ScheduleEntry(date: Date(), currentBlock: "Loading...", isUpcoming: false, assignmentsDue: 0, allDone: false, name: "", color: "#000000", time: "")
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ScheduleEntry) -> Void) {
        let entry = ScheduleEntry(date: Date(), currentBlock: "Loading...", isUpcoming: false, assignmentsDue: 0, allDone: false, name: "", color: "#000000", time: "")
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<ScheduleEntry>) -> Void) {
        var entries: [ScheduleEntry] = []
        print("getTimeline called")
        
        fetchCurrentBlock { currentBlock, isUpcoming, allDone, selectedclass, name, color, time in
            print("fetchCurrentBlock completed with block: \(currentBlock)")
            fetchAssignmentsDue(selectedclass: selectedclass, allDone: allDone) { assignmentsDue in
                print("fetchAssignmentsDue completed with assignments: \(assignmentsDue)")
                let entry = ScheduleEntry(date: Date(), currentBlock: currentBlock, isUpcoming: isUpcoming, assignmentsDue: assignmentsDue, allDone: allDone, name: name, color: color, time: time)
                entries.append(entry)
                
                // Create a timeline with the entry
                let timeline = Timeline(entries: entries, policy: .atEnd)
                completion(timeline)
            }
        }
    }
    
    private func fetchCurrentBlock(completion: @escaping (String, Bool, Bool, String, String, String, String) -> Void) {
        print("fetchCurrentBlock called")
        let sharedDefaults = UserDefaults(suiteName: "group.com.example.CampusCommotion")!
        let requestData = sharedDefaults.string(forKey: "request_data") ?? ""
        let parsedData = JSON(parseJSON: requestData)
        let now = Date()
        var allDone = true
        var nextBlock: String? = nil
        var selectedclass: String = ""
        var name: String = ""
        var nextblockclass: String = ""
        var nextblockname: String = ""
        var color: String = ""
        var nextblockcolor: String = ""
        var time: String = ""
        var nextblocktime : String = ""

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
                    let blocks = day.arrayValue
                    print("Found today's blocks: \(blocks)")
                    // Looks for the block currently in session
                    for blockInfo in blocks {
                        let startTimeString = blockInfo["starttime"].stringValue // "h:mm"
                        let endTimeString = blockInfo["endtime"].stringValue
                        let blockId = blockInfo["blockid"].stringValue
                        let pmstart = blockInfo["pmstart"].boolValue
                        let pmend = blockInfo["pmend"].boolValue
                        selectedclass = blockInfo["classname"].stringValue
                        name = blockInfo["classname"].stringValue
                        color = blockInfo["color"].stringValue
                        time = blockInfo["starttime"].stringValue + " - " + blockInfo["endtime"].stringValue
                        
                        // Converts times to Date
                        if
                            let start = parseTime(startTimeString, isAfternoon: pmstart),
                            let end = parseTime(endTimeString, isAfternoon: pmend)
                        {
                            if now >= start && now < end {
                                print("Current block: \(blockId)")
                                completion(blockId, false, false, selectedclass, name, color, time)
                                return
                            } else if now < start && nextBlock == nil {
                                nextBlock = blockId
                                allDone = false
                                nextblockname = name
                                nextblockclass = selectedclass
                                nextblockcolor = color
                                nextblocktime = time
                            }
                        }
                    }
                }
            }
        }
        if let nextBlock = nextBlock {
            print("Next block: \(nextBlock)")
            completion(nextBlock, true, false, nextblockclass, nextblockname, nextblockcolor, nextblocktime)
        } else {
            print("No current or upcoming block found")
            completion("Loading...", false, allDone, "", "", "#000000", "")
        }
    }
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

private func fetchAssignmentsDue(selectedclass: String, allDone: Bool, completion: @escaping (Int) -> Void) {
    let keychain = KeychainSwift()
    keychain.accessGroup = "group.com.example.CampusCommotion"
    let token = keychain.get("token") ?? ""
    guard !token.isEmpty else {
        print("Token is empty")
        completion(0)
        return
    }

    if allDone {
        print("All done is true")
        completion(0)
        return
    }
    
    let classID = selectedclass.split(separator: " ").first ?? ""
    print("Class ID: \(classID)")

    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    let formattedDate = dateFormatter.string(from: Date())
    let urlString = "https://canvas.example.edu/api/v1/planner/items?start_date=\(formattedDate)&access_token=\(token)&per_page=100"
    
    guard let url = URL(string: urlString) else {
        print("Invalid URL: \(urlString)")
        completion(0)
        return
    }

    URLSession.shared.dataTask(with: url) { data, _, error in
        if let error = error {
            print("Error: \(error.localizedDescription)")
            completion(0)
            return
        }

        guard let data = data else {
            print("No data received")
            completion(0)
            return
        }

        let jsonString = String(data: data, encoding: .utf8)
        let parsedData = JSON(parseJSON: jsonString ?? "")
        
        DispatchQueue.main.async {
            let dispatchGroup = DispatchGroup()
            var assignmentsDue = 0

            for item in parsedData.arrayValue {
                dispatchGroup.enter()
                let isoDateFormatter = ISO8601DateFormatter()
                isoDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                
                AF.request("https://canvas.example.edu/api/v1/courses/\(item["course_id"].stringValue)?access_token=\(token)&per_page=100").responseString { response in
                    switch response.result {
                    case .success(let value):
                        let coursedata = JSON(parseJSON: value)
                        let coursecodefix = coursedata["course_code"].stringValue.replacingOccurrences(of: "-", with: "*")
                        print(coursecodefix)
                        print(classID)
                        if coursecodefix.contains(classID) {
                            if let date = isoDateFormatter.date(from: item["plannable_date"].stringValue) {
                                let dateFormatter = DateFormatter()
                                print("coursedata " + coursedata["course_code"].stringValue)
                                dateFormatter.dateFormat = "yyyy-MM-dd"
                                dateFormatter.timeZone = TimeZone(identifier: "America/New_York")
                                let formattedDate = dateFormatter.string(from: date)
                                let today = dateFormatter.string(from: Date())
                                if formattedDate == today {
                                    assignmentsDue += 1
                                }
                            }
                        }
                    case .failure(let error):
                        print("Course request failed with error: \(error)")
                    }
                    dispatchGroup.leave()
                }
            }

            dispatchGroup.notify(queue: .main) {
                print("Assignments due: \(assignmentsDue)")
                completion(assignmentsDue)
            }
        }
    }.resume()
}

struct ScheduleWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            switch family {
            case .systemSmall:
                if !entry.allDone {
                    VStack {
                        if entry.isUpcoming {
                            Text("Upcoming Block")
                                .font(.caption)
                                .foregroundColor(.gray)
                        } else {
                            Text("Current Block")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Text(entry.currentBlock)
                            .font(.largeTitle)
                            .foregroundColor(Color(hexStringToUIColor(hex: entry.color)))
                            .lineLimit(3)
                            .minimumScaleFactor(0.5)
                        //if entry.color != "#6A5ACD" {
                         //   Text("\(entry.assignmentsDue)")
                         //       .font(.system(size: 40, weight: .bold))
                        //        .foregroundColor(.white)
                        //}
                        Text(entry.time)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding()
                }
                else {
                    Text("All Done!")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                }
            default:
                if !entry.allDone {
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        if entry.isUpcoming {
                            Text("Upcoming Block")
                                .font(.caption)
                                .foregroundColor(.gray)
                        } else {
                            Text("Current Block")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Text(entry.currentBlock)
                            .font(.largeTitle)
                            .foregroundColor(Color(hexStringToUIColor(hex: entry.color)))
                    }
                    Spacer()
                    //VStack {
                      //  Text(entry.name.components(separatedBy: " - ").count > 1 ? entry.name.components(separatedBy: " - //").dropLast().joined(separator: " - ") : entry.name)
                      //      .font(.title3)
                      //      .foregroundColor(Color(hexStringToUIColor(hex: entry.color)))
                      //      .minimumScaleFactor(0.5)
                      //  if entry.color != "#6A5ACD" {
                      //      Text("\(entry.assignmentsDue)")
                      //          .font(.system(size: 50, weight: .bold)) // Big, bold red number
                      //          .foregroundColor(Color(hexStringToUIColor(hex: entry.color)))
                      //      Text("Assignment Due")
                      //          .font(.caption)
                       //         .foregroundColor(.gray)
                     //   }
                   // }
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
            }
            else {
                Text("All Done!")
                    .font(.system(size: 40, weight: .bold)) // Large, bold number
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
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ScheduleWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Campus Commotion Widget")
        .description("Displays the current block and the number of assignments due.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .disableContentMarginsIfNeeded()
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
        #if os(macOS)
        if #available(macCatalystApplicationExtension 17.0, *) {
            self.containerBackground(for: .widget) {
                Color.black
            }
        } else {
            self
        }
        #else
        self
        #endif
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
