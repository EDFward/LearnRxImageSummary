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
  
  let (uploadSignal, uploadObserver) = Signal<Void, NSError>.pipe()

  let apiInfo = NSDictionary(contentsOfFile: NSBundle.mainBundle().pathForResource("APIKey", ofType: "plist")!)!

  @IBAction func uploadPic(sender: NSButton) {
    uploadObserver.sendNext()
  }

  @IBOutlet weak var picView: NSImageView!
  
  private func imageAnalysisRequest(imageData: NSData) -> NSURLRequest {
    let apiKey = apiInfo["AlchemyAPIKey"]!

    let urlString = [
      "http://gateway-a.watsonplatform.net/calls/image/ImageGetRankedImageKeywords?",
      "apikey=\(apiKey)&",
      "imagePostMode=raw&",
      "outputMode=json"].joinWithSeparator("")
    let URL = NSURL(string: urlString)!
    let request = NSMutableURLRequest(URL: URL)
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    request.HTTPMethod = "POST"
    request.HTTPBody = imageData
    return request
  }

  override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: NSBundle!) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)!

    let imageData: Signal<NSData?, NSError> = uploadSignal
      .map { () in
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.allowedFileTypes = ["jpg", "png", "jpeg"]
        // Block on file selection.
        if openPanel.runModal() == NSFileHandlingPanelOKButton {
          if let url = openPanel.URL {
            return NSData(contentsOfURL:url)
          }
        }
        return nil
      }
      .filter { $0 != nil }

    // TODO: Throttling, test flatten strategy, etc.

    // Display the selected picture.
    imageData.observeNext { data in
      self.picView.image = NSImage(data: data!)
    }

    let analysisResults = imageData
      .flatMap(FlattenStrategy.Latest) { (data: NSData?) -> SignalProducer<(NSData, NSURLResponse), NSError> in
        // Must be non-nil after filtering.
        let URLRequest = self.imageAnalysisRequest(data!)
        return NSURLSession.sharedSession().rac_dataWithRequest(URLRequest)
      }
      .map({ (data: NSData, URLResponse: NSURLResponse) -> String in
        let result = String(data: data, encoding: NSUTF8StringEncoding)!
        return result
      })

    // For now, simply output to console.
    analysisResults.observeNext { res in
      print(res)
    }
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
  }

  override func viewDidDisappear() {
    // Clear the signal.
    uploadObserver.sendCompleted()
  }

}
