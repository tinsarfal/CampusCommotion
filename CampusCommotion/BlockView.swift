//
//  BlockView.swift
//  CampusCommotion

import SwiftUI
import SwiftyJSON
import KeychainSwift

struct NavigationLazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    var body: Content {
        build()
    }
}

struct LabelledDivider: View {

    let label: String
    let horizontalPadding: CGFloat
    let color: Color

    init(label: String, horizontalPadding: CGFloat = 20, color: Color = .gray) {
        self.label = label
        self.horizontalPadding = horizontalPadding
        self.color = color
    }

    var body: some View {
        HStack {
            line
            Text(label).foregroundColor(color)
            line
        }
    }

    var line: some View {
        VStack { Divider().background(color) }.padding(horizontalPadding)
    }
}

struct BlockView: View {
    
    var blockid: String
    var blockidsub: String
    var starttime: String
    var pmstart: Bool
    var endtime: String
    var pmend: Bool
    var classname: String
    var location: String
    var use_color: Color
    var endstop: Bool
    @State private var hascanvas = false
    let id = UUID()
    var keychain = KeychainSwift()
    var coursedata = (UserDefaults(suiteName: "group.com.example.CampusCommotion")?.data(forKey: "canvascourses")).flatMap {
        try? JSONDecoder().decode([String: CourseData].self, from: $0)
    }
    func fetchCourseData() {
        let classIDtag = classname.split(separator: " ").first ?? ""
        for (_, classItem) in coursedata! {
            let classIDFromJSON = classItem.coursecode
            if classIDFromJSON.contains(classIDtag) {
                hascanvas = true
            }
        }
    }
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading) {
                if blockid != "" {
                    Text(blockid)
                        .font(.largeTitle)
                        .fontWeight(.black)
                        .foregroundColor(use_color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                Text(starttime)
                    .font(.headline)
                    .foregroundColor(use_color)
                    .lineLimit(2)
                Text(endtime)
                    .font(.headline)
                    .foregroundColor(use_color)
                    .lineLimit(2)
            }
            .padding()
            #if os(watchOS)
            .frame(maxWidth: .infinity, alignment: .leading)
            #endif
            
            #if os(watchOS)
            if use_color != Color.white,
            blockid != "CLB" {
                Text(classname.split(separator: " ").first ?? "")
                    .font(.title3)
                    .fontWeight(.regular)
                    .foregroundColor(use_color)
                    .padding()
            }
            #endif
            
            #if !os(watchOS)
            VStack(alignment: .leading) {
                Text(classname)
                    .font(.title2)
                    .fontWeight(.regular)
                    .foregroundColor(use_color)
                if location != "" {
                    Text(location.uppercased())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }.padding([.trailing, .top, .bottom, .leading])
            Spacer()
            if hascanvas && (UserDefaults(suiteName: "group.com.example.CampusCommotion")?.string(forKey: "token") ?? "") != "" {
                NavigationLink(destination: NavigationLazyView(CoursesView(selectedclass: classname, isclass: true))) {
                    Text("Info")
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
            #endif
        }
        .cornerRadius(10)
        .background(Color(red: 0.08, green: 0.08, blue: 0.08))
        .cornerRadius(6)
        .onAppear {
            keychain.accessGroup = "group.com.example.CampusCommotion"
            if (coursedata != nil) {
                fetchCourseData()
            }
        }
        if endstop {
            // Divider()
        } else {
            LabelledDivider(label: "OVERLAPS")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
