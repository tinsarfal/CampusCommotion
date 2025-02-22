import SwiftUI
import SwiftyJSON
import ActivityIndicatorView
import KeychainSwift
import WatchConnectivity
import WidgetKit

struct Event: Codable {
    let pmstart: Bool
    let starttime: String
    let location: String
    let blockid: String
    let color: String
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
    static var isOld: Bool = true

    // Change the second element of the tuple to Int
    private static var _currentnum: (Int, Int)? = nil
    private static var lastUpdateDate: String? = nil
    
    public static var currentnum: (Int, Int) {
        let today = todaydate
        
        if let cachedCurrentnum = _currentnum, lastUpdateDate == today, !isOld {
            return cachedCurrentnum
        }
        
        guard let request_data = UserDefaults(suiteName: "group.com.example.CampusCommotion")?.string(forKey: "request_data"),
              let requestDataJSON = try? JSON(parseJSON: request_data) else {
            return (0, 0)
        }
        
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let currentMonth = calendar.component(.month, from: Date())

        for i in 0..<requestDataJSON["all_weeks_blocks"].count {
            for (key, day) in requestDataJSON["all_weeks_blocks"][i] {
                guard
                    let rawDateString = day[0]["date"].string?.split(separator: " ").last,
                    let intKey = Int(key)
                else { continue }
                
                if rawDateString == today {
                    _currentnum = (i, intKey)
                    isOld = false
                    lastUpdateDate = today
                    return (i, intKey)
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
                        _currentnum = (i, intKey)
                        isOld = false
                        lastUpdateDate = today
                        return (i, intKey)
                    }
                }
            }
        }
        _currentnum = (0, 0)
        lastUpdateDate = today
        return (0, 0)
    }
    
    static var indexnumber = currentnum.0
}

struct ContentView: View {
    @State private var requestData: String = ""
    private var parsedJSON: JSON { JSON(requestData) }
    @State private var showLoadingIndicator = false
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
                    BlockCollection(text: $requestData, whichDate: .constant(String(date_selected)))
                }
            }
        }
        .onAppear {
            WatchSessionManager.sharedManager.startSession()
            if requestData == "" {
                if let cachedData = UserDefaults(suiteName: "group.com.example.CampusCommotion")?.string(forKey: "request_data"), cachedData != "" {
                    print("CachedData: " + cachedData)
                    requestData = cachedData
                } else {
                    let context = WCSession.default.receivedApplicationContext
                    if let retrievedData = context["request_data"] as? String {
                        print("retrievedData: " + retrievedData)
                        requestData = retrievedData
                        UserDefaults(suiteName: "group.com.example.CampusCommotion")!.set(requestData, forKey: "request_data")
                        Information.isOld = true
                        Information.indexnumber = Information.currentnum.0
                        date_selected = Information.currentnum.1
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ReceivedRequestData"))) { note in
            if let info = note.userInfo, let newData = info["request_data"] as? String {
                requestData = newData
                print("newData" + newData)
                UserDefaults(suiteName: "group.com.example.CampusCommotion")!.set(newData, forKey: "request_data")
                Information.isOld = true
                Information.indexnumber = Information.currentnum.0
                date_selected = Information.currentnum.1
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
}

struct ScheduleDate: Identifiable {
    let id: Int
    let name: String
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
