//
//  AppDelegate.swift
//  RxImageSummary
//
//  Created by Junjia He on 1/8/16.
//  Copyright © 2016 Junjia He. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  @IBOutlet weak var window: NSWindow!

  var viewController: ViewController!

  func applicationDidFinishLaunching(aNotification: NSNotification) {
    window.styleMask = NSClosableWindowMask | NSTitledWindowMask | NSMiniaturizableWindowMask

    viewController = ViewController(nibName: "ViewController", bundle: nil)
    window.contentView!.addSubview(viewController.view)
    viewController.view.frame = (window.contentView! as NSView).bounds
  }

  func applicationWillTerminate(aNotification: NSNotification) {
    // Insert code here to tear down your application
  }
}
