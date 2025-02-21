//
//  Connector.swift
//  CampusCommotion

import Foundation
import Alamofire
import SwiftyJSON

private let session = Session()

func rgbToHex(red: Int, green: Int, blue: Int) -> String {
    let hexString = String(format: "#%02X%02X%02X", red, green, blue)
    return hexString
}
func applyStyling(letter: String) -> String {
    let backgroundColor: String
    
    // Check if the letter contains any of the special cases first
    if letter.contains("PEG") || letter.contains("PEB") || letter.contains("PEM") || letter.contains("DAN") {
        return "#E1E2E2" // Special case color
    }
    
    // Define the color mapping for base letters
    switch letter {
    case "A", "T":
        backgroundColor = "#f25c5a" // Red
    case "B", "U":
        backgroundColor = "#f7a877" // Orange
    case "C", "V":
        backgroundColor = "#3cb371" // Green
    case "D", "W":
        backgroundColor = "#6495ed" // Blue
    case "E", "X":
        backgroundColor = "#fff44f" // Yellow
    case "F", "Y":
        backgroundColor = "#9370db" // Purple
    case "G", "Z":
        backgroundColor = "#ff69b4" // Pink
    case "Q", "H":
        backgroundColor = "#07ABD7" // Aqua
    case "A Short", "A Long":
        backgroundColor = "#f25c5a" // Red
    case "B Long", "B Short":
        backgroundColor = "#f7a877" // Orange
    case "C Long", "C Short":
        backgroundColor = "#3cb371" // Green
    case "D Long", "D Short":
        backgroundColor = "#6495ed" // Blue
    case "E Long", "E Short":
        backgroundColor = "#fff44f" // Yellow
    case "F Long", "F Short":
        backgroundColor = "#9370db" // Purple
    case "G Long", "G Short":
        backgroundColor = "#ff69b4" // Pink
    case "H Long", "H Short":
        backgroundColor = "#07ABD7" // Aqua
    case "ME":
        backgroundColor = "#90EE90" // Light Green
    case "PE1", "PE2", "PE3", "PE4", "PE5":
        backgroundColor = "#c0c0c0" // Gray
    case "Advising", "Assembly":
        backgroundColor = "#ffffff"
    default:
        // Extract the base letter from the input if it contains a number
        let baseLetter = String(letter.prefix(while: { $0.isLetter }))
        switch baseLetter {
        case "A", "T", "AT":
            backgroundColor = "#f25c5a" // Red
        case "B", "U", "BU":
            backgroundColor = "#f7a877" // Orange
        case "C", "V", "CV":
            backgroundColor = "#3cb371" // Green
        case "D", "W", "DW":
            backgroundColor = "#6495ed" // Blue
        case "E", "X", "EX":
            backgroundColor = "#fff44f" // Yellow
        case "F", "Y", "FY":
            backgroundColor = "#9370db" // Purple
        case "G", "Z", "GZ":
            backgroundColor = "#ff69b4" // Pink
        case "Q", "H", "HQ":
            backgroundColor = "#07ABD7" // Aqua
        default:
            backgroundColor = "#ffffff" // White
        }
    }
    
    return backgroundColor
}
struct ScheduleLink: Codable {
    let username: String
    let url: String
}

struct studentimage: Codable {
    var studentname: String
    var image: String
    var studentID: Int
}

struct CourseData: Codable {
    var coursecode: String
    var students: [studentimage]
    var courseid: Int
    var sectionid: Int
}



