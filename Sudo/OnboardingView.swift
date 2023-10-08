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
    @Published var onboardingStage: Int = 1
    @Published var hasInternetConnection: Bool = true // Added this line
}

struct OnboardingParentView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @State var isShowingOnboarding = true

    var body: some View {
        VStack {
            if isShowingOnboarding {
                if viewModel.onboardingStage == 1 {
                    OnboardingView1(viewModel: viewModel)
                }
                else if viewModel.onboardingStage == 2 {
                    OnboardingView2(viewModel: viewModel)
                }
                else if viewModel.onboardingStage == 3 {
                    OnboardingView3(viewModel: viewModel, isShowingOnboarding: $isShowingOnboarding)
                }
            } else {
                Text("Main UI")
            }
        }
    }
}

struct OnboardingView2: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var phoneNumber = ""

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
            
            
            Text("This is stored locally and is never shared with anyone. Please enter country code (For ex: +1 XXX XXX XXXX)")
                .fontWeight(.light)
                .foregroundColor( Color(red: 119/255, green: 119/255, blue: 119/255))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 30)
                .padding(.trailing, 200)
                .font(.custom("Avenir light", size: 15))


            CustomTextField(text: $phoneNumber)
                .frame(width: 200, height: 40)
                .padding(.horizontal, 30)

            Button("FINISH SETUP") {
                if phoneNumber.count > 0 {
                    
                        let accountSID = "AC61dad5ff185fbb39744f1366adaf31e4"
                        let authToken = "40590797620b6bbba291de167af0d116"

                        let url = "https://api.twilio.com/2010-04-01/Accounts/AC61dad5ff185fbb39744f1366adaf31e4/Messages"
                        let parameters = ["From": "+18777030857", "To": phoneNumber, "Body": "Welcome to Clyde! Here are a few instructions:"]

                        AF.request(url, method: .post, parameters: parameters)
                            .authenticate(username: accountSID, password: authToken)
                            .responseJSON { response in
                                debugPrint(response)
                            }
                    
                    viewModel.onboardingStage = 3
                }
            }.buttonStyle(CustomButton())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, -14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .edgesIgnoringSafeArea(.all)
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
        textField.font = NSFont(name: "Avenir", size: 18)
        textField.placeholderString = "+X XXX-XXX-XXXX" // Here is how you add placeholder

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
    // How thick should the border be
    let borderThickness: CGFloat = 0.5

    // Add extra height, to accommodate the underlined border, as the minimum required size for the NSTextField
    override var cellSize: NSSize {
        let originalSize = super.cellSize
        return NSSize(width: originalSize.width, height: originalSize.height + borderThickness)
    }

    // Render the custom border for the NSTextField
    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        let interiorFrame = NSRect(x: 0, y: 0, width: cellFrame.width, height: cellFrame.height - borderThickness)

        let path = NSBezierPath()
        path.lineWidth = borderThickness
        path.move(to: NSPoint(x: 0, y: cellFrame.height - (borderThickness / 2)))
        path.line(to: NSPoint(x: cellFrame.width, y: cellFrame.height - (borderThickness / 2)))
        NSColor.white.setStroke()
        path.stroke()

        // Pass in area minus the border thickness in the height
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
                    // Internet connection is available so transition to Main UI
                    viewModel.onboardingStage = 2
                    // Indicate that there's an internet connection
                    viewModel.hasInternetConnection = true
                } else {
                    // No internet connection, show an alert or some relevant UI
                    print("No internet connection.")
                    // Indicate that there's no internet connection
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
                 Image("Frame1.png")
                     .resizable()
                     .scaledToFill()
             )
             .edgesIgnoringSafeArea(.all)
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .background(Color.black)
//        .edgesIgnoringSafeArea(.all)
    }
}







struct OnboardingView3: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @Binding var isShowingOnboarding: Bool

    var body: some View {
        VStack {
            VStack{
                
                Text("You're Set.")
                    .multilineTextAlignment(.center)
                    .fontWeight(.light)
                    .foregroundColor(Color(red: 201/255, green: 201/255, blue: 201/255))
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 10)
                    .font(.custom("Avenir ", size: 18))
                
                Text("We just sent a text confirming")
                    .multilineTextAlignment(.center)
                    .fontWeight(.light)
                    .foregroundColor(Color.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 10)
                    .font(.custom("Avenir ", size: 10))
            }
            
            Button("Continue to App") {
                self.isShowingOnboarding = false
            }
            .buttonStyle(CustomButton())
            .frame(maxWidth: .infinity, alignment: .center)
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


