import Foundation
import SwiftUI
import AppKit

private func checkSudoers() -> Bool {
    let appleScriptCommand = "do shell script \"sudo pmset -b disablesleep 0\""
    if let appleScript = NSAppleScript(source: appleScriptCommand) {
        var error: NSDictionary? = nil
        appleScript.executeAndReturnError(&error)
       
        if let error = error {
            print("ERROR: \(error)")
            return false
        }
    }
    return true
}

class AppDelegate: NSObject, NSApplicationDelegate {
    

        var preferencesWindow: NSWindow!

        func openPreferencesWindow() {
            if nil == preferencesWindow {      // create once !!
                let preferencesView = PreferencesView()
                // Create the preferences window and set content
                preferencesWindow = NSWindow(
                    contentRect: NSRect(x: 20, y: 20, width: 480, height: 300),
                    styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                    backing: .buffered,
                    defer: false)
                preferencesWindow.center()
                preferencesWindow.setFrameAutosaveName("Preferences")
                preferencesWindow.isReleasedWhenClosed = false
                preferencesWindow.contentView = NSHostingView(rootView: preferencesView)
            }
            preferencesWindow.makeKeyAndOrderFront(nil)
        }
    
    
    
    func applicationWillTerminate(_ aNotification: Notification) {
           let task = Process()
           task.launchPath = Bundle.main.executablePath
           task.launch()
       }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        if !checkSudoers() {
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
    }
}