func parseICalendar(icalString: String, clubsString: String) -> ([[[[String: Any]]]], [String]) {
    var weekschedules: [[[[String: Any]]]] = []
    var dayschedules: [[[String: Any]]] = []
    var blockschedules: [[String: Any]] = []
    var currentEvent: [String: Any] = [:]
    var uniqueClubs: [String] = []
    var inEvent = false
    var currentDate: String? = nil
    var firstDate: Date?
    var lastDate: Date?
    var onlyDate: Date?
    
    // Helper functions (no changes needed)
    func extractDateFromLine(from input: String) -> Date? {
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Split on colon to find the actual date-time string
        guard let dateTimeRange = trimmedInput.range(of: ":") else {
            print("Error: Date-time separator ':' not found in the input string.")
            return nil
        }
        
        let dateTimeString = String(trimmedInput[dateTimeRange.upperBound...])
        
        // Default time zone if not found
        var timeZoneIdentifier = "EST"
        
        // Check for TZID= in the input
        if let timeZoneRange = trimmedInput.range(of: "TZID=") {
            let timeZoneEndIndex = trimmedInput.range(of: ":", range: timeZoneRange.upperBound..<trimmedInput.endIndex)?.lowerBound ?? trimmedInput.endIndex
            timeZoneIdentifier = String(trimmedInput[timeZoneRange.upperBound..<timeZoneEndIndex])
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss"
        
        // Try setting the correct time zone
        if let timeZone = TimeZone(identifier: timeZoneIdentifier) {
            dateFormatter.timeZone = timeZone
        } else {
            print("Error: Invalid time zone identifier '\(timeZoneIdentifier)'. Using default time zone: EST")
            dateFormatter.timeZone = TimeZone(abbreviation: "EST")
        }
        
        // Parse the date
        guard let date = dateFormatter.date(from: dateTimeString) else {
            print("Error: Failed to parse date-time string '\(dateTimeString)' with format '\(dateFormatter.dateFormat)'.")
            return nil
        }
        
        return date
    }
    
    func extractDayFromLine(from input: String) -> Date? {
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Split on colon to find the actual date-time string
        guard let dateTimeRange = trimmedInput.range(of: ":") else {
            print("Error: Date-time separator ':' not found in the input string.")
            return nil
        }
        
        let dateTimeString = String(trimmedInput[dateTimeRange.upperBound...])
        
        // Default time zone if not found
        var timeZoneIdentifier = "EST"
        
        // Check for TZID= in the input
        if let timeZoneRange = trimmedInput.range(of: "TZID=") {
            let timeZoneEndIndex = trimmedInput.range(of: ":", range: timeZoneRange.upperBound..<trimmedInput.endIndex)?.lowerBound ?? trimmedInput.endIndex
            timeZoneIdentifier = String(trimmedInput[timeZoneRange.upperBound..<timeZoneEndIndex])
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        
        // Try setting the correct time zone
        if let timeZone = TimeZone(identifier: timeZoneIdentifier) {
            dateFormatter.timeZone = timeZone
        } else {
            print("Error: Invalid time zone identifier '\(timeZoneIdentifier)'. Using default time zone: EST")
            dateFormatter.timeZone = TimeZone(abbreviation: "EST")
        }
        
        // Parse the date
        guard let date = dateFormatter.date(from: dateTimeString) else {
            print("Error: Failed to parse date-time string '\(dateTimeString)' with format '\(dateFormatter.dateFormat)'.")
            return nil
        }
        
        return date
    }
    
    func extractTime(from date: Date) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm"
        return timeFormatter.string(from: date)
    }
    
    func isAfternoon(from date: Date) -> Bool {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "a"
        let amPmString = timeFormatter.string(from: date)
        return amPmString != "AM"
    }
    
    func extractStringFromLine(_ line: String) -> String {
        return line.split(separator: ":").dropFirst().joined(separator: ":")
    }
    
    //func extractBlockLetter(from summary: String) -> String {
    //    let components = summary.split(separator: " ").map(String.init)
     //   if components.first != "Advising" {
     //       if components.count >= 2 {
     //           let blockLetter = components[components.count - 2]
     //           return blockLetter
     //       }
     //   } else {
     //       return "Advising"
      //  }
     //   return ""
   // }
  //  func extractBlockLetter(from summary: String) -> String {
   //     if let startIndex = summary.lastIndex(of: "("), let endIndex = summary.lastIndex(of: ")") {
   //         let blockLetter = summary[summary.index(after: startIndex)..<endIndex]
   //         var cleanedBlockLetter = blockLetter.replacingOccurrences(of: "/", with: "")
   //         if cleanedBlockLetter == "Example Academy" {
   //             if let range = summary.range(of: " - ") {
    //                    let textBeforeDash = summary[..<range.lowerBound]
   //                 return String(textBeforeDash)
    //                }
    //            else {
    //                if summary.starts(with: "First Day") {
    //                   return("First Day")
     //               }
     //           }
     //       }
     //       return String(cleanedBlockLetter)
     //   }
     //   return ""
    //}
    
    func extractBlockLetter(from summary: String) -> String {
        if let startIndex = summary.lastIndex(of: "("), let endIndex = summary.lastIndex(of: ")") {
            let blockLetter = summary[summary.index(after: startIndex)..<endIndex]
            let blockLetterString = String(blockLetter)
            
            if blockLetterString == "Advising" {
                return "ADV"
            }
            if blockLetterString == "Example Academy" {
                if let range = summary.range(of: " - ") {
                    let textBeforeDash = summary[..<range.lowerBound]
                    return String(textBeforeDash)
                } else if summary.starts(with: "First Day") {
                    return("First Day")
                }
            }
        }
        
        if let dashIndex = summary.lastIndex(of: "-"),
           let parenIndex = summary.lastIndex(of: "("),
           dashIndex < parenIndex {
            
            let startIndex = summary.index(after: dashIndex)
            let endIndex = summary.index(before: parenIndex)
            var extractedText = summary[startIndex...endIndex]
            
            let cleanedText = String(extractedText)
                .trimmingCharacters(in: .whitespaces)
                .replacingOccurrences(of: "\\d+$", with: "", options: .regularExpression)
            
            return cleanedText
        }
        
        return ""
    }
    
    
    // Process each line from the iCal string
    for line in icalString.components(separatedBy: "\n") {
        if String(line).contains("BEGIN:VEVENT") {
            inEvent = true
            currentEvent = [:]
            
        } else if String(line).contains("END:VEVENT") {
            inEvent = false
            let blockDictionary: [String: Any] = [
                "date": currentEvent["date"] ?? "",
                "blockid": currentEvent["blockLetter"] ?? "",
                "color": currentEvent["color"] ?? "",
                "starttime": currentEvent["starttime"] ?? "",
                "pmstart": currentEvent["isStartAfternoon"] ?? false,
                "endtime": currentEvent["endtime"] ?? "",
                "pmend": currentEvent["isEndAfternoon"] ?? false,
                "classname": currentEvent["classname"] ?? "",
                "location": currentEvent["location"] ?? ""
            ]
            blockschedules.append(blockDictionary)
            currentEvent.removeAll()
        } else if inEvent {
            if line.starts(with: "DTSTART") {
                if let startTime = extractDateFromLine(from: line) {
                    currentEvent["starttime"] = extractTime(from: startTime)
                    if firstDate == nil || startTime < firstDate! {
                        firstDate = startTime
                    }
                    if lastDate == nil || startTime > lastDate! {
                        lastDate = startTime
                    }
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "EEEE M/d"
                    let formattedDate = dateFormatter.string(from: startTime)
                    currentEvent["date"] = formattedDate
                    currentDate = formattedDate
                    currentEvent["isStartAfternoon"] = isAfternoon(from: startTime)

                } else if let startTime = extractDayFromLine(from: line) {
                    currentEvent["starttime"] = "All Day"
                    if firstDate == nil || startTime < firstDate! {
                        firstDate = startTime
                    }
                    if lastDate == nil || startTime > lastDate! {
                        lastDate = startTime
                    }
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "EEEE M/d"
                    let formattedDate = dateFormatter.string(from: startTime)
                    currentEvent["date"] = formattedDate
                    currentDate = formattedDate

                }
            } else if line.starts(with: "DTEND") {
                if let endTime = extractDateFromLine(from: line) {
                    currentEvent["endtime"] = extractTime(from: endTime)
                    currentEvent["isEndAfternoon"] = isAfternoon(from: endTime)
                }
            } else if line.starts(with: "SUMMARY") {
                let className = extractStringFromLine(String(line))
                currentEvent["classname"] = className
                currentEvent["blockLetter"] = extractBlockLetter(from: className)
                if let blockLetter = currentEvent["blockLetter"] as? String {
                    currentEvent["color"] = applyStyling(letter: blockLetter)
                }
            } else if line.starts(with: "LOCATION") {
                currentEvent["location"] = extractStringFromLine(String(line))
            } else if line.starts(with: "DESCRIPTION") {
                currentEvent["description"] = extractStringFromLine(String(line))
            } else if line.starts(with: "UID") {
                currentEvent["blockid"] = extractStringFromLine(String(line))
            }
        }
    }
    if clubsString != "" {
        inEvent = false
        for line in clubsString.components(separatedBy: "\n") {
            if String(line).contains("BEGIN:VEVENT") {
                inEvent = true
                currentEvent = [:]
                
            } else if String(line).contains("END:VEVENT") {
                inEvent = false
                let clubName = currentEvent["classname"] as? String ?? ""
                
                // Append the club to uniqueClubs array if it's not already there
                if !uniqueClubs.contains(clubName) {
                    uniqueClubs.append(clubName)
                }
                
                // Set the block ID to "Clubs" for club events
                let blockDictionary: [String: Any] = [
                    "date": currentEvent["date"] ?? "",
                    "blockid": "CLB",  // All club events will have blockid as "Clubs"
                    "color": "#6A5ACD",
                    "starttime": currentEvent["starttime"] ?? "",
                    "pmstart": currentEvent["isStartAfternoon"] ?? false,
                    "endtime": currentEvent["endtime"] ?? "",
                    "pmend": currentEvent["isEndAfternoon"] ?? false,
                    "classname": clubName,
                    "location": currentEvent["location"] ?? ""
                ]
                blockschedules.append(blockDictionary)
                currentEvent.removeAll()
            } else if inEvent {
                if line.starts(with: "DTSTART") {
                    if let startTime = extractDateFromLine(from: line) {
                        currentEvent["starttime"] = extractTime(from: startTime)
                        currentEvent["isStartAfternoon"] = isAfternoon(from: startTime)
                        if firstDate == nil || startTime < firstDate! {
                            firstDate = startTime
                        }
                        if lastDate == nil || startTime > lastDate! {
                            lastDate = startTime
                        }
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "EEEE M/d"
                        let formattedDate = dateFormatter.string(from: startTime)
                        currentEvent["date"] = formattedDate
                        currentDate = formattedDate
                        
                    } else if let startTime = extractDayFromLine(from: line) {
                        currentEvent["starttime"] = "All Day"
                        if firstDate == nil || startTime < firstDate! {
                            firstDate = startTime
                        }
                        if lastDate == nil || startTime > lastDate! {
                            lastDate = startTime
                        }
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "EEEE M/d"
                        let formattedDate = dateFormatter.string(from: startTime)
                        currentEvent["date"] = formattedDate
                        currentDate = formattedDate
                        
                    }
                } else if line.starts(with: "DTEND") {
                    if let endTime = extractDateFromLine(from: line) {
                        currentEvent["endtime"] = extractTime(from: endTime)
                        currentEvent["isEndAfternoon"] = isAfternoon(from: endTime)
                    }
                } else if line.starts(with: "SUMMARY") {
                    let className = extractStringFromLine(String(line))
                    if className == "First Day of School\r" {
                        currentEvent.removeAll()
                        continue
                    }
                    currentEvent["classname"] = className
                    currentEvent["blockLetter"] = extractBlockLetter(from: className)
                    if let blockLetter = currentEvent["blockLetter"] as? String {
                        currentEvent["color"] = applyStyling(letter: blockLetter)
                    }
                } else if line.starts(with: "LOCATION") {
                    currentEvent["location"] = extractStringFromLine(String(line))
                } else if line.starts(with: "DESCRIPTION") {
                    currentEvent["description"] = extractStringFromLine(String(line))
                } else if line.starts(with: "UID") {
                    currentEvent["blockid"] = extractStringFromLine(String(line))
                }
            }
        }
    }
    // Create dayschedules from blockschedules
    var dayMap: [String: [[String: Any]]] = [:]
    func cleanDateString(_ dateString: String) -> String {
        return dateString.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "EEEE M/d"
    
    // Dictionary to hold blocks organized by date
    //var dayMap: [String: [[String: Any]]] = [:]
    
    // Organize blocks by date
    
    // Convert dayMap to dayschedules
    
    // Determine the range of weeks based on the available dates
    for block in blockschedules {
        if let dateStr = block["date"] as? String {
            if dayMap[dateStr] == nil {
                dayMap[dateStr] = []
            }
            dayMap[dateStr]?.append(block)
        }
    }
    
    
    
    var calendar = Calendar.current
    calendar.firstWeekday = 1
    if firstDate != nil {
        let weekStartDate = calendar.startOfWeek(for: firstDate!)
        let weekEndDate = calendar.endOfWeek(for: lastDate!)
        var currentWeekDate = weekStartDate
        while currentWeekDate <= weekEndDate {
            let weekEndDate = calendar.date(byAdding: .day, value: 6, to: currentWeekDate)!
            let weekDays = calendar.generateDates(for: currentWeekDate, to: weekEndDate)
            // Filter out days with no events
            let weekBlocks = weekDays.compactMap { day in
                dateFormatter.dateFormat = "EEEE M/d"
                let dateKey = dateFormatter.string(from: day)
                let eventsForDay = dayMap[dateKey] ?? []
                return eventsForDay.isEmpty ? nil : eventsForDay
            }
            
            if !weekBlocks.isEmpty { // Add week to schedules only if it contains events
                weekschedules.append(weekBlocks)
            }
            
            currentWeekDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeekDate)!
        }
        
        return (weekschedules, uniqueClubs)
    }
    else {
        return ([], [])
    }
}
    // Calendar extension
extension Calendar {
    func startOfWeek(for date: Date) -> Date {
            // Force the first weekday to Sunday
            var calendar = self
            calendar.firstWeekday = 1 // 1 means Sunday
            
            var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
            components.weekday = calendar.firstWeekday // Set to Sunday (firstWeekday = 1)
            
            return calendar.date(from: components)!
        }

    func endOfWeek(for date: Date) -> Date {
        let startOfWeek = startOfWeek(for: date)
        return self.date(byAdding: .day, value: 6, to: startOfWeek)!
    }

    func generateDates(for startDate: Date, to endDate: Date) -> [Date] {
        var dates: [Date] = []
        var currentDate = startDate
        while currentDate <= endDate {
            dates.append(currentDate)
            currentDate = self.date(byAdding: .day, value: 1, to: currentDate)!
        }
        return dates
    }
}
class ConnectorClass {
    public init() {}

    func makeRequest(calurl: String, cluburl: String, token: String, completionHandler: @escaping () -> Void) {
        var weekschedules: [[[[String: Any]]]] = []
        var uniqueClubs: [String] = []
        let group = DispatchGroup()

        group.enter()
        NetworkManager.shared.request(calurl, method: .get).responseString { response in
            switch response.result {
            case .success(let value):
                if !cluburl.isEmpty {
                    group.enter()
                    NetworkManager.shared.request(cluburl, method: .get).responseString { response in
                        switch response.result {
                        case .success(let value2):
                            (weekschedules, uniqueClubs) = parseICalendar(icalString: value, clubsString: value2)
                            self.saveRequestData(weekschedules: weekschedules)
                        case .failure(let error):
                            print("Request failed with error: \(error)")
                        }
                        group.leave()
                    }
                } else {
                    weekschedules = parseICalendar(icalString: value, clubsString: "").0
                    self.saveRequestData(weekschedules: weekschedules)
                }
            case .failure(let error):
                print(error)
            }
            group.leave()
        }

        if !token.isEmpty {
            group.enter()
            NetworkManager.shared.request("https://canvas.example.edu/api/v1/users/self/enrollments?per_page=100").responseString { response in
                switch response.result {
                case .success(let value):
                    self.handleEnrollmentsResponse(value: value, token: token, group: group, completionHandler: completionHandler)
                case .failure(let error):
                    print("Enrollments request failed with error: \(error)")
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completionHandler()
        }
    }

    private func saveRequestData(weekschedules: [[[[String: Any]]]]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd, HH:mm:ss.SSS"
        let timestamp = dateFormatter.string(from: Date())
        dateFormatter.dateFormat = "dd"
        let retrievedDay = dateFormatter.string(from: Date())

        let requestData: [String: Any] = [
            "success": true,
            "all_weeks_blocks": weekschedules,
            "timestamp": timestamp,
            "day_retrieved": retrievedDay
        ]

        if let theJSONData = try? JSONSerialization.data(withJSONObject: requestData, options: .prettyPrinted),
           let jsontext = String(data: theJSONData, encoding: .utf8) {
            let sharedDefaults = UserDefaults(suiteName: "group.com.example.CampusCommotion")!
            sharedDefaults.set(jsontext, forKey: "request_data")
        }
    }

    private func handleEnrollmentsResponse(value: String, token: String, group: DispatchGroup, completionHandler: @escaping () -> Void) {
    var classStudentsDictionary = [String: CourseData]()
    let enrollments = JSON(parseJSON: value)

    let validEnrollments = enrollments.arrayValue.compactMap { enrollment -> (Int, Int)? in
        let courseId = enrollment["course_id"].intValue
        let sectionID = enrollment["course_section_id"].intValue
        return (courseId > 0 && sectionID > 0) ? (courseId, sectionID) : nil
    }

    validEnrollments.forEach { (courseId, sectionID) in
        group.enter()
        NetworkManager.shared.request("https://canvas.example.edu/api/v1/courses/\(courseId)?per_page=100")
            .responseString { response in
                defer { group.leave() }
                switch response.result {
                case .success(let value):
                    let coursedata = JSON(parseJSON: value)
                    let coursecode = coursedata["course_code"].stringValue.replacingOccurrences(of: "-", with: "*")

                    if classStudentsDictionary[coursecode] == nil {
                        classStudentsDictionary[coursecode] = CourseData(coursecode: coursecode, students: [], courseid: courseId, sectionid: sectionID)
                    }

                    // Fetch students for this course section
                    group.enter()
                    NetworkManager.shared.request("https://canvas.example.edu/api/v1/sections/\(sectionID)/enrollments?include=avatar_url&per_page=100&type=StudentEnrollment")
                        .responseString { response in
                            defer { group.leave() }
                            switch response.result {
                            case .success(let value):
                                let students = JSON(parseJSON: value)
                                students.arrayValue.forEach { student in
                                    classStudentsDictionary[coursecode]?.students.append(studentimage(
                                        studentname: student["user"]["name"].stringValue,
                                        image: student["user"]["avatar_url"].stringValue,
                                        studentID: student["user"]["id"].intValue
                                    ))
                                }
                            case .failure(let error):
                                print("Section enrollments request failed: \(error)")
                            }
                        }
                case .failure(let error):
                    print("Course request failed: \(error)")
                }
            }
    }

    // Notify once all requests are done
    group.notify(queue: .main) {
        do {
            let encodedcourses = try JSONEncoder().encode(classStudentsDictionary)
            UserDefaults(suiteName: "group.com.example.CampusCommotion")!.set(encodedcourses, forKey: "canvascourses")
        } catch {
            print("Error encoding courses: \(error)")
        }
        completionHandler()
    }
}
}
