import SwiftUI
import AppKit

struct ContentView: View {
    var body: some View {
        @State var sendText = false
        @State var playSound = false

        
        VStack(alignment: .leading){
            
            Toggle(isOn: $sendText) {
                Text("Simultaneously sign out on toggle")
            }.toggleStyle(CheckboxToggleStyle())
                .frame(alignment: .leading)
                .padding(.leading, -120)
            Toggle(isOn: $playSound) {
                Text("Launch at Login")
            }.toggleStyle(CheckboxToggleStyle())
                .frame(alignment: .leading)
                .padding(.leading, -120)
               
        }
        
        
        Button("Avoid Sudo when using PMSET") {
            let username = NSUserName()
            let appleScriptCommand = """
                do shell script "echo '\(username) ALL=(ALL) NOPASSWD: /usr/bin/pmset' | sudo EDITOR='tee -a' visudo" with administrator privileges
            """

            if let appleScript = NSAppleScript(source: appleScriptCommand) {
                var error: NSDictionary? = nil
                appleScript.executeAndReturnError(&error)

                if let error = error {
                    print("ERROR: \(error)")
                }
            }
        }
        
        Button("Disable Sleep") {
            let appleScriptCommand = """
                do shell script "sudo pmset -b disablesleep 1"
                """

            if let appleScript = NSAppleScript(source: appleScriptCommand) {
                var error: NSDictionary? = nil
                appleScript.executeAndReturnError(&error)

                if let error = error {
                    print("ERROR: \(error)")
                }
            }
        }
        
        Button("Enable Sleep") {
            let appleScriptCommand = """
                do shell script "sudo pmset -b disablesleep 0"
                """

            if let appleScript = NSAppleScript(source: appleScriptCommand) {
                var error: NSDictionary? = nil
                appleScript.executeAndReturnError(&error)

                if let error = error {
                    print("ERROR: \(error)")
                }
            }
        }
    }
}
