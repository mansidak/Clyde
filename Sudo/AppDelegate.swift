//
//  AppDelegate.swift
//  Sudo
//
//  Created by Mansidak Singh on 9/23/23.
//

import Foundation
import AppKit
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var statusBarItem: NSStatusItem!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = self.statusBarItem.button {
            button.image = NSImage(named: NSImage.Name("YourImageName"))
            button.action = #selector(self.statusBarButtonClicked(sender:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    @objc func statusBarButtonClicked(sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!
        
        if event.type == NSEvent.EventType.rightMouseUp {
            print("Right click")
            // Here you should present your settings menu.
        } else {
            print("Left click")
            // Here you should present your standard menu or perform your standard action.
        }
    }
}
