import SwiftUI
import Foundation
import Alamofire
import SystemConfiguration


public class Reachability {
    class func isConnectedToNetwork() -> Bool {
        var zeroAddress: sockaddr_in = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
            return false
        }
        
        let isReachable = flags == .reachable
        let needsConnection = flags == .connectionRequired
        
        return isReachable && !needsConnection
    }
}

class OnboardingViewModel: ObservableObject {
    @Published var onboardingStage: Int
    @Published var hasInternetConnection: Bool = true
    @Published var phoneNumber: String?

    init(onboardingStage: Int = 1) {
        self.onboardingStage = onboardingStage
    }
}

struct OnboardingParentView: View {
    @StateObject private var viewModel: OnboardingViewModel
    @Binding var isShowingOnboarding: Bool

    init(isShowingOnboarding: Binding<Bool>, startAtStage: Int = 1) {
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(onboardingStage: startAtStage))
        _isShowingOnboarding = isShowingOnboarding
    }

    var body: some View {
        VStack {
            if isShowingOnboarding {
                if viewModel.onboardingStage == 1 {
                    OnboardingView1(viewModel: viewModel)
                } else if viewModel.onboardingStage == 2 {
                    OnboardingView2(viewModel: viewModel)
                } else if viewModel.onboardingStage == 3 {
                    OnboardingView3(viewModel: viewModel)
                } else if viewModel.onboardingStage == 4 {
                    OnboardingView4(viewModel: viewModel, isShowingOnboarding: $isShowingOnboarding)
                }
            } else {
                Text("Main UI")
            }
        }
    }
}

func checkSudoersDuringOnboarding() -> Bool {
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

struct OnboardingView1: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack {
            VStack{
                Text("Welcome to")
                    .multilineTextAlignment(.center)
                    .fontWeight(.light)
                    .foregroundColor(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                    .padding(.bottom, 1)
                    .font(.custom("Avenir ", size: 20))

                Text("Clyde")
                    .multilineTextAlignment(.center)
                    .fontWeight(.light)
                    .foregroundColor(Color(red: 201/255, green: 201/255, blue: 201/255))
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 10)
                    .font(.custom("Avenir ", size: 18))
            }
            .padding(.bottom, 20)

            HStack{
                Text(Image(systemName: "laptopcomputer.and.arrow.down"))
                    .foregroundColor(Color.white)
                
                VStack{
                    Text("Toggle Clyde and walk away by keeping the lid open.")
                        .fontWeight(.light)
                        .padding(.leading, 3)
                        .foregroundColor(Color.white)
                        .frame(maxWidth: .infinity)
                        .font(.custom("Avenir ", size: 13))
                }
            }
            .padding(.leading, 140)
            .padding(.trailing, 120)
            .padding(.bottom, 20)
            
            HStack{
                Text(Image(systemName: "dot.radiowaves.left.and.right"))
                    .foregroundColor(Color.white)
                
                VStack{
                    Text("An alarm will ring if someone closes the lid of your Mac.")
                        .multilineTextAlignment(.leading)
                        .padding(.leading, 2)
                        .fontWeight(.light)
                        .foregroundColor(Color.white)
                        .frame(maxWidth: .infinity)
                        .font(.custom("Avenir ", size: 13))
                }
            }
            .padding(.leading, 140)
            .padding(.trailing, 100)
            .padding(.bottom, 20)
            
            HStack{
                Text(Image(systemName: "iphone.radiowaves.left.and.right"))
                    .foregroundColor(Color.white)
                
                VStack{
                    Text("You will also get a text notification if someone closes the lid.")
                        .fontWeight(.light)
                        .foregroundColor(Color.white)
                        .frame(maxWidth: .infinity)
                        .font(.custom("Avenir ", size: 13))
                }
            }
            .padding(.leading, 138)
            .padding(.trailing, 80)
            .padding(.bottom, 20)
            
             
             HStack{
                 Text(Image(systemName: "touchid"))
                     .foregroundColor(Color.white)
                 
                 VStack{
                     Text("Clyde will deactivate itself when you sign in.")
                         .padding(.leading, 5)
                         .fontWeight(.light)
                         .foregroundColor(Color.white)
                         .font(.custom("Avenir ", size: 13))
                 }
                 Spacer()
             }
             .padding(.leading, 142)
             .padding(.trailing, 144)
            
            Button("Got it. Finish Setup") {
                if Reachability.isConnectedToNetwork() {
                    
                    if !checkSudoersDuringOnboarding() {
                        viewModel.onboardingStage = 2
                    }
                    
                    else{
                        viewModel.onboardingStage = 3
                    }
                    
                    viewModel.hasInternetConnection = true
                } else {
                    print("No internet connection.")
                    viewModel.hasInternetConnection = false
                }
            }
            .buttonStyle(CustomButton())
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.leading, -14)

            if !viewModel.hasInternetConnection {
                         Text("You need internet connection to finish setup Clyde. Try re-opening the app.")
                             .foregroundColor(.red)
                             .frame(maxWidth: .infinity)
                             .padding()
                     }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
             .background(
                 Image("Frame1")
                     .resizable()
                     .scaledToFill()
             )
             .edgesIgnoringSafeArea(.all)
    }
}

