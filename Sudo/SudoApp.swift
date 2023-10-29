//
//  SudoApp.swift
//  Sudo
//
//  Created by Mansidak Singh on 9/20/23.

import SwiftUI
import AppKit
import Alamofire
import AudioToolbox
import AVKit
import AVFoundation
import Sparkle

class AppSettings: ObservableObject {
    @Published var sendText = true {
        didSet {
            if !sendText {
                playSound = true
            }
        }
    }
    @Published var playSound = true {
        didSet {
            if !playSound {
                sendText = true
            }
        }
    }
}


struct windowSize {
// changes let to static - read comments
    static var minWidth : CGFloat = 600
    static var minHeight : CGFloat = 380
    static var maxWidth : CGFloat = 600
    static var maxHeight : CGFloat = 380
}


class TimerManager: ObservableObject {
    @Published var isActive: Bool = false
    var timer: DispatchSourceTimer?
    var lockObserver: NSObjectProtocol!
    var unlockObserver: NSObjectProtocol!
    var settings: AppSettings
    var player: AVAudioPlayer!

    private func runShell(_ command: String) {
           let process = Process()
           process.launchPath = "/bin/bash"
           process.arguments = ["-c", command]
           process.launch()
       }
    
    init(settings: AppSettings) {
        self.settings = settings
        self.lockObserver = self.createLockObserver()
        self.unlockObserver = self.createUnlockObserver()
    }

    func createLockObserver() -> NSObjectProtocol {
        let dnc = DistributedNotificationCenter.default()
        return dnc.addObserver(forName: .init("com.apple.screenIsLocked"), object: nil, queue: .main) { [weak self] _ in
            print("BITCHHHHHHHHH MAC LOCKED")

        }
    }

    func createUnlockObserver() -> NSObjectProtocol {
        let dnc = DistributedNotificationCenter.default()

        return dnc.addObserver(forName: .init("com.apple.screenIsUnlocked"), object: nil, queue: .main) { [weak self] _ in
            print("BITCHHHHHHHHH MAC UNLOCKED")

            self?.stopLidCheck()
            self?.stopTheSound()
        }
    }

    func lidClosed() -> Bool {
        let process = Process()
        process.launchPath = "/bin/bash"
        process.arguments = ["-c", "ioreg -r -k AppleClamshellState -d 4 | grep AppleClamshellState  | head -1"]
        let pipe = Pipe()
        process.standardOutput = pipe
        let fileHandle = pipe.fileHandleForReading
        process.launch()
        return String(data: fileHandle.readDataToEndOfFile(), encoding: .utf8)?.contains("Yes") ?? false
    }
//
//    func lidClosed() -> Bool {
//        let process = Process()
//        process.launchPath = "/bin/bash"
//        process.arguments = ["-c", "ioreg -r -k AppleClamshellState -d 4 | grep AppleClamshellState  | head -1"]
//        
//        let pipe = Pipe()
//        process.standardOutput = pipe
//        let fileHandle = pipe.fileHandleForReading
//        
//        process.launch()
//        
//        let output = String(data: fileHandle.readDataToEndOfFile(), encoding: .utf8) ?? ""
//        
//        // Check if "Yes" is present in the output
//        return output.contains("\"Yes\"")
//    }

    
     func sendTwilioMessage() {
         let phoneNumber = UserDefaults.standard.string(forKey: "phoneNumber") ?? ""
         let accountSID = "AC61dad5ff185fbb39744f1366adaf31e4"
         let authToken = "40590797620b6bbba291de167af0d116"
         let url = "https://api.twilio.com/2010-04-01/Accounts/AC61dad5ff185fbb39744f1366adaf31e4/Messages"
         let parameters = ["From": "+18777030857", "To": phoneNumber, "Body": "Your Mac is in Danger"]

         AF.request(url, method: .post, parameters: parameters)
             .authenticate(username: accountSID, password: authToken)
             .responseJSON { response in
                 debugPrint(response)
             }
     }
    
    
    func sendTwilioCall() {
        let phoneNumber = UserDefaults.standard.string(forKey: "phoneNumber") ?? ""
          let accountSID = "AC61dad5ff185fbb39744f1366adaf31e4"
          let authToken = "40590797620b6bbba291de167af0d116"
          let url = "https://api.twilio.com/2010-04-01/Accounts/\(accountSID)/Calls"
          let parameters = ["From": "+18777030857", "To": phoneNumber, "Url": "http://demo.twilio.com/docs/voice.xml"] //use your TwiML URL here

          AF.request(url, method: .post, parameters: parameters)
              .authenticate(username: accountSID, password: authToken)
              .responseJSON { response in
                  debugPrint(response)
              }
      }
    
