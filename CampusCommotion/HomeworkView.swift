import Foundation
import SwiftUI
import KeychainSwift

struct HomeworkView: View {
    @State private var styledAttributedString: NSMutableAttributedString? = nil
    @State private var assignmentData: AssignmentData?
    @State private var calendarEventData: CalendarEventData?
    @State private var discussionTopic: DiscussionTopic?
    @State private var discussionEntries: [DiscussionEntry] = []
    @State private var discussionEntriesLoaded: Bool = false
    var token: String = (KeychainSwift().get("token") ?? "")
    var selectedcourseid: Int
    var assignmentid: Int
    var type: String
    
    init(selectedcourseid: Int, assignmentid: Int, type: String) {
        self.selectedcourseid = selectedcourseid
        self.assignmentid = assignmentid
        self.type = type
        print("Initialized HomeworkView with course ID: \(selectedcourseid), assignment ID: \(assignmentid), type: \(type)")
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
                        
                    } else if type == "discussion_topic" {
                        if let discussionTopic = discussionTopic {
                            Text(discussionTopic.title)
                                .font(.largeTitle)
                            if let attributedMessage = parseHTMLToAttributedString(htmlString: discussionTopic.message) {
                                if #available(iOS 15, *) {
                                    Text(AttributedString(attributedMessage))
                                } else {
                                    Text(attributedMessage.string)
                                }
                            }
                            if !discussionEntriesLoaded {
                                Text("Loading discussion entries...")
                                    .onAppear {
                                        loadDiscussionEntries()
                                    }
                            } else {
                                if !discussionEntries.isEmpty {
                                    ForEach(discussionEntries, id: \.id) { entry in
                                        VStack(alignment: .leading) {
                                            Text(entry.user_name)
                                                .font(.headline)
                                            if let attributedMessage = parseHTMLToAttributedString(htmlString: entry.message) {
                                                if #available(iOS 15, *) {
                                                    Text(AttributedString(attributedMessage))
                                                } else {
                                                    Text(attributedMessage.string)
                                                }
                                            }
                                            if let replies = entry.recent_replies {
                                                ForEach(replies, id: \.id) { reply in
                                                    VStack(alignment: .leading) {
                                                        Text(reply.user_name)
                                                            .font(.subheadline)
                                                        if let attributedMessage = parseHTMLToAttributedString(htmlString: reply.message) {
                                                            if #available(iOS 15, *) {
                                                                Text(AttributedString(attributedMessage))
                                                            } else {
                                                                Text(attributedMessage.string)
                                                            }
                                                        }
                                                    }
                                                    .padding(.leading)
                                                }
                                            } else {
                                                Text("No replies")
                                                    .font(.subheadline)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        .padding()
                                    }
                                } else {
                                    Text("Loading discussion entries...")
                                }
                            }
                        } else {
                            Text("Loading discussion topic...")
                                .onAppear {
                                    loadDiscussionTopic()
                                }
                        }
                    } else {
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
        
        do {
            let attributedString = try NSMutableAttributedString(data: htmlData, options: options, documentAttributes: nil)
            if #available(iOS 15, *) {
                attributedString.addAttribute(.foregroundColor, value: textColor, range: NSRange(location: 0, length: attributedString.length))
                attributedString.addAttribute(.font, value: font, range: NSRange(location: 0, length: attributedString.length))
            }
            return attributedString
        } catch {
            print("Error parsing HTML to attributed string: \(error)")
            return nil
        }
    }

    func loadData() {
        if type != "calendar_event" {
            guard let url = URL(string: "https://canvas.example.edu/api/v1/courses/\(selectedcourseid)/assignments/\(assignmentid)?access_token=\(token)") else {
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
            guard let url = URL(string: "https://canvas.example.edu/api/v1/calendar_events/\(assignmentid)?access_token=\(token)") else {
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

    func loadDiscussionTopic() {
        guard let url = URL(string: "https://canvas.example.edu/api/v1/courses/\(selectedcourseid)/discussion_topics/\(assignmentid)?access_token=\(token)") else {
            print("Invalid URL for discussion topic")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data {
                do {
                    let fetchedTopic = try JSONDecoder().decode(DiscussionTopic.self, from: data)
                    DispatchQueue.main.async {
                        self.discussionTopic = fetchedTopic
                        print("Fetched discussion topic: \(fetchedTopic)")
                    }
                } catch {
                    print("Error decoding discussion topic: \(error)")
                }
            } else if let error = error {
                print("Error fetching discussion topic: \(error)")
            }
        }.resume()
    }

    func loadDiscussionEntries() {
        guard !discussionEntriesLoaded else { return }
        guard let url = URL(string: "https://canvas.example.edu/api/v1/courses/\(selectedcourseid)/discussion_topics/\(assignmentid)/entries?access_token=\(token)") else {
            print("Invalid URL for discussion entries")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data {
                do {
                    let fetchedEntries = try JSONDecoder().decode([DiscussionEntry].self, from: data)
                    DispatchQueue.main.async {
                        self.discussionEntries = fetchedEntries
                        self.discussionEntriesLoaded = true
                    }
                    print("Fetched discussion entries: \(fetchedEntries)")
                    for entry in fetchedEntries {
                        print("Entry ID: \(entry.id), Message: \(entry.message), User: \(entry.user_name)")
                        if let replies = entry.recent_replies {
                            for reply in replies {
                                print("Reply ID: \(reply.id), Message: \(reply.message), User: \(reply.user_name)")
                            }
                        }
                    }
                } catch {
                    print("Error decoding discussion entries: \(error)")
                }
            } else if let error = error {
                print("Error fetching discussion entries: \(error)")
            }
        }.resume()
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

struct DiscussionTopic: Codable {
    let id: Int
    let title: String
    let message: String
}

struct DiscussionEntry: Codable {
    let id: Int
    let message: String
    let user_name: String
    let recent_replies: [DiscussionReply]?
}

struct DiscussionReply: Codable {
    let id: Int
    let message: String
    let user_name: String
}

