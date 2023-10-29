
import Foundation
import SwiftUI

struct PreferencesView: View {
    struct windowSize {
    // changes let to static - read comments
        static var minWidth : CGFloat = 600
        static var minHeight : CGFloat = 380
        static var maxWidth : CGFloat = 600
        static var maxHeight : CGFloat = 380
    }

    @State var isShowingOnboarding = true

    var body: some View {
        OnboardingParentView(isShowingOnboarding: $isShowingOnboarding, startAtStage: 3)
            .frame(minWidth: windowSize.minWidth, minHeight: windowSize.minHeight)
            .frame(maxWidth: windowSize.maxWidth, maxHeight: windowSize.maxHeight)    }
}