    func playTheSound() {
        
        let url = Bundle.main.url(forResource: "Final4", withExtension: "mp3")
        
        player = try! AVAudioPlayer(contentsOf: url!)
        NSSound.systemVolume += 0.99
        player.numberOfLoops = -1    // Loops indefinitely
        player?.play()
        
        print("Sound was played")

    }
    
    func stopTheSound() {
        if player != nil {
            player.stop()
            print("Sound was stopped")
        }
    }
   
    func startLidCheck() {
        // Ensure any existing timer is cancelled first
        if timer != nil {
            timer?.cancel()
            timer = nil
        }

        runShell("sudo pmset -b disablesleep 1")

        timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
        timer?.schedule(deadline: .now(), repeating: .milliseconds(500))
        timer?.setEventHandler {
            if self.lidClosed() {
                DispatchQueue.main.async {
                    if self.settings.sendText {  // If the sendText toggle is ON
                        self.sendTwilioCall()
                    }
                    if self.settings.playSound { // If the playSound toggle is ON
                        self.playTheSound()
                        // Your function to play the alarm goes here.
                    }
                    self.timer?.cancel()
                    self.timer = nil
                }
            }
        }
        timer?.resume()
    }
    
      func stopLidCheck() {
          timer?.cancel()
          timer = nil
          print("ALL TIMERS STOPPED BRO")
          // Enables sleep after stopping check
          runShell("sudo pmset -b disablesleep 0")
      }



    func lockScreen() {
        let libHandle = dlopen("/System/Library/PrivateFrameworks/login.framework/Versions/Current/login", RTLD_LAZY)
        let sym = dlsym(libHandle, "SACLockScreenImmediate")
        typealias myFunction = @convention(c) () -> Void

        let SACLockScreenImmediate = unsafeBitCast(sym, to: myFunction.self)
        SACLockScreenImmediate()
    }
}


@main
struct SudoApp: App {
    private let updaterController: SPUStandardUpdaterController


    @StateObject var settings = AppSettings()
    var preferencesWindow: NSWindow?
    @StateObject var timerManager: TimerManager


    init() {
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        let settingsObject = AppSettings()
        let timerManagerObject = TimerManager(settings: settingsObject)

        _settings = StateObject(wrappedValue: settingsObject)
        _timerManager = StateObject(wrappedValue: timerManagerObject)
    }
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
//    @State var isShowingOnboarding: Bool = UserDefaults.standard.string(forKey: "phoneNumber") == nil
    @AppStorage("phoneNumber") var phoneNumber: String? {
        didSet {
            isShowingOnboarding = phoneNumber == nil
        }
    }
    
    @State var isShowingOnboarding: Bool = (UserDefaults.standard.string(forKey: "phoneNumber") == nil) || !checkSudoersDuringOnboarding() {
        didSet {
            isShowingOnboarding = (phoneNumber == nil) || !checkSudoersDuringOnboarding()
        }
    }
    mutating func openPreferencesWindow() {
           if preferencesWindow == nil {
               let preferencesView = PreferencesView()
               // Create the preferences window and set content
               preferencesWindow = NSWindow(
                   contentRect: NSRect(x: 20, y: 20, width: 480, height: 300),
                   styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                   backing: .buffered,
                   defer: false)
               preferencesWindow?.center()
               preferencesWindow?.setFrameAutosaveName("Preferences")
               preferencesWindow?.isReleasedWhenClosed = false
               preferencesWindow?.contentView = NSHostingView(rootView: preferencesView)
           }
           preferencesWindow?.makeKeyAndOrderFront(nil)
       }
    
    
    
 
   
