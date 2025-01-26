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
    
    init(text: Binding<String>, whichDate: Binding<String>) {
        _request_data = text
        _which_date = whichDate
        block_list = []
        let parsed_data = JSON.init(parseJSON:request_data)
        //print(request_data)
        if !parsed_data["success"].exists() {
            //something is wrong with the data payload, display it
            let blockid = ""
            let blockidsub = ""
            let starttime = "oh"
            let endtime = "no"
            let location = "check your profile info"
            let classname = "Unable to Retrieve Data"
            let teacher = ""
            let teacherusername = ""
            let endstop = true
            let my_color = Color(red: 0.6353, green: 0.1412, blue: 0.1333)
            block_list.append(BlockView(blockid: blockid, blockidsub: blockidsub, starttime: starttime, endtime: endtime, classname: classname, teacher: teacher, teacherusername: teacherusername, location: location, use_color: my_color, endstop: endstop))
        } else if parsed_data["success"] == false{
            //something is wrong with the data payload, display it
            let blockid = ""
            let blockidsub = ""
            let starttime = "oh"
            let endtime = "no"
            let location = parsed_data["all_days_blocks"].rawValue as! String
            let classname = "Server Error"
            let teacher = ""
            let teacherusername = ""
            let endstop = true
            let my_color = Color(red: 0.6353, green: 0.1412, blue: 0.1333)
            block_list.append(BlockView(blockid: blockid, blockidsub: blockidsub, starttime: starttime, endtime: endtime, classname: classname, teacher: teacher, teacherusername: teacherusername, location: location, use_color: my_color, endstop: endstop))
        } else {
            for (key, allDaysJson) in parsed_data["all_weeks_blocks"][Information.indexnumber] {
                    //debugPrint(key)
                    //debugPrint(which_date)
                    if key.contains(which_date){
                        for (key, subJson) in allDaysJson {
                            //debugPrint(which_date)
                            //debugPrint(subJson["classname"].rawValue as? String)
                            var blockid = subJson["blockid"].rawValue as? String
                            var blockidsub = ""
                            let starttime = subJson["starttime"].rawValue as? String
                            let endtime = subJson["endtime"].rawValue as? String
                            let location = subJson["location"].rawValue as? String
                            let classname = subJson["classname"].rawValue as? String
                            let teacher = subJson["teacher"].rawValue as? String
                            let teacherusername = subJson["teacherusername"].rawValue as? String
                            var endstop = true
                            //var my_color = Color(red: 0.6353, green: 0.1412, blue: 0.1333)
                            var my_color = Color(hexStringToUIColor(hex:subJson["color"].rawValue as? String ?? "ffffff"))
                            
                            if classname == "" && blockid != "" {
                                my_color = Color(red: 143/255, green: 145/255, blue: 162/255)
                            } else if classname != "" && (blockid == "" || blockid == " "){
                                my_color = Color(red: 244/255, green: 185/255, blue: 96/255)
                            }
                            
                            //if blockid?.components(separatedBy: " ").count ?? 0 > 1 {
                            //    blockidsub = blockid?.components(separatedBy: " ")[1] ?? ""
                            //    blockid = blockid?.components(separatedBy: " ")[0]
                            //}
                            
                            if Int(key) != parsed_data["todays_blocks"].count-1 {
                                endstop = true
                            }
                            block_list.append(BlockView(blockid: blockid ?? "", blockidsub: blockidsub, starttime: starttime ?? "", endtime: endtime ?? "", classname: classname ?? "", teacher: teacher ?? "", teacherusername: teacherusername ?? "", location: location ?? "", use_color: my_color, endstop: endstop))
                        }
                }
            }
        }
        
        if block_list.count == 0 {
            //then it's no school!
            let blockid = ""
            let blockidsub = ""
            let starttime = "☺"
            let endtime = ""
            let location = "have fun"
            let classname = "No School"
            let teacher = ""
            let teacherusername = ""
            let endstop = true
            let my_color = Color(red: 156/255, green: 227/255, blue: 125/255)
            block_list.append(BlockView(blockid: blockid, blockidsub: blockidsub, starttime: starttime, endtime: endtime, classname: classname, teacher: teacher, teacherusername: teacherusername, location: location, use_color: my_color, endstop: endstop))
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

