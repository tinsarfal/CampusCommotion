//
//  Preferences.swift
//  CampusCommotion

import SwiftUI
import CoreData

struct Preferences: View {
    @State var oldMenu: Bool = (UserDefaults(suiteName: "group.com.example.CampusCommotion")?.bool(forKey: "oldMenu") ?? false)
    
    @State var id_string: String = (UserDefaults(suiteName: "group.com.example.CampusCommotion")!).string(forKey: "id_string") ?? ""
    @State var box_string: String = (UserDefaults(suiteName: "group.com.example.CampusCommotion")!).string(forKey: "box_string") ?? ""
    @State var combo_string: String = (UserDefaults(suiteName: "group.com.example.CampusCommotion")!).string(forKey: "combo_string") ?? ""

    @State private var textFieldIdId: String = UUID().uuidString
    @State private var textFieldIdCombo: String = UUID().uuidString
    @State private var textFieldIdBox: String = UUID().uuidString
    
    @State var showingAlertQA = false


    var body: some View {
        Toggle("Use Classic Dining Hall Menu", isOn: $oldMenu)
                        .padding()
                        .onChange(of: oldMenu) { newValue in
                            // Update UserDefaults when the toggle value changes
                            (UserDefaults(suiteName: "group.com.example.CampusCommotion")!).set(newValue, forKey: "oldMenu")
                            oldMenu = newValue
                            print(oldMenu)
                            print("Menutest")
                        }
        NavigationLink(destination: Acknowledgements()) {
            Text("Acknowledgements")
        }
    }
    
}

struct Preferences_Previews: PreviewProvider {
    static var previews: some View {
        Preferences()
    }
}