    func sendTwilioMessage(_ phoneNumber: String) {
        let accountSID = "AC61dad5ff185fbb39744f1366adaf31e4"
        let authToken = "40590797620b6bbba291de167af0d116"
        let url = "https://api.twilio.com/2010-04-01/Accounts/AC61dad5ff185fbb39744f1366adaf31e4/Messages"
        let parameters = ["From": "+18777030857", "To": phoneNumber, "Body": "Your Mac is in Danger"]
        AF.request(url, method: .post, parameters: parameters)
            .authenticate(username: accountSID, password: authToken)
            .responseJSON { response in
                debugPrint(response)
            }
    }
    
    
    var body: some Scene {
        WindowGroup {
                    if isShowingOnboarding {
                        OnboardingParentView(isShowingOnboarding: $isShowingOnboarding)
                            .frame(minWidth: windowSize.minWidth, minHeight: windowSize.minHeight)
                            .frame(maxWidth: windowSize.maxWidth, maxHeight: windowSize.maxHeight)
                    }     
        }.commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController.updater)
            }
        }
        
        .windowResizability(.contentSize)
            MenuBarExtra("Clyde") {
                
//                Button(action:{
//                    self.timerManager.playTheSound()
//
//                }){Text("Playsound")}
//                
//                
//            
//                Button(action:{
//                    print(timerManager.lidClosed())
//
//                }){Text("Print Lid Closed")}
//                
//                
//                Button(action:{
//                    UserDefaults.standard.removeObject(forKey: "phoneNumber")
//
//                }){Text("Delete User Defaults")}
//                
//                Button(action:{
//                    
//                    let accountSID = "AC61dad5ff185fbb39744f1366adaf31e4"
//                    let authToken = "40590797620b6bbba291de167af0d116"
//
//                    let url = "https://api.twilio.com/2010-04-01/Accounts/\(accountSID)/Messages"
//
//                    let parameters = [
//                        "Body": "Here is the Contact Card :)",
//                        "From": "+18777030857",
//                        "To": phoneNumber,
//                    ]
//                    
//                        AF.request(url, method: .post, parameters: parameters)
//                            .authenticate(username: accountSID, password: authToken)
//                            .responseJSON { response in
//                                debugPrint(response)
//                            }
//                }){Text("Send Random Text")}

                Button(action: {
                    if self.timerManager.timer == nil {
                        self.timerManager.lockScreen()    // Locks the screen
                        self.timerManager.startLidCheck() // Starts checking if the lid is closed
                    } else {
                        self.timerManager.stopLidCheck()  // Stops checking if the lid is closed
                        self.timerManager.timer = nil
                    }
                }){
                    HStack {
                        Image(systemName: "alarm")
                        Text("Toggle Clyde")
                        Spacer()
                    }
                }

                
                
                Divider()
                Text("Leave the lid open after toggle").disabled(true)

                

           
                Menu("Settings"){
                    Toggle(isOn: $settings.sendText) {
                        Text("Notify me via call")
                    }
                    .toggleStyle(CheckboxToggleStyle())
                    .frame(alignment: .leading)
                    .padding(.leading, -120)
                    .disabled(!settings.playSound)
                    Toggle(isOn: $settings.playSound) {
                        Text("Notify me via Alarm")
                    }
                    .toggleStyle(CheckboxToggleStyle())
                    .frame(alignment: .leading)
                    .padding(.leading, -120)
                    .disabled(!settings.sendText)
                    
                    Button(action: {
                        
                        UserDefaults.standard.removeObject(forKey: "phoneNumber")
                        appDelegate.openPreferencesWindow()
                    }) {
                        Text("Change Phone Number").foregroundColor(.primary)
                    }
                    
                    Button(action: {
                        NSApplication.shared.terminate(nil)})
                    {Text("Quit")}
                    
                }
                   
                
//                Button(action:{
//                        print(UserDefaults.standard.dictionaryRepresentation())
//
//                    }){Text("Print User Defaults")}
//                    
//                
                
            }
        
        }
       
    
    static func show(ignoringOtherApps: Bool = true) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: ignoringOtherApps)
    }
    
    static func hide() {
        NSApp.hide(self)
        NSApp.setActivationPolicy(.accessory)
    }
   
}
    




extension NSApplication {
    
    static func show(ignoringOtherApps: Bool = true) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: ignoringOtherApps)
    }
    
    static func hide() {
        NSApp.hide(self)
        NSApp.setActivationPolicy(.accessory)
    }
}


