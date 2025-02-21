//
//  ContentView.swift
//  CampusCommotion
import SwiftUI
import CoreData
import SwiftyJSON
import WidgetKit
import ActivityIndicatorView
import WebKit
import KeychainSwift
import WatchConnectivity

struct ScheduleDate: Identifiable {
    var id: Int
    var name: String
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
    @State var request_data: String = ""
    @State var showingAlert = false
    @State var showLoadingIndicator = false
    @State var date_selected = "n/a"
    @State var day_selected = "n/a"
    @State var warning_opacity = 0.8
    @State var all_keys: [ScheduleDate] = []
    @State var email: String
    @State var calurl: String
    @State var cluburl: String
    @State var token: String
    @State private var shouldRefresh = true
    @State public var menuLoading = true
    @State private var parsedData = JSON()
    
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.colorScheme) var colorScheme
    
    @State private var textFieldIdEmail: String = UUID().uuidString
    @State private var textFieldIdPasscode: String = UUID().uuidString

    init() {
        let keychain = KeychainSwift()
        keychain.accessGroup = "group.com.example.CampusCommotion"
        email = (keychain.get("email") ?? "")
        calurl = (keychain.get("calurl") ?? "")
        cluburl = (keychain.get("cluburl") ?? "")
        token = (keychain.get("token") ?? "")
        if !email.isEmpty {
            parsedData = JSON.init(parseJSON: (UserDefaults(suiteName: "group.com.example.CampusCommotion")!).string(forKey: "request_data") ?? "")
        }
    }
    
    func updateScheduleView() {
        DispatchQueue.global(qos: .userInitiated).async {
            if let requestData = UserDefaults(suiteName: "group.com.example.CampusCommotion")?.string(forKey: "request_data") {
                DispatchQueue.main.async {
                    self.request_data = requestData
                    self.parsedData = JSON(parseJSON: requestData)
                    // Use try with error handling for the throwing call
                    do {
                        try WatchSessionManager.sharedManager.updateApplicationContext(applicationContext: [
                            "request_data": requestData as AnyObject
                        ])
                    } catch {
                        print("Error updating watch context: \(error)")
                    }
                    self.updateUI()
                }
            } else {
                let simpleCompletionHandler: () -> Void = {
                    self.updateScheduleView()
                }
                ConnectorClass().makeRequest(calurl: "", cluburl: "", token: "", completionHandler: simpleCompletionHandler)
            }
        }
    }

    func updateUI() {
        WidgetCenter.shared.reloadAllTimelines()
        all_keys = []
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d"
        let toMatchDate = dateFormatter.string(from: date)
        
        all_keys = []
        var counterID = 0
        
        for (key, day) in parsedData["all_weeks_blocks"][Information.indexnumber] {
            all_keys.append(ScheduleDate(id: counterID, name: day[0]["date"].string ?? ""))
            counterID = counterID + 1
        }
        if date_selected == "n/a" {
            date_selected = Information.currentnum.1
        }
        if all_keys.count > 0 {
            day_selected = all_keys[Int(date_selected)!].name
        } else {
            day_selected = "n/a"
        }
        var calendar = Calendar(identifier: .gregorian)
        let nyTimeZone = TimeZone(identifier: "America/New_York")
        calendar.timeZone = nyTimeZone!
        
        let now = calendar.dateComponents(in: .current, from: Date())
        let tomorrow = DateComponents(year: now.year, month: now.month, day: now.day! + 1, hour: 0, minute: 5)
        _ = calendar.date(from: tomorrow)!
        
        showLoadingIndicator = false
        
        dateFormatter.dateFormat = "dd"
        if day_selected.components(separatedBy: "/").count > 1 {
            if day_selected.contains(Information.todaydate) && Information.indexnumber == Information.currentnum.0 {
                warning_opacity = 0.0
            } else {
                warning_opacity = 0.8
            }
        } else {
            warning_opacity = 0.0
        }
    }

    func setToLoading() {
        self.showLoadingIndicator = true
    }
    func setToNotLoading() {
        self.showLoadingIndicator = false
    }

    var body: some View {
        TabView {
            NavigationView {
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading) {
                        Spacer(minLength: 10)
                        HStack (alignment: .center) {
                            Spacer()
                            Button(action: {
                                if Int(date_selected) == 0 {
                                    if Information.indexnumber != 0 {
                                        Information.indexnumber -= 1
                                        all_keys = []
                                        var counterID = 0
                                        for (key, day) in parsedData["all_weeks_blocks"][Information.indexnumber] {

                                            if day[0]["date"].string!.contains(Information.todaydate) {
                                                date_selected = key
                                                day_selected = day[0]["date"].string!
                                            }
                                            all_keys.append(ScheduleDate(id: counterID, name: day[0]["date"].string!))
                                            counterID = counterID + 1
                                        }
                                        
                                        date_selected = String(all_keys.last?.id ?? 0)
                                        day_selected = all_keys.last?.name ?? ""
                                        if day_selected.contains(Information.todaydate) && Information.indexnumber == Information.currentnum.0 {
                                            warning_opacity = 0.0
                                        } else {
                                            warning_opacity = 0.8
                                        }}} else {
                                            date_selected = String(all_keys[Int(date_selected)! - 1].id)
                                            day_selected = all_keys[Int(date_selected)!].name
                                            if day_selected.contains(Information.todaydate) && Information.indexnumber == Information.currentnum.0 {
                                                warning_opacity = 0.0
                                            } else {
                                                warning_opacity = 0.8
                                            }
                                        }
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.title)
                                    .padding(8)
                                    .frame(alignment: .center)
                                    .background(Color.accentColor)
                                    .foregroundColor(Color.white)
                                    .cornerRadius(10)
                            }
                            
                            Menu(content: {
                                ForEach(0..<all_keys.count, id: \.self) { myNewKey in
                                    Button(action: {
                                        date_selected = String(all_keys[myNewKey].id)
                                        day_selected = all_keys[myNewKey].name
                                        if day_selected.contains(Information.todaydate) && Information.indexnumber == Information.currentnum.0 {
                                            warning_opacity = 0.0
                                        } else {
                                            warning_opacity = 0.8
                                        }
                                    }) {
                                        Text(all_keys[myNewKey].name)
                                    }
                                }
                            }, label: {
                                Text($day_selected.wrappedValue)
                                    .font(.title)
                                    .fontWeight(.semibold)
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.accentColor)
                                    .foregroundColor(Color.white)
                                    .cornerRadius(10)
                            })
                            
                            Button(action: {
                                if Int(date_selected) == (all_keys.count - 1){
                                    if Information.indexnumber != (parsedData["all_weeks_blocks"].count - 1) {
                                        Information.indexnumber += 1
                                        all_keys = []
                                        var counterID = 0
                                        for (key, day) in parsedData["all_weeks_blocks"][Information.indexnumber] {
                                            if day[0]["date"].string!.contains(Information.todaydate) {
                                                date_selected = key
                                                day_selected = day[0]["date"].string!
                                            }
                                            all_keys.append(ScheduleDate(id: counterID, name: day[0]["date"].string!))
                                            counterID = counterID + 1
                                        }
                                        date_selected = String(all_keys[0].id)
                                        day_selected = all_keys[0].name
                                        if day_selected.contains(Information.todaydate) && Information.indexnumber == Information.currentnum.0 {
                                            warning_opacity = 0.0
                                        } else {
                                            warning_opacity = 0.8
                                        }}} else {
                                            if let currentIndex = Int(date_selected),
                                               currentIndex + 1 < all_keys.count {
                                                date_selected = String(all_keys[currentIndex + 1].id)
                                                day_selected = all_keys[Int(date_selected)!].name
                                                if day_selected.contains(Information.todaydate) && Information.indexnumber == Information.currentnum.0 {
                                                    warning_opacity = 0.0
                                                } else {
                                                    warning_opacity = 0.8
                                                }
                                            } else {
                                                print("Index out of range or invalid date_selected")
                                            }

                                        }
                            }) {
                                Image(systemName: "chevron.right")
                                    .font(.title)
                                    .padding(8)
                                    .frame(alignment: .center)
                                    .background(Color.accentColor)
                                    .foregroundColor(Color.white)
                                    .cornerRadius(10)
                            }
                            Spacer()
                        }
                        .onAppear {
                            // Start the WC session when view appears
                            WatchSessionManager.sharedManager.startSession()
                            updateScheduleView()
                        }
                        BlockCollection(text: $request_data, whichDate: $date_selected)
                    }
                }
                .navigationBarItems(
                    leading: HStack {

                        Text("Week \(Int(Information.indexnumber) + 1)")
                            .font(.title3)
                            .padding(5)
                            .background(Color.white)
                            .foregroundColor(Color.black)
                            .cornerRadius(5)
                            
                        Button(action: {
                            Information.indexnumber = Information.currentnum.0
                            all_keys = []
                            var counterID = 0
                            for (key, day) in parsedData["all_weeks_blocks"][Information.indexnumber] {
                                if day[0]["date"].string!.contains(Information.todaydate) {
                                    date_selected = key
                                    day_selected = day[0]["date"].string!
                                }
                                all_keys.append(ScheduleDate(id: counterID, name: day[0]["date"].string!))
                                counterID = counterID + 1
                            }
                            date_selected = Information.currentnum.1
                            if let index = Int(date_selected), index >= 0, index < all_keys.count, !all_keys.isEmpty  {
                                day_selected = all_keys[Int(date_selected)!].name
                                warning_opacity = 0.0
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.uturn.left")
                                Text("today")
                            }
                        }
                        .padding(5)
                        .foregroundColor(.white)
                        .background(Color(red: 218/255, green: 165/255, blue: 32/255))
                        .cornerRadius(20)
                        .opacity($warning_opacity.wrappedValue)
                        
                    },
                    trailing: Button(action: {
                        setToLoading()
                        let simpleCompletionHandler:()->Void =  {
                            updateScheduleView()
                        }
                        ConnectorClass().makeRequest(calurl: calurl, cluburl: cluburl, token: token, completionHandler: simpleCompletionHandler)
                    }) {
                        Image(systemName: "arrow.counterclockwise").imageScale(.large)
                    }
                )
                .overlay(
                    ActivityIndicatorView(isVisible: $showLoadingIndicator, type: .growingArc(.red))
                    .frame(width: 50.0, height: 50.0)
                ).onChange(of: scenePhase) { phase in
                    switch phase {
                    case .background:
                        debugPrint("leaving app")
                    case .active:
                        if showLoadingIndicator {
                            showLoadingIndicator = false
                            showLoadingIndicator = true
                            debugPrint(showLoadingIndicator)
                        }
                    case .inactive:
                        debugPrint("leaving app")
                    @unknown default:
                        print("unknown state")
                    }
                }
                .overlay(
                    VStack(spacing: 0) {
                        Spacer()
                        Text("you're viewing a date that isn't today!")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(8)
                            .background(Color.orange)
                            .foregroundColor(Color.white)
                            .cornerRadius(5)
                            .padding(.leading, 10)
                            .opacity($warning_opacity.wrappedValue)
                    }.padding(.bottom, 15)
                )
            }.navigationViewStyle(.stack).tabItem {
                Image(systemName: "calendar.circle")
                Text("Schedule")
            }

            NavigationView {

                if (UserDefaults(suiteName: "group.com.example.CampusCommotion")?.bool(forKey: "oldMenu") ?? false) {
                SwiftUIWebView(url: URL(string: "https://epicuremenus.com/clients/example/online"), reload: $shouldRefresh)
                        .navigationBarTitle("Today's Menu")
                        .navigationBarItems(trailing:
                            Button(action: {
                                shouldRefresh = true
                            }) {
                                Image(systemName: "arrow.counterclockwise").imageScale(.large)
                            }
                        )
                        .overlay(
                            ActivityIndicatorView(isVisible: $shouldRefresh, type: .growingArc(.red))
                            .frame(width: 50.0, height: 50.0)
                        )
                } else {
                SwiftUIWebView(url: URL(string: "https://epicuremenus.com/clients/ion/example/nn"), reload: $shouldRefresh)
                        .navigationBarTitle("Today's Menu")
                        .navigationBarItems(trailing:
                            Button(action: {
                                shouldRefresh = true
                            }) {
                                Image(systemName: "arrow.counterclockwise").imageScale(.large)
                            }
                        )
                        .overlay(
                            ActivityIndicatorView(isVisible: $shouldRefresh, type: .growingArc(.red))
                            .frame(width: 50.0, height: 50.0)
                        )

                }

            }.navigationViewStyle(.stack).tabItem {
                Image(systemName: "cup.and.saucer")
                Text("Menu")
            }.onChange(of: scenePhase) { phase in
                switch phase {
                case .background:
                    if colorScheme == .light {
                        (UserDefaults(suiteName: "group.com.example.CampusCommotion")!).set("dark", forKey: "lastColors")
                    } else {
                        (UserDefaults(suiteName: "group.com.example.CampusCommotion")!).set("dark", forKey: "lastColors")
                    }
                case .active:
                    let lastState = (UserDefaults(suiteName: "group.com.example.CampusCommotion")!).string(forKey: "lastColors") ?? ""
                    if lastState != "" {
                        if colorScheme == .light && lastState == "dark" {
                            shouldRefresh = true
                        } else if colorScheme == .dark && lastState == "light" {
                            shouldRefresh = true
                        }
                    }
                case .inactive:
                    print("App inactive (menu)")
                @unknown default:
                    print("unknown state (menu)")
                }
            }
            NavigationView {
                NavigationLazyView(CoursesView(selectedclass: "", isclass: false))
            }.navigationViewStyle(.stack).tabItem {
                Image(systemName: "folder")
                Text("Todo")
            }
            NavigationView {
                VStack {
                    List {
                        NavigationLink(destination: ProfileView(some_context: self)) {
                            Text("Configure")
                        }
                        NavigationLink(destination: Preferences()) {
                            Text("Preferences")
                        }
                    }
                }
            }.navigationViewStyle(.stack).tabItem {
                Image(systemName: "person.crop.circle")
                Text("Settings")
            }.onChange(of: scenePhase) { phase in
                switch phase {
                case .background:
                    let date = Date()
                    let calendar = Calendar.current
                    let what_day = calendar.component(.day, from: date)
                    (UserDefaults(suiteName: "group.com.example.CampusCommotion")!).set(what_day, forKey: "lastOpen")
                case .active:
                    let date = Date()
                    let calendar = Calendar.current
                    let day_now = calendar.component(.day, from: date)
                    
                    let lastOpenDay = Int((UserDefaults(suiteName: "group.com.example.CampusCommotion")!).string(forKey: "lastOpen") ?? "-1")
                    
                    if day_now != lastOpenDay && lastOpenDay != -1 {
                        shouldRefresh = true
                    }
                    
                    print("App is Active")
                    UITabBar.appearance().isTranslucent = false
                    UITabBar.appearance().barTintColor = .white
                    if request_data == "" {
                        setToLoading()
                        let simpleCompletionHandler:()->Void =  {
                            updateScheduleView()
                        }
                        ConnectorClass().makeRequest(calurl: calurl, cluburl: cluburl, token: token, completionHandler: simpleCompletionHandler)
                    } else {
                        let parsed_data = JSON.init(parseJSON:request_data)
                        if parsed_data["success"].boolValue {
                            updateScheduleView()
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "dd"
                            let retrieve_day: Int? = Int((parsed_data["day_retrieved"].rawValue as! String?)!)
                            let current_day = Int(dateFormatter.string(from: Date()))
                            if current_day ?? 100 != retrieve_day ?? -100 {
                                setToLoading()
                                let simpleCompletionHandler:()->Void =  {
                                    updateScheduleView()
                                }
                                ConnectorClass().makeRequest(calurl: calurl, cluburl: cluburl, token: token, completionHandler: simpleCompletionHandler)
                            }
                        }

                    }
                case .inactive:
                    print("App is Inactive")
                @unknown default:
                    print("New App state not yet introduced")
                }
            }
            
        }
        .accentColor(Color.red)

        
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
