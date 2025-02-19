import SwiftUI
import SwiftyJSON
import ActivityIndicatorView
import KeychainSwift
import WatchConnectivity

struct Event: Codable {
    let pmstart: Bool
    let starttime: String
    let location: String
    let teacher: String
    let blockid: String
    let color: String
    let teacherusername: String
    let endtime: String
    let pmend: Bool
    let date: String
    let classname: String
}

struct Information {
    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "M/d"
        return df
    }()
    
    public static var todaydate: String {
        return dateFormatter.string(from: Date())
    }
    
    private static var _currentnum: (Int, String)? = nil
    private static var lastUpdateDate: String? = nil
    
    public static var currentnum: (Int, String) {
        let today = todaydate
        
        if let cachedCurrentnum = _currentnum, lastUpdateDate == today {
            return cachedCurrentnum
        }
        
        guard let request_data = UserDefaults(suiteName: "group.com.example.CampusCommotion")?.string(forKey: "request_data"),
              let requestDataJSON = try? JSON(parseJSON: request_data) else {
            return (0, "0")
        }
        
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let currentMonth = calendar.component(.month, from: Date())

        for i in 0..<requestDataJSON["all_weeks_blocks"].count {
            for (key, day) in requestDataJSON["all_weeks_blocks"][i] {
                guard let rawDateString = day[0]["date"].string?.split(separator: " ").last else { continue }
                
                if rawDateString == today {
                    _currentnum = (i, key)
                    lastUpdateDate = today
                    return (i, key)
                }
                
                if let dayDate = dateFormatter.date(from: String(rawDateString)) {
                    var adjustedDate = dayDate
                    
                    if currentMonth == 12 && calendar.component(.month, from: dayDate) == 1 {
                        adjustedDate = calendar.date(bySetting: .year, value: currentYear + 1, of: dayDate) ?? dayDate
                    } else if currentMonth <= 4 && calendar.component(.month, from: dayDate) >= 11 {
                        adjustedDate = calendar.date(bySetting: .year, value: currentYear - 1, of: dayDate) ?? dayDate
                    } else {
                        adjustedDate = calendar.date(bySetting: .year, value: currentYear, of: dayDate) ?? dayDate
                    }
                    
                    if adjustedDate >= Date() {
                        _currentnum = (i, key)
                        lastUpdateDate = today
                        return (i, key)
                    }
                }
            }
        }
        _currentnum = (0, "0")
        lastUpdateDate = today
        return (0, "0")
    }
    
    static var indexnumber = currentnum.0
}

struct ContentView: View {
    @State private var requestData: String = ""
    // Use computed property to update parsed JSON as requestData changes.
    private var parsedJSON: JSON { JSON(requestData) }
    @State private var showLoadingIndicator = false
    @State private var scheduleBlocks: [ScheduleDate] = []
    @State private var selectedDate: ScheduleDate?
    @State private var shouldRefresh = false
    @State private var date_selected = Information.currentnum.1

    var body: some View {
            VStack {
                if showLoadingIndicator {
                    ActivityIndicatorView(isVisible: $showLoadingIndicator, type: .growingArc(.red))
                        .frame(width: 50, height: 50)
                } else {
                    ScrollView {
                        BlockCollection(text: $requestData, whichDate: $date_selected)
                    }
                }
            }
            .onAppear {
                // Start the WC session and load cached schedule data if available
                WatchSessionManager.sharedManager.startSession()
                if requestData.isEmpty,
                   let cachedData = UserDefaults.standard.string(forKey: "cachedScheduleData") {
                    requestData = cachedData
                    loadSchedule()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ReceivedRequestData"))) { note in
                if let info = note.userInfo, let newData = info["request_data"] as? String {
                    requestData = newData
                    // Cache the received schedule data
                    UserDefaults.standard.set(newData, forKey: "cachedScheduleData")
                }
                loadSchedule()
            }
            .refreshable { loadSchedule() }
    }

    private func loadSchedule() {
        showLoadingIndicator = true
        Information.indexnumber = Information.currentnum.0
        if !requestData.isEmpty {  // <-- Changed from "if let ..."
            print("Data found")
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE M/d"
            let today = dateFormatter.string(from: Date())
            
            var filteredBlocks: [ScheduleDate] = []
            // Iterate over parsedJSON from computed property.
            for week in parsedJSON["all_weeks_blocks"].arrayValue {
                for day in week.arrayValue {
                    if let dateString = day[0]["date"].string, dateString == today {
                        for block in day.arrayValue {
                            filteredBlocks.append(ScheduleDate(id: filteredBlocks.count, name: dateString))
                        }
                    }
                }
            }
            print("Dates:")
            print(filteredBlocks)
            DispatchQueue.main.async {
                scheduleBlocks = filteredBlocks
                showLoadingIndicator = false
            }
        } else {
            print("No data found, making request")
            let keychain = KeychainSwift()
            keychain.accessGroup = "group.com.example.CampusCommotion"
//let calurl = keychain.get("calurl") ?? "https://calendar.example.edu/podium/feed/iCal.aspx?z=CALENDAR_FEED_TOKEN"
            //let cluburl = keychain.get("cluburl") ?? "https://calendar.example.edu/podium/feed/iCal.aspx?z=CALENDAR_FEED_TOKEN"
            //let token = keychain.get("token") ?? "6333~DOy2IKmaUuAuPxKsI9JQk11rtX8mzCaCIVYtmdjFXDMwSVL3O41gvNJMu6hoZ4dj"
            let calurl = keychain.get("calurl") ?? ""
            let cluburl = keychain.get("cluburl") ?? ""
            let token = keychain.get("token") ?? ""
            print("calurl: \(calurl)")
            print("cluburl: \(cluburl)")
            print("token: \(token)")
            guard !calurl.isEmpty, !cluburl.isEmpty, !token.isEmpty else {
                print("Error: One or more Keychain values are empty")
                DispatchQueue.main.async { showLoadingIndicator = false }
                return
            }
            let simpleCompletionHandler: () -> Void = { self.loadSchedule() }
            ConnectorClass().makeRequest(calurl: calurl, cluburl: cluburl, token: token, completionHandler: simpleCompletionHandler)
        }
    }
}

/// Model representing a schedule date item.
struct ScheduleDate: Identifiable {
    let id: Int
    let name: String
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
