import SwiftUI
import SwiftyJSON
import URLImage
import KeychainSwift

extension String: Identifiable {
    public var id: String {
        return self
    }
}

struct IdentifiableImage: Identifiable {
    var id = UUID()
    var image: Image
}

struct UsersResponse: Codable {
    let users: [User]
}

struct User: Codable {
    let id: Int
    let user_id: Int
    let course_id: Int
    let user: UserInfo
}
struct UserInfo: Codable {
    let id: Int
    let name: String
    let created_at: String
    let sortable_name: String
    let short_name: String
    let avatar_url: String
}

struct MembersView: View {
    @State private var selectedImage: IdentifiableImage? = nil
    
//    var token: String = (UserDefaults(suiteName: "group.com.example.CampusCommotion")!).string(forKey: "token")  ?? ""
    let keychain = KeychainSwift()
    var selectedclass: String
    var classkey: String?
    var numofstudents = 0
    var teacherusername: String
    var token: String
    var parsedSchedules: [ClassInfo] = []
    let coursedata = try? JSONDecoder().decode([String: CourseData].self, from: (UserDefaults(suiteName: "group.com.example.CampusCommotion")?.data(forKey: "canvascourses")!)!)
    @State private var fetchedSchedules: [ClassInfo] = [] // New state variable for fetched data
    @State private var matchingSchedules: [ClassInfo] = [] // New state variable for fetched data
    
    
    init(selectedclass: String, teacherusername: String, classkey: String?) {
        self.selectedclass = selectedclass
        self.teacherusername = teacherusername
        self.classkey = classkey
        keychain.accessGroup = "group.com.example.CampusCommotion"
        token = keychain.get("token") ?? ""
        
        // Perform data loading and parsing in the initializer
        loadData()
    }
    
    struct ClassInfo: Identifiable, Hashable {
        var id: String { imglink } // Assuming studentID is unique
        var studentName: String
        var imglink: String
        var studentID: Int
        
    }
    
    private func fetchData() {
        self.fetchedSchedules = []
        matchingSchedules = []
        guard let sectionID = coursedata![classkey!]?.sectionid else {
                print("Course ID not found.")
                return
            }

            // Replace the following URL with your actual API endpoint
            let apiURLString = "https://canvas.example.edu/api/v1/sections/\(sectionID)/enrollments?access_token=\(token)&include=avatar_url&per_page=100&type=StudentEnrollment"
            
            guard let apiURL = URL(string: apiURLString) else {
                print("Invalid API URL.")
                return
            }

            URLSession.shared.dataTask(with: apiURL) { data, response, error in
                guard let data = data, error == nil else {
                    print("Error fetching data: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                do {
                            let users = try JSONDecoder().decode([User].self, from: data)
                    print(users)
                                self.fetchedSchedules = users.map { user in
                                    ClassInfo(studentName: user.user.name, imglink: user.user.avatar_url, studentID: user.user.id)
                            }

                    print(fetchedSchedules)
                        } catch let error {
                            print("Error decoding JSON: \(error)")
                        }
            }.resume()
        for parsedSchedule in parsedSchedules {
            if let matchingFetchedSchedule = fetchedSchedules.first(where: { fetchedSchedule in
                fetchedSchedule.studentID == parsedSchedule.studentID
            }) {
                matchingSchedules.append(ClassInfo(studentName: parsedSchedule.studentName, imglink: matchingFetchedSchedule.imglink, studentID: parsedSchedule.studentID))
            } else {
                // If no match, use imglink directly from parsedSchedule
                matchingSchedules.append(ClassInfo(studentName: parsedSchedule.studentName, imglink: parsedSchedule.imglink, studentID: parsedSchedule.studentID))
            }
        }
        }
    
    private mutating func loadData() {
        parsedSchedules = []
        let classIDtag = selectedclass.split(separator: " ").first
        //let classID = (classIDtag?.split(separator: "-").map(String.init).prefix(2).joined(separator: "*")) ?? ""
        
        let studentsfullArray = coursedata![classkey!]?.students ?? []
                for student in studentsfullArray {
                    print(student)
                    numofstudents += 1
                    self.parsedSchedules.append(ClassInfo(studentName: student.studentname, imglink: student.image, studentID: student.studentID))
                }
        //print(parsedSchedules)
    }
    var body: some View {
        List {
            ForEach(matchingSchedules, id: \.studentID) { classInfo in
                HStack(spacing: 8) {
                    if #available(iOS 15, *) {
                        AsyncImage(url: URL(string: classInfo.imglink)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                                    .padding(.leading, 16)
                                    .onTapGesture {
                                        // Assuming IdentifiableImage is defined somewhere
                                        selectedImage = IdentifiableImage(image: image)
                                    }

                            case .failure(_):
                                // Handle failure, e.g., show a placeholder image or an error message
                                Text("Failed to load image")
                            case .empty:
                                // Show a spinning loading indicator
                                ProgressView()
                                    .frame(width: 50, height: 50)
                            @unknown default:
                                // Handle unknown cases
                                fatalError("Unhandled AsyncImage phase")
                            }
                        }
                    } else
                        {
                        URLImage(url: URL(string: classInfo.imglink)!) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                                .padding(.leading, 16)
                                .onTapGesture {
                                    selectedImage = IdentifiableImage(image: image)
                                
                        }
                    }
                    }
                    VStack(alignment: .leading) {
                        
                        Text("\(classInfo.studentName)")
                            .font(.headline)
                        Image(systemName: "person.fill")
                                .foregroundColor(.blue)
                        //Text("Student ID: \(classInfo.studentID)")
                        //   .font(.subheadline)
                        //  .foregroundColor(.gray)
                        //Spacer()
                    }
                }.fullScreenCover(item: $selectedImage) { item in
                    item.image
                        .resizable()
                        .scaledToFit()
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            // Dismiss the full-screen view when tapped
                            selectedImage = nil
                        }
                }
            }
        }
        .onAppear {
            fetchData()
        }
        .listStyle(GroupedListStyle())
        .foregroundColor(.white)
        Text("Number of Students: \(String(numofstudents) ?? "")")
            .frame(alignment: .center)
    }
}
