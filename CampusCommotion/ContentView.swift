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

struct ScheduleDate: Identifiable {
    var id: Int
    var name: String
}
struct Information {
    public static var todaydate: String {
            let df = DateFormatter()
            df.dateFormat = "M/d"
            return df.string(from: Date())
        }
    
    public static var currentnum: (Int, String) {
            let request_data = (UserDefaults(suiteName: "group.com.sscheffler.CampusCommotion")!).string(forKey: "request_data")  ?? ""
            
            for i in (0..<JSON.init(parseJSON:request_data)["all_weeks_blocks"].count) {
                for (key, day) in JSON.init(parseJSON:request_data)["all_weeks_blocks"][i] {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "M/d"
                    let calendar = Calendar.current
                    let currentYear = calendar.component(.year, from: Date())
                    let currentMonth = calendar.component(.month, from: Date())
                    
                    //  if day[0]["date"].string!.contains(todaydate) {
                    //    print(i)
                    //    print(key)
                    //    print("1")
                    //    return (i, key)
                    //}
                    //print(String(day[0]["date"].string!.split(separator: " ")[1]))
                    //print(todaydate)
                    if String(day[0]["date"].string?.split(separator: " ")[1] ?? "") == todaydate {
                        print(i)
                        print(key)
                        print("1")
                        return (i, key)
                      } else {
                          var idate = dateFormatter.date(from: String(day[0]["date"].string?.split(separator: " ")[1] ?? ""))
                        if var unwrappedIdate = idate {
                            print("Before if conditions: currentMonth=\(currentMonth), monthComponent=\(calendar.component(.month, from: unwrappedIdate))")
                            if currentMonth == 12 && calendar.component(.month, from: unwrappedIdate) == 1 {
                                idate = calendar.date(bySetting: .year, value: currentYear + 1, of: unwrappedIdate)
                            } else if currentMonth <= 4 && calendar.component(.month, from: unwrappedIdate) >= 11 {
                                var comps = Calendar.current.dateComponents([.year, .month, .day], from: unwrappedIdate)
                                //idate = calendar.date(bySetting: .year, value: currentYear, of: unwrappedIdate)
                                var dc = DateComponents(year: currentYear - 1, month: comps.month, day: comps.day)
                                idate = Calendar(identifier: .gregorian).date(from: dc)
                            } else {
                                var comps = Calendar.current.dateComponents([.year, .month, .day], from: unwrappedIdate)
                                //idate = calendar.date(bySetting: .year, value: currentYear, of: unwrappedIdate)
                                var dc = DateComponents(year: currentYear, month: comps.month, day: comps.day)
                                idate = Calendar(identifier: .gregorian).date(from: dc)
                            }

                            if var updatedIdate = idate, updatedIdate > Date() {
                                return (i, key)
                            }
                        }
                    }
                }
            }
            return (0, "0")
        }
    static var indexnumber = currentnum.0
}

