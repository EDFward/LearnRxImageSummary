//
//  UploadImageViewController.swift
//  RxImageSummary
//
//  Created by Junjia He on 1/8/16.
//  Copyright (c) 2016 Junjia He. All rights reserved.
//

import Cocoa
import ReactiveCocoa


class UploadImageViewController: NSViewController {
  
  let (uploadSignal, uploadObserver) = Signal<Void, NoError>.pipe()

  @IBAction func uploadPic(sender: NSButton) {
    uploadObserver.sendNext()
  }

  @IBOutlet weak var picView: NSImageView!
  
  override func viewDidLoad() {
    super.viewDidLoad()

    let imagePathSignal: Signal<NSURL?, NoError> = uploadSignal
      .map { () -> NSURL? in
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.allowedFileTypes = ["jpg", "png", "jpeg"]
        // Block on file selection.
        if openPanel.runModal() == NSFileHandlingPanelOKButton {
          return openPanel.URL
        } else {
          return nil
        }
      }
      .filter { $0 != nil }

    imagePathSignal.observeNext { url in
      let imgData = NSData(contentsOfURL: url!)
      if imgData != nil {
        let img = NSImage(data: imgData!)
        self.picView.image = img
      } else {
        print("Failed to get img from \(url)")
      }
    }
  }
  
  override func viewDidDisappear() {
    // Clear the signal.
    uploadObserver.sendCompleted()
  }

}
