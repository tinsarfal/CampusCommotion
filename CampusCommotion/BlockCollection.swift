//
//  BlockCollection.swift
//  CampusCommotion

import SwiftUI
import SwiftyJSON

func hexStringToUIColor (hex:String) -> UIColor {
    var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

    if (cString.hasPrefix("#")) {
        cString.remove(at: cString.startIndex)
    }

    if ((cString.count) != 6) {
        return UIColor.gray
    }

    var rgbValue:UInt64 = 0
    Scanner(string: cString).scanHexInt64(&rgbValue)

    return UIColor(
        red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
        green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
        blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
        alpha: CGFloat(1.0)
    )
}

let indexnumber = Information.indexnumber

struct BlockCollection: View {
        
    @Binding var request_data: String
    @Binding var which_date: String
    private var block_list: [BlockView] = []
    
    private func makeBlock(
        blockid: String = "",
        blockidsub: String = "",
        starttime: String = "",
        pmstart: Bool = false,
        endtime: String = "",
        pmend: Bool = false,
        location: String = "",
        classname: String = "",
        teacher: String = "",
        teacherusername: String = "",
        color: String = "ffffff",
        endstop: Bool = true
    ) -> BlockView {
        var my_color = Color(hexStringToUIColor(hex: color))
        if classname == "" && blockid != "" {
            my_color = Color(red: 143/255, green: 145/255, blue: 162/255)
        } else if classname != "" && (blockid == "" || blockid == " "){
            my_color = Color(red: 244/255, green: 185/255, blue: 96/255)
        }
        return BlockView(
            blockid: blockid,
            blockidsub: blockidsub,
            starttime: starttime,
            pmstart: pmstart,
            endtime: endtime,
            pmend: pmend,
            classname: classname,
            teacher: teacher,
            teacherusername: teacherusername,
            location: location,
            use_color: my_color,
            endstop: endstop
        )
    }
    
    init(text: Binding<String>, whichDate: Binding<String>) {
        _request_data = text
        _which_date = whichDate
        block_list = []
        let parsedData = JSON(parseJSON: request_data)
        if !parsedData["success"].exists() {
            block_list.append(makeBlock(
                starttime: "oh",
                endtime: "no",
                location: "check your profile info",
                classname: "Unable to Retrieve Data",
                color: "a22222"
            ))
        } else if parsedData["success"] == false {
            let location = parsedData["all_days_blocks"].stringValue
            block_list.append(makeBlock(
                starttime: "oh",
                endtime: "no",
                location: location,
                classname: "Server Error",
                color: "a22222"
            ))
        } else {
            for (key, allDaysJson) in parsedData["all_weeks_blocks"][Information.indexnumber] {
                if key.contains(which_date) {
                    for (_, subJson) in allDaysJson {
                        block_list.append(makeBlock(
                            blockid: subJson["blockid"].stringValue,
                            starttime: subJson["starttime"].stringValue,
                            pmstart: subJson["pmstart"].boolValue,
                            endtime: subJson["endtime"].stringValue,
                            pmend: subJson["pmend"].boolValue,
                            location: subJson["location"].stringValue,
                            classname: subJson["classname"].stringValue,
                            teacher: subJson["teacher"].stringValue,
                            teacherusername: subJson["teacherusername"].stringValue,
                            color: subJson["color"].stringValue
                        ))
                    }
                }
            }
        }
        
        if block_list.count == 0 {
            block_list.append(makeBlock(
                starttime: "☺",
                location: "have fun",
                classname: "No School",
                color: "9ce37d"
            ))
        }
    }
    

    var body: some View {
        Spacer(minLength: 20)
        Divider()
    
        ForEach(block_list, id: \.id) { block in
            block
        }
        
    }
    
}

struct BlockCollection_Previews: PreviewProvider {
    
    @State var request_data: String = UserDefaults.standard.string(forKey: "request_data")  ?? ""
    @State var test_date: String = "1/7"

    static var previews: some View {
        BlockCollection(text: .constant(UserDefaults.standard.string(forKey: "request_data")  ?? ""), whichDate: .constant("12/7"))
    }
}