struct ContentView: View {
    @State var request_data: String = (UserDefaults(suiteName: "group.com.sscheffler.CampusCommotion")!).string(forKey: "request_data")  ?? ""
    @State var menu_data: String = (UserDefaults(suiteName: "group.com.sscheffler.CampusCommotion")!).string(forKey: "menu_data")  ?? ""
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
    //@State private var oldMenu: Bool = (UserDefaults(suiteName: "group.com.sscheffler.CampusCommotion")?.bool(forKey: "oldMenu") ?? false)
    
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.colorScheme) var colorScheme
    
    @State private var textFieldIdEmail: String = UUID().uuidString
    @State private var textFieldIdPasscode: String = UUID().uuidString

    init() {
        let keychain = KeychainSwift()
        keychain.accessGroup = "group.com.sscheffler.CampusCommotion"
        email = (keychain.get("email") ?? "")
        calurl = (keychain.get("calurl") ?? "")
        cluburl = (keychain.get("cluburl") ?? "")
        token = (keychain.get("token") ?? "")
    }
    
    func updateScheduleView() {
        print(Information.currentnum)
        if ((UserDefaults(suiteName: "group.com.sscheffler.CampusCommotion")!).string(forKey: "request_data") != nil) {
            request_data = (UserDefaults(suiteName: "group.com.sscheffler.CampusCommotion")!).string(forKey: "request_data")  ?? ""
        }
        else {
            let simpleCompletionHandler:()->Void =  {
                updateScheduleView()
            }
            ConnectorClass().makeRequest(calurl: "", cluburl: "", token: "", completionHandler: simpleCompletionHandler)
            request_data = (UserDefaults(suiteName: "group.com.sscheffler.CampusCommotion")!).string(forKey: "request_data")  ?? ""
        }

        print(request_data)
        WidgetCenter.shared.reloadAllTimelines()
        all_keys = []
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d"
        let toMatchDate = dateFormatter.string(from: date)
        //debugPrint(toMatchDate)
        
        all_keys = []
        var counterID = 0
        
        for (key, day) in JSON.init(parseJSON:request_data)["all_weeks_blocks"][Information.indexnumber] {
            //debugPrint(day[0]["date"].string)
            //debugPrint(toMatchDate)
            //if day[0]["date"].string!.contains(toMatchDate) {
            //    date_selected = key
            //    day_selected = day[0]["date"].string!
            //}
            //if key.contains(toMatchDate) {
            //    date_selected = key
            //}
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
        if day_selected.components(separatedBy: "/").count > 1{
            if day_selected.contains(Information.todaydate) && Information.indexnumber == Information.currentnum.0 {
            //if current_day ?? 100 != retrieve_day ?? -100 {
                warning_opacity = 0.0
            } else {
                warning_opacity = 0.8
            }
        } else {
            warning_opacity = 0.0
        }
    }

    func setToLoading() {
        debugPrint("set to loading")
        self.showLoadingIndicator = true
    }
    func setToNotLoading() {
        debugPrint("set to loading")
        self.showLoadingIndicator = false
    }

    var body: some View {
        TabView {
            NavigationView {
                ScrollView(.vertical) {
                    VStack(alignment: .leading) {
                        Spacer(minLength: 10)
                        HStack (alignment: .center) {
                            Spacer()
                            Button(action: {
                                // Handle the action for the previous button
                                debugPrint("Previous Button Tapped")
                                if Int(date_selected) == 0 {
                                    if Information.indexnumber != 0 {
                                        Information.indexnumber -= 1
                                        all_keys = []
                                        var counterID = 0
                                        for (key, day) in JSON.init(parseJSON:request_data)["all_weeks_blocks"][Information.indexnumber] {

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
                                            print(date_selected)
                                            date_selected = String(all_keys[Int(date_selected)! - 1].id)
                                            day_selected = all_keys[Int(date_selected)!].name
                                            print(day_selected)
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
                                        debugPrint(all_keys)
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
                                debugPrint("Next Button Tapped")
                                if Int(date_selected) == (all_keys.count - 1){
                                    if Information.indexnumber != (JSON.init(parseJSON:request_data)["all_weeks_blocks"].count - 1) {
                                        Information.indexnumber += 1
                                        all_keys = []
                                        var counterID = 0
                                        for (key, day) in JSON.init(parseJSON:request_data)["all_weeks_blocks"][Information.indexnumber] {
                                            //debugPrint(day[0]["date"].string)
                                            //debugPrint(toMatchDate)
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
                                        //if current_day ?? 100 != retrieve_day ?? -100 {
                                            warning_opacity = 0.0
                                        } else {
                                            warning_opacity = 0.8
                                        }}} else {
                                            print(date_selected)
                                            if let currentIndex = Int(date_selected),
                                               currentIndex + 1 < all_keys.count {
                                                date_selected = String(all_keys[currentIndex + 1].id)
                                                day_selected = all_keys[Int(date_selected)!].name
                                                print(day_selected)
                                                if day_selected.contains(Information.todaydate) && Information.indexnumber == Information.currentnum.0 {
                                                    warning_opacity = 0.0
                                                } else {
                                                    warning_opacity = 0.8
                                                }
                                            } else {
                                                // Handle the case where index is out of range or date_selected is not a valid Int
                                                // For example, you could set date_selected to a default value or leave it unchanged
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
                        .onAppear() {
                            updateScheduleView()
                        }
                        BlockCollection(text: $request_data, whichDate: $date_selected)
                    }
                }
                //.navigationBarTitle("Week \(Int(Information.indexnumber) + 1)")
                .navigationBarItems(leading: Button(action: {
                    //debugPrint(all_keys)
                    Information.indexnumber = Information.currentnum.0
                    all_keys = []
                    var counterID = 0
                    for (key, day) in JSON.init(parseJSON:request_data)["all_weeks_blocks"][Information.indexnumber] {
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
)
                .navigationBarItems(leading:
                                        HStack {
                                            Text("Week \(Int(Information.indexnumber) + 1)")
                                        }
                                        .font(.title3)
                                        .padding(5)
                                        .background(Color.white)
                                        .foregroundColor(Color.black)
                                        .cornerRadius(5)
                )
                .navigationBarItems(trailing:
                    Button(action: {
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

                if (UserDefaults(suiteName: "group.com.sscheffler.CampusCommotion")?.bool(forKey: "oldMenu") ?? false) {
                SwiftUIWebView(url: URL(string: "https://epicuremenus.com/clients/exeter/online"), reload: $shouldRefresh)
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
                SwiftUIWebView(url: URL(string: "https://epicuremenus.com/clients/ion/exeter/nn"), reload: $shouldRefresh)
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
                        //(UserDefaults(suiteName: "group.com.sscheffler.CampusCommotion")!).set("light", forKey: "lastColors")
                        (UserDefaults(suiteName: "group.com.sscheffler.CampusCommotion")!).set("dark", forKey: "lastColors")
                    } else {
                        (UserDefaults(suiteName: "group.com.sscheffler.CampusCommotion")!).set("dark", forKey: "lastColors")
                    }
                case .active:
                    let lastState = (UserDefaults(suiteName: "group.com.sscheffler.CampusCommotion")!).string(forKey: "lastColors") ?? ""
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
                NavigationLazyView(CoursesView(selectedclass: "", teacherusername: "", isclass: false))
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
                    (UserDefaults(suiteName: "group.com.sscheffler.CampusCommotion")!).set(what_day, forKey: "lastOpen")
                case .active:
                    let date = Date()
                    let calendar = Calendar.current
                    let day_now = calendar.component(.day, from: date)
                    
                    let lastOpenDay = Int((UserDefaults(suiteName: "group.com.sscheffler.CampusCommotion")!).string(forKey: "lastOpen") ?? "-1")
                    
                    if day_now != lastOpenDay && lastOpenDay != -1 {
                        shouldRefresh = true
                    }
                    
                    print("App is Active")
                    //debugPrint((UserDefaults(suiteName: "group.com.sscheffler.CampusCommotion")!).string(forKey: "request_data")  ?? "")
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