struct OnboardingView2: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var isCheckboxChecked: Bool = true
    @State private var isInstalled = false

    var body: some View {
        VStack {
            VStack {
                Text("Please allow installation")
                    .fontWeight(.light)
                    .foregroundColor(Color(red: 201/255, green: 201/255, blue: 201/255))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 30)
                    .padding(.bottom, 10)
                    .font(.custom("Avenir ", size: 20))
                
                Text("This is necessary to let Clyde sound an alarm and send you a notification in case of theft")
                    .fontWeight(.light)
                    .foregroundColor( Color(red: 119/255, green: 119/255, blue: 119/255))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 30)
                    .padding(.trailing, 230)
                    .font(.custom("Avenir light", size: 15))
                
                if !isInstalled {
                    Button("Install") {
                        let username = NSUserName()
                        let appleScriptCommand = """
                                do shell script "echo '\(username) ALL=(ALL) NOPASSWD: /usr/bin/pmset' | sudo EDITOR='tee -a' visudo" with administrator privileges
                            """
                                                 
                        if let appleScript = NSAppleScript(source: appleScriptCommand) {
                            var error: NSDictionary? = nil
                            appleScript.executeAndReturnError(&error)
                            
                            if error == nil {
                                self.isInstalled = true
                            }
                        }
                        viewModel.onboardingStage = 2
                    }
                    .buttonStyle(CustomButton())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, -40)
                }
                else {
                    Button("Finish Setup") {
                        viewModel.onboardingStage = 3
                    }
                    .buttonStyle(CustomButton())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, -40)
                }
            }
        }
        .background(
            Image("Frame3")
                .resizable()
                .scaledToFill()
        )
    }
}




struct OnboardingView3: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var phoneNumber = ""
    @State private var selectedCountryIndex = 0
    let sortedCountries = countries.sorted { $0.0 < $1.0 }

  
    
    var body: some View {
        VStack(alignment: .leading)  {
            (Text(Image(systemName: "checkmark.shield")) + Text(" Clyde"))
                .fontWeight(.light)
                .foregroundColor(Color.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 30)
                .padding(.bottom, 60)
                .font(.custom("Avenir Bold", size: 14))
            
            Text("Set up Text Notifications")
                .fontWeight(.light)
                .foregroundColor(Color(red: 201/255, green: 201/255, blue: 201/255))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 30)
                .padding(.bottom, 10)
                .font(.custom("Avenir ", size: 20))
            
            Text("This is stored locally and is never shared with anyone. Please choose country code (For ex: +1 XXX XXX XXXX)")
                .fontWeight(.light)
                .foregroundColor( Color(red: 119/255, green: 119/255, blue: 119/255))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 30)
                .padding(.trailing, 200)
                .font(.custom("Avenir light", size: 15))

            HStack {

                Picker(selection: $selectedCountryIndex, label: Text("Select Country").bold().foregroundColor(.white)) {
                    ForEach(0..<sortedCountries.count, id: \.self) { index in
                        Text("\(sortedCountries[index].0) \(sortedCountries[index].1)")
                    }
                }
                
                
                .pickerStyle(.menu)
                .padding(10)
                .cornerRadius(0)
                .accentColor(.white)
                .labelsHidden()
                .frame(width: 150, height: 40)
                .padding(.leading, 20)
                .environment(\.colorScheme, .dark)

                CustomTextField(text: $phoneNumber)
                    .frame(width: 200, height: 20)
                    .padding(.trailing, 30)
            }

            VStack{
                Button("FINISH SETUP") {
                    if phoneNumber.count > 0 {
                        let selectedCountryCode = sortedCountries[selectedCountryIndex].0
                        let combinedPhoneNumber = selectedCountryCode + phoneNumber
                        viewModel.phoneNumber = combinedPhoneNumber // Change this line
                        let accountSID = "AC61dad5ff185fbb39744f1366adaf31e4"
                        let authToken = "40590797620b6bbba291de167af0d116"
                        
                        let url = "https://api.twilio.com/2010-04-01/Accounts/\(accountSID)/Messages"
                        
                        let parameters = [
                            "Body": """
                            Hello there! 👋
                                           
                            This is how you will be notified in case someone tries to steal your laptop.
                               
                            Something important before we set you up: In order to make sure we can notify you, please make sure that Emergency bypass is enabled. To do that, take the following steps:
                               
                            1. Click the contact card
                            2. Hit create new contact
                            3. Scroll to Ringtone
                            4. Enable Emergency Bypass
                            5. Hit Done
                            6. Do the same with Text tone
                               
                            This makes sure that you get notified of potential theft in case you have Do Not Disturb enabled.
                            
                            """,
                            "MediaUrl":"https://www.getcly.de/s/Clyde.vcf",
                            "From": "+18777030857",
                            "To": combinedPhoneNumber
                        ]
                        

                        AF.request(url, method: .post, parameters: parameters)
                            .authenticate(username: accountSID, password: authToken)
                            .responseJSON { response in
                                debugPrint(response)
                            }
                        viewModel.onboardingStage = 4
                    }
                }.buttonStyle(CustomButton())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, -14)
                
                
            
                
                Text(" < Back")
                    .onTapGesture {
                        viewModel.onboardingStage = 1
                    }
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 30)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Image("Frame1")
                .resizable()
                .scaledToFill()
        )
        .edgesIgnoringSafeArea(.all)
    }
}


