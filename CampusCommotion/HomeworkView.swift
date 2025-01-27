import Foundation
import SwiftUI
import KeychainSwift

struct HomeworkView: View {
    @State private var styledAttributedString: NSMutableAttributedString? = nil
    @State private var assignmentData: AssignmentData?
    @State private var calendarEventData: CalendarEventData?
    var keychain = KeychainSwift()
    var selectedcourseid: Int
    var assignmentid: Int
    var type: String
    var token: String
    
    init(selectedcourseid: Int, assignmentid: Int, type: String) {
        self.selectedcourseid = selectedcourseid
        self.assignmentid = assignmentid
        self.type = type
        keychain.accessGroup = "group.com.sscheffler.CampusCommotion"
        token = keychain.get("token") ?? ""
        loadData()
    }
    
    var body: some View {
        let dateFormatter: DateFormatter = {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                return formatter
            }()
        let timeFormatter: DateFormatter = {
                let formatter = DateFormatter()
            formatter.timeStyle = .short
                return formatter
            }()
        let dayFormatter: DateFormatter = {
                let formatter = DateFormatter()
            formatter.dateStyle = .medium
                return formatter
            }()
        ScrollView {
            Group {
                if let assignmentData = assignmentData {
                    if assignmentData.description != nil {
                        if assignmentData.name != nil {
                            Text(assignmentData.name!)
                            .font(.largeTitle) } else {
                                Text("No Title For This Assignment")
                                    .font(.largeTitle)
                            }
                        
                        if assignmentData.due_at != nil {
                            Text("Due: " + dateFormatter.string(from: assignmentData.due_at!))
                            .font(.title3) } else {
                                Text("No due date for this assignment.")
                                    .font(.title3)
                            }
                        
                        Spacer()
                        //.navigationBarTitle(assignmentData.name)
                        if let styledAttributedString = styledAttributedString {
                            if #available(iOS 15, *) {
                                Text(AttributedString(styledAttributedString))
                            } else {
                                Text(styledAttributedString.string)
                            }}
                        else {
                            Text("Loading...")
                        }
                        Spacer()
                    } else {
                        if assignmentData.name != nil {
                            Text(assignmentData.name!)
                            .font(.largeTitle) } else {
                                Text("No Title For This Assignment")
                                    .font(.largeTitle)
                            }
                        
                        if assignmentData.due_at != nil {
                            Text("Due: " + dateFormatter.string(from: assignmentData.due_at!))
                            .font(.title3) } else {
                                Text("No due date for this assignment.")
                                    .font(.title3)
                            }
                        
                        Spacer()
                        Text("No description for this assignment.")
                        Spacer()
                    }
                } else {
                    if type == "calendar_event" {
                        if let calendarEventData = calendarEventData {
                            if calendarEventData.title != nil {
                                Text(calendarEventData.title)
                                .font(.largeTitle) } else {
                                    Text("No Title For This Assignment")
                                        .font(.largeTitle)
                                }
                            if calendarEventData.start_at != nil {
                                Text(dayFormatter.string(from: calendarEventData.start_at!))
                                    .font(.title3)
                                if calendarEventData.start_at != nil && calendarEventData.end_at != nil {
                                    Text(timeFormatter.string(from: calendarEventData.start_at!) + " - " + timeFormatter.string(from: calendarEventData.end_at!))
                                        .font(.title3)
                                }
                            }
                            if calendarEventData.location_name != nil {
                                Text(calendarEventData.location_name!)
                                .font(.title3) }
                            if let styledAttributedString = styledAttributedString {
                                if #available(iOS 15, *) {
                                    Text(AttributedString(styledAttributedString))
                                } else {
                                    Text(styledAttributedString.string)
                                }}
                        } else {
                            Text("Loading...")
                                .onAppear(perform: loadData)
                        }
                        
                    } else
                    {
                        Text("Loading...")
                            .onAppear(perform: loadData)
                    }
                }
            }
                .padding()
        }
    }
    
    private func parseHTMLToAttributedString(htmlString: String, textColor: UIColor = .white, font: UIFont = UIFont.systemFont(ofSize: 20)) -> NSAttributedString? {
        guard let htmlData = htmlString.data(using: .unicode) else { return nil }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html
        ]
        
        if let attributedString = try? NSMutableAttributedString(data: htmlData, options: options, documentAttributes: nil) {
            if #available(iOS 15, *) {
                attributedString.addAttribute(.foregroundColor, value: textColor, range: NSRange(location: 0, length: attributedString.length))
                attributedString.addAttribute(.font, value: font, range: NSRange(location: 0, length: attributedString.length))
            }
            return attributedString
        }
        return nil
    }

    func loadData() {
        if type != "calendar_event" {
            guard let url = URL(string: "https://canvas.exeter.edu/api/v1/courses/\(selectedcourseid)/assignments/\(assignmentid)?access_token=\(token)") else {
                print("Invalid URL")
                return
            }
            
            URLSession.shared.dataTask(with: url) { data, _, error in
                if let data = data {
                    do {
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        let fetchedData = try decoder.decode(AssignmentData.self, from: data)
                        
                        DispatchQueue.main.async {
                            self.assignmentData = fetchedData
                            
                            if let description = fetchedData.description,
                               let attributedString = parseHTMLToAttributedString(htmlString: description) {
                                self.styledAttributedString = NSMutableAttributedString(attributedString: attributedString)
                            }
                        }
                    } catch {
                        print("Error decoding assignment data: \(error)")
                    }
                } else if let error = error {
                    print("Error fetching data: \(error)")
                }
            }.resume()
        } else {
            guard let url = URL(string: "https://exeter.instructure.com/api/v1/calendar_events/\(assignmentid)?access_token=\(token)") else {
                print("Invalid URL")
                return
            }
            
            URLSession.shared.dataTask(with: url) { data, _, error in
                if let data = data {
                    do {
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        let fetchedEvent = try decoder.decode(CalendarEventData.self, from: data)
                        
                        DispatchQueue.main.async {
                            self.calendarEventData = fetchedEvent
                            
                            if let description = fetchedEvent.description,
                               let attributedString = parseHTMLToAttributedString(htmlString: description) {
                                self.styledAttributedString = NSMutableAttributedString(attributedString: attributedString)
                            }
                        }
                    } catch {
                        print("Error decoding calendar event data: \(error)")
                    }
                } else if let error = error {
                    print("Error fetching calendar event data: \(error)")
                }
            }.resume()
        }
    }
}

struct AssignmentData: Codable {
    let name: String?
    let due_at: Date?
    let description: String?
    let location: String?
}

struct CalendarEventData: Codable {
    let id: Int
    let title: String
    let start_at: Date?
    let end_at: Date?
    let location_name: String?
    let description: String?
    let url: String
}

