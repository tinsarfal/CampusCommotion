import Foundation
import SwiftUI
import KeychainSwift
import Alamofire

struct HomeworkView: View {
    @State private var styledAttributedString: NSMutableAttributedString? = nil
    @State private var assignmentData: AssignmentData?
    @State private var calendarEventData: CalendarEventData?
    @State private var discussionTopic: DiscussionTopic?
    @State private var discussionEntries: [DiscussionEntry]?
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
                if type == "assignment" {
                if let assignmentData = assignmentData {
                    if assignmentData.description != nil {
                        if assignmentData.name != nil {
                            Text(assignmentData.name!)
                            .font(.largeTitle)
                            .multilineTextAlignment(.center)} else {
                                Text("No Title For This Assignment")
                                    .font(.largeTitle)
                                    .multilineTextAlignment(.center)
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
                                Text(AttributedString(styledAttributedString))
                            }
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
                        if let lockdetails = assignmentData.lock_explanation {
                            Text(lockdetails)
                        } else {
                            Text("No description for this assignment.")
                        }
                        Spacer()
                    }
                } else {
                    Text("Loading...")
                        .onAppear(perform: loadData)
                }
            } else if type == "calendar_event" {
                        if let calendarEventData = calendarEventData {
                            if calendarEventData.title != nil {
                                Text(calendarEventData.title)
                                .font(.largeTitle)
                                .multilineTextAlignment(.center)} else {
                                    Text("No Title For This Assignment")
                                        .font(.largeTitle)
                                        .multilineTextAlignment(.center)
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
                                    Text(AttributedString(styledAttributedString))
                                }
                        } else {
                            Text("Loading...")
                                .onAppear(perform: loadData)
                        }
                        
                    } else if type == "discussion_topic" {
                        if let discussionTopic = discussionTopic {
                            Text(discussionTopic.title)
                                .font(.largeTitle)
                                .multilineTextAlignment(.center)
                            if let attributedMessage = discussionTopic.attributedMessage {
                                Text(AttributedString(attributedMessage))
                            }
                        } else {
                            Text("Loading discussion topic...")
                                .onAppear {
                                    loadDiscussionTopic()
                                }
                        }
                        if let discussionEntries = discussionEntries {
                            ForEach(discussionEntries, id: \.id) { entry in
                                VStack(alignment: .leading) {
                                    Text(entry.user_name)
                                        .font(.headline)
                                    // Use attributedMessage instead of parsing in the view
                                    if let attributedMessage = entry.attributedMessage {
                                        Text(AttributedString(attributedMessage))

                                    }
                                    if let replies = entry.recent_replies {
                                        ForEach(replies, id: \.id) { reply in
                                            VStack(alignment: .leading) {
                                                Text(reply.user_name)
                                                    .font(.subheadline)
                                                // Use attributedMessage instead of parsing in the view
                                                if let attributedMessage = reply.attributedMessage {
                                                    Text(AttributedString(attributedMessage))
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
                            Text("Loading entries...")
                                .onAppear {
                                        loadDiscussionEntries()
                                }
                        }
                    } else if type == "announcement" {
                        if let discussionTopic = discussionTopic {
                            Text(discussionTopic.title)
                                .font(.largeTitle)
                                .multilineTextAlignment(.center)
                            if let postedat = discussionTopic.posted_at {
                            Text("Posted: " + dateFormatter.string(from: postedat))
                                    .font(.title3)
                            }
                            if let attributedMessage = discussionTopic.attributedMessage {
                                Text(AttributedString(attributedMessage))
                            }
                        } else {
                            Text("Loading announcement...")
                                .onAppear {
                                    loadDiscussionTopic()
                                }
                        }
                    } else {
                        Text("Loading...")
                            .onAppear(perform: loadData)
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
                attributedString.addAttribute(.foregroundColor, value: textColor, range: NSRange(location: 0, length: attributedString.length))
                attributedString.addAttribute(.font, value: font, range: NSRange(location: 0, length: attributedString.length))
                attributedString.enumerateAttribute(.backgroundColor, in: NSRange(location: 0, length: attributedString.length)) { value, range, _ in
                    if let color = value as? UIColor, color.isVeryLight {
                        attributedString.addAttribute(.backgroundColor, value: UIColor.orange, range: range)
                    }
                }
            return attributedString
        } catch {
            print("Error parsing HTML to attributed string: \(error)")
            return nil
        }
    }

    func loadData() {
        if type != "calendar_event" {
            let url = "https://canvas.example.edu/api/v1/courses/\(selectedcourseid)/assignments/\(assignmentid)?access_token=\(token)"
            
            NetworkManager.shared.request(url).responseData { response in
                switch response.result {
                case .success(let data):
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
                case .failure(let error):
                    print("Error fetching data: \(error)")
                }
            }
        } else {
            let url = "https://canvas.example.edu/api/v1/calendar_events/\(assignmentid)?access_token=\(token)"
            
            NetworkManager.shared.request(url).responseData { response in
                switch response.result {
                case .success(let data):
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
                case .failure(let error):
                    print("Error fetching calendar event data: \(error)")
                }
            }
        }
    }

    func loadDiscussionTopic() {
        let url = "https://canvas.example.edu/api/v1/courses/\(selectedcourseid)/discussion_topics/\(assignmentid)?access_token=\(token)"
        
        NetworkManager.shared.request(url).responseData { response in
            switch response.result {
            case .success(let data):
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let fetchedTopic = try decoder.decode(DiscussionTopic.self, from: data)
                    DispatchQueue.main.async {
                        self.discussionTopic = fetchedTopic
                        self.discussionTopic?.attributedMessage = parseHTMLToAttributedString(htmlString: fetchedTopic.message)
                        print("Fetched discussion topic: \(fetchedTopic)")
                        self.loadDiscussionEntries()
                    }
                } catch {
                    print("Error decoding discussion topic: \(error)")
                }
            case .failure(let error):
                print("Error fetching discussion topic: \(error)")
            }
        }
    }

    func loadDiscussionEntries() {
        let url = "https://canvas.example.edu/api/v1/courses/\(selectedcourseid)/discussion_topics/\(assignmentid)/entries?access_token=\(token)"
        
        NetworkManager.shared.request(url).responseData { response in
            switch response.result {
            case .success(let data):
                do {
                    var fetchedEntries = try JSONDecoder().decode([DiscussionEntry].self, from: data)
                    
                    // Parse HTML for each entry and its replies
                    for index in fetchedEntries.indices {
                        if let attributed = parseHTMLToAttributedString(htmlString: fetchedEntries[index].message) {
                            fetchedEntries[index].attributedMessage = attributed
                        }
                        if var replies = fetchedEntries[index].recent_replies {
                            for replyIndex in replies.indices {
                                if let attributed = parseHTMLToAttributedString(htmlString: replies[replyIndex].message) {
                                    replies[replyIndex].attributedMessage = attributed
                                }
                            }
                            fetchedEntries[index].recent_replies = replies
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.discussionEntries = fetchedEntries
                    }
                } catch {
                    print("Error decoding discussion entries: \(error)")
                }
            case .failure(let error):
                print("Error fetching discussion entries: \(error)")
            }
        }
    }
}

extension UIColor {
    var isVeryLight: Bool {
        var white: CGFloat = 0
        self.getWhite(&white, alpha: nil)
        return white > 0.9
    }
}

struct AssignmentData: Codable {
    let name: String?
    let due_at: Date?
    let description: String?
    let location: String?
    let lock_info: LockInfo?
    let lock_explanation: String?
}

struct LockInfo: Codable {
    let unlock_at: String?
    let asset_string: String?
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
    let posted_at: Date?
    var attributedMessage: NSAttributedString?

    enum CodingKeys: String, CodingKey {
        case id, title, message, posted_at
    }
}

struct DiscussionEntry: Codable {
    let id: Int
    let message: String
    let user_name: String
    var recent_replies: [DiscussionReply]?
    var attributedMessage: NSAttributedString?

    enum CodingKeys: String, CodingKey {
        case id, message, user_name, recent_replies
    }
}

struct DiscussionReply: Codable {
    let id: Int
    let message: String
    let user_name: String
    var attributedMessage: NSAttributedString?

    enum CodingKeys: String, CodingKey {
        case id, message, user_name
    }
}