struct OnboardingView4: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @Binding var isShowingOnboarding: Bool
    @State private var isCheckboxChecked: Bool = false

    var body: some View {
        VStack {
            VStack{
                
                Text("One last thing.")
                    .multilineTextAlignment(.center)
                    .fontWeight(.light)
                    .foregroundColor(Color(red: 201/255, green: 201/255, blue: 201/255))
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 10)
                    .font(.custom("Avenir ", size: 18))
                
                Text("We just sent a text with some instructions on the last step.")
                    .multilineTextAlignment(.center)
                    .fontWeight(.light)
                    .foregroundColor(Color.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 10)
                    .font(.custom("Avenir ", size: 15))
                 
                Toggle(isOn: $isCheckboxChecked) {
                    Text("Yes, I received the text and made the necessary changes.")
                        .font(.custom("Avenir ", size: 12))
                        .foregroundColor(Color.gray)
                        .multilineTextAlignment(.leading)
                }
                .padding()
            }
            
            Button("Continue to App") {
                if let phoneNumber = viewModel.phoneNumber {
                    UserDefaults.standard.set(phoneNumber, forKey: "phoneNumber")
                    NSApplication.shared.keyWindow?.close()
                    viewModel.onboardingStage = 1 // Reset onboarding stage

                }
            }
            .buttonStyle(CustomButton())
            .disabled(!isCheckboxChecked)
            .frame(maxWidth: .infinity, alignment: .center)
            .opacity(isCheckboxChecked ? 1.0 : 0.5)
        }
        .background(
            Image("Frame2")
                .resizable()
                .scaledToFill()
        )
    }
}



struct CustomTextField: NSViewRepresentable {
    @Binding var text: String
    

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField(frame: .zero)
        textField.cell = CustomBorderTextFieldCell()
        textField.stringValue = text
        textField.isEditable = true
        textField.isBezeled = false
        textField.backgroundColor = .clear
        textField.delegate = context.coordinator
        textField.textColor = NSColor.white
        textField.focusRingType = .none
        textField.font = NSFont(name: "Avenir", size: 15)
        textField.placeholderString = "XXX XXX XXXX"
        let attrString = NSAttributedString(string: "XXX XXX XXXX", attributes: [NSAttributedString.Key.font : NSFont(name: "Avenir", size: 15)!, NSAttributedString.Key.foregroundColor: NSColor.gray])
               textField.placeholderAttributedString = attrString
        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        nsView.stringValue = text
    }
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: CustomTextField
        
        init(parent: CustomTextField) {
            self.parent = parent
        }
        
        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                self.parent.text = textField.stringValue
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
}

class CustomBorderTextFieldCell: NSTextFieldCell {
    let borderThickness: CGFloat = 0.5

    override var cellSize: NSSize {
        let originalSize = super.cellSize
        return NSSize(width: originalSize.width, height: originalSize.height + borderThickness)
    }

    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        let interiorFrame = NSRect(x: 0, y: 0, width: cellFrame.width, height: cellFrame.height - borderThickness)

        let path = NSBezierPath()
        path.lineWidth = borderThickness
        path.move(to: NSPoint(x: 0, y: cellFrame.height - (borderThickness / 2)))
        path.line(to: NSPoint(x: cellFrame.width, y: cellFrame.height - (borderThickness / 2)))
        NSColor.white.setStroke()
        path.stroke()

        drawInterior(withFrame: interiorFrame, in: controlView)
    }
    
    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
            super.drawInterior(withFrame: cellFrame, in: controlView)
            
            if self.stringValue.isEmpty, let placeholderString = self.placeholderString {
                let placeholderAttributes: [NSAttributedString.Key: Any] = [
                    .foregroundColor: NSColor.gray,
                    .font: NSFont(name: "Avenir", size: 18) ?? NSFont.systemFont(ofSize: 18)
                ]
                let placeholderAttributedString = NSAttributedString(string: placeholderString, attributes: placeholderAttributes)
                placeholderAttributedString.draw(in: cellFrame)
            }
        }
}


struct OnboardingView1_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView1(viewModel: OnboardingViewModel())
    }
}

struct CustomButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
            .background(configuration.isPressed ?
                                    Color(red: 120/255, green: 113/255, blue: 110/255) :
                                    Color(red: 104/255, green: 98/255, blue: 96/255)
                        )
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 30.0, style: .continuous))
            .animation(.easeOut(duration: 0.05), value: configuration.isPressed)
            .frame(width: 200, height: 80)
            .font(.custom("Avenir Bold", size: 11))
        }
    }
