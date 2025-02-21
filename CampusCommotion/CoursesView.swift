import SwiftUI
import SwiftyJSON
import KeychainSwift
import Alamofire

struct TodoItem: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String
    let type: String
    let courseid: Int
    let duedate: String
    let duetime: String
}

struct CoursesView: View {
    @State private var todos: [TodoItem] = []
    @State private var notretrieved: Bool = true
    @State private var classkey: String?
    @State private var courseid: Int?
    @State private var type: String?
    @State private var token: String
    var keychain = KeychainSwift()
    var selectedclass: String
    var isclass: Bool
    
    private let enccoursedata: Data?
    
    init(selectedclass: String, isclass: Bool) {
        self.selectedclass = selectedclass
        self.isclass = isclass
        keychain.accessGroup = "group.com.sscheffler.CampusCommotion"
        self.token = keychain.get("token") ?? ""
        self.enccoursedata = UserDefaults(suiteName: "group.com.sscheffler.CampusCommotion")?.data(forKey: "canvascourses")
    }
    
    private func loadData() {
        guard let data = enccoursedata else {
            print("No course data available.")
            return
        }
        
        do {
            let coursedata = try JSONDecoder().decode([String: CourseData].self, from: data)
            
            if isclass {
                let classIDtag = selectedclass.split(separator: " ").first ?? ""
                //let classID = (classIDtag?.split(separator: "-").map(String.init).prefix(2).joined(separator: "*")) ?? ""
                for (key, classItem) in coursedata {
                    let classIDFromJSON = classItem.coursecode
                    if classIDFromJSON.contains(classIDtag) {
                        classkey = key
                        courseid = classItem.courseid
                    }
                }
            }
        } catch {
            print("Error decoding course data: \(error.localizedDescription)")
        }
    }
    
    private func loadTodos() {
        notretrieved = true
        todos.removeAll()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let formattedDate = dateFormatter.string(from: Date())
        
        guard let url = URL(string: "https://canvas.exeter.edu/api/v1/planner/items?start_date=\(formattedDate)&per_page=100") else {
            print("Invalid URL")
            return
        }
        
        NetworkManager.shared.request(url).responseData { response in
            switch response.result {
            case .success(let data):
                let jsonString = String(data: data, encoding: .utf8)
                let todoparsed = JSON(parseJSON: jsonString ?? "")
                
                DispatchQueue.main.async {
                    if self.isclass {
                        for (_, item) in todoparsed {
                            if item["course_id"].intValue == self.courseid {
                                let isoDateFormatter = ISO8601DateFormatter()
                                isoDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                                
                                if let date = isoDateFormatter.date(from: item["plannable_date"].stringValue) {
                                    let dateFormatter = DateFormatter()
                                    dateFormatter.dateFormat = "MMMM dd"
                                    
                                    let timeFormatter = DateFormatter()
                                    timeFormatter.dateFormat = "hh:mm a"
                                    
                                    dateFormatter.timeZone = TimeZone(identifier: "America/New_York")
                                    timeFormatter.timeZone = TimeZone(identifier: "America/New_York")
                                    
                                    let formattedDate = dateFormatter.string(from: date)
                                    let formattedTime = timeFormatter.string(from: date)
                                    
                                    self.todos.append(TodoItem(id: item["plannable"]["id"].intValue,
                                                               title: item["plannable"]["title"].stringValue,
                                                               description: item["context_name"].stringValue,
                                                               type: item["plannable_type"].stringValue,
                                                               courseid: item["course_id"].intValue,
                                                               duedate: formattedDate,
                                                               duetime: formattedTime))
                                }
                            }
                        }
                    } else {
                        for (_, item) in todoparsed {
                            let isoDateFormatter = ISO8601DateFormatter()
                            isoDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                            
                            if let date = isoDateFormatter.date(from: item["plannable_date"].stringValue) {
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = "MMMM dd"
                                
                                let timeFormatter = DateFormatter()
                                timeFormatter.dateFormat = "hh:mm a"
                                
                                dateFormatter.timeZone = TimeZone(identifier: "America/New_York")
                                timeFormatter.timeZone = TimeZone(identifier: "America/New_York")
                                
                                let formattedDate = dateFormatter.string(from: date)
                                let formattedTime = timeFormatter.string(from: date)
                                
                                self.todos.append(TodoItem(id: item["plannable"]["id"].intValue,
                                                           title: item["plannable"]["title"].stringValue,
                                                           description: item["context_name"].stringValue,
                                                           type: item["plannable_type"].stringValue,
                                                           courseid: item["course_id"].intValue,
                                                           duedate: formattedDate,
                                                           duetime: formattedTime))
                            }
                        }
                    }
                    
                    self.notretrieved = false
                }
            case .failure(let error):
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    var body: some View {
        VStack {
            if notretrieved {
                Text("Loading...")
            } else {
                if !todos.isEmpty {
                    List(todos, id: \.id) { todo in
                        NavigationLink(destination: NavigationLazyView(HomeworkView(selectedcourseid: todo.courseid, assignmentid: todo.id, type: todo.type))) {
                            VStack(alignment: .leading) {
                                Text(todo.title)
                                    .font(.headline)
                                
                                HStack {
                                    Text(todo.description)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    VStack {
                                        Text(todo.duedate)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                            .frame(maxWidth: .infinity, alignment: .trailing)
                                        Text(todo.duetime)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                            .frame(maxWidth: .infinity, alignment: .trailing)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if token != "" {
                        Text(isclass ? "It seems you don't have any homework due for this course right now." : "It seems you don't have any homework right now.")
                    } else {
                        Text("Please enter Canvas token to see homework.")
                    }
                }
            }
            Spacer()
            if isclass, enccoursedata != nil, !notretrieved {
                NavigationLink(destination: NavigationLazyView(MembersView(selectedclass: selectedclass, classkey: classkey))) {
                    Text("Students")
                        .fontWeight(.semibold)
                        .font(.title3)
                        .padding(6)
                        .background(Color.accentColor)
                        .foregroundColor(Color.white)
                        .cornerRadius(10)
                        .padding(.leading, 15)
                        .padding(.trailing, 15)
                }
            }
        }
        .onAppear {
            loadData()
            loadTodos()
            let keychain = KeychainSwift()
            keychain.accessGroup = "group.com.sscheffler.CampusCommotion"
            token = keychain.get("token") ?? ""
        }
        .navigationBarTitle("Homework")
        .listStyle(GroupedListStyle())
        .foregroundColor(.white)
    }
}
