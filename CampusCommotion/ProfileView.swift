//
//  ProfileView.swift
//  CampusCommotion

import SwiftUI
import SwiftyJSON
import CoreData
import KeychainSwift

class ProfileViewModel: ObservableObject {
    @Published var email: String
    @Published var calurl: String
    @Published var cluburl: String
    @Published var token: String
    
    private let keychain = KeychainSwift()
    
    init() {
        keychain.accessGroup = "group.com.example.CampusCommotion"
        self.email = keychain.get("email") ?? ""
        self.calurl = keychain.get("calurl") ?? ""
        self.cluburl = keychain.get("cluburl") ?? ""
        self.token = keychain.get("token") ?? ""
    }
    
    func saveInformation() {
        keychain.set(email, forKey: "email")
        keychain.set(calurl, forKey: "calurl")
        keychain.set(cluburl, forKey: "cluburl")
        keychain.set(token, forKey: "token")
    }
}


struct ProfileView: View {
    private let keychain: KeychainSwift = {
        let keychain = KeychainSwift()
        keychain.accessGroup = "group.com.example.CampusCommotion"
        return keychain
    }()
    @State var email: String
    @State var calurl: String
    @State var cluburl: String
    @State var token: String
    @State private var textFieldIdEmail: String = UUID().uuidString
    @State private var textFieldIdCalurl: String = UUID().uuidString
    @State private var textFieldIdCluburl: String = UUID().uuidString
    @State private var textFieldIdToken: String = UUID().uuidString

    @State var showingAlert = false
    
    var context_ContentView = ContentView()
    
    init (some_context: ContentView) {
        context_ContentView = some_context
        email = (keychain.get("email") ?? "")
        calurl = (keychain.get("calurl") ?? "")
        cluburl = (keychain.get("cluburl") ?? "")
        token = (keychain.get("token") ?? "")
    }
    
    var body: some View {
        ScrollView{
            VStack(alignment: .leading) {
                Group {
                    //Image("banner")
                    //    .resizable()
                    //    .scaledToFit()
                    
                    
                    Text("Blackbaud Calendar URL")
                        .font(.callout)
                        .bold()
                    TextField("Enter calendar URL", text: $calurl)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Text("Canvas Token")
                        .font(.callout)
                        .bold()
                    TextField("Enter Canvas Access Token", text: $token)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Text("Club Times URL")
                        .font(.callout)
                        .bold()
                    TextField("Enter club meeting times URL", text: $cluburl)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    
                    Button {
                        saveInformation()
                    } label: {
                        Text("Save Information")
                            .font(.body)
                            .fontWeight(.semibold)
                            .padding(5)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(5)
                    }
                    .alert(isPresented: $showingAlert) {
                        Alert(title: Text("Success!"), message: Text("Your login information was saved."), dismissButton: .default(Text("OK")))
                    }
                    Text("You need to enter the Blackbaud calender url for the app to work. If you leave the Canvas token blank you will simply not be able to use Canvas features such as viewing homework and class rosters. \nNot sure where to find these? \nTo get your Blackbaud calendar URL, go to the \"Calendar\" tab in Blackbaud, and click on the button with the three signal lines on the right (looks like RSS icon or Wi-Fi signal bars). Expand the Individual Calendar Feeds dropdown and copy the link for \"Schedule\". \nFor your Canvas token, go to Account, then Settings in Canvas. Then scroll down and click on \"New Access Token\" and generate one, leaving the expiration blank. The token should then be displayed on your screen for you to copy.\nFor the clubs URL follow the same instructions as for classes but instead of \"Calendar\" select \"Group Events\".")
                }
                .padding()
                
                Spacer()
                Text("Developer Name")
                    .font(.system(size: 8))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                
            }
        }
        }
    private func saveInformation() {
    
        email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        calurl = calurl.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "webcal", with: "https").replacingOccurrences(of: "http://", with: "https://")
        cluburl = cluburl.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "webcal", with: "https").replacingOccurrences(of: "http://", with: "https://")
        token = token.trimmingCharacters(in: .whitespacesAndNewlines)
    
        keychain.set(email, forKey: "email")
        keychain.set(calurl, forKey: "calurl")
        keychain.set(cluburl, forKey: "cluburl")
        keychain.set(token, forKey: "token")
        
        context_ContentView.email = self.email
        context_ContentView.calurl = self.calurl
        context_ContentView.cluburl = self.cluburl
        context_ContentView.setToLoading()

        let simpleCompletionHandler: () -> Void = {
            context_ContentView.updateScheduleView()
        }

        ConnectorClass().makeRequest(calurl: calurl, cluburl: cluburl, token: token, completionHandler: simpleCompletionHandler)
            showingAlert = true
        }
    }

