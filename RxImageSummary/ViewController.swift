import Cocoa
import ReactiveCocoa

class ViewController: NSViewController, NSSplitViewDelegate {

  let (uploadSignal, uploadObserver) = Signal<Void, NSError>.pipe()

  let apiInfo = NSDictionary(contentsOfFile: NSBundle.mainBundle().pathForResource("APIKey", ofType: "plist")!)!

  @IBOutlet weak var infoView: NSScrollView!

  @IBOutlet weak var imageView: NSImageView!

  @IBAction func uploadPic(sender: NSButton) {
    uploadObserver.sendNext()
  }

  private func imageAnalysisRequest(imageData: NSData) -> NSURLRequest {
    let apiKey = apiInfo["AlchemyAPIKey"]!

    let urlString = [
      "http://gateway-a.watsonplatform.net/calls/image/ImageGetRankedImageKeywords?",
      "apikey=\(apiKey)&",
      "imagePostMode=raw&",
      "outputMode=json",
      ].joinWithSeparator("")
    let URL = NSURL(string: urlString)!
    let request = NSMutableURLRequest(URL: URL)
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    request.HTTPMethod = "POST"
    request.HTTPBody = imageData
    return request
  }

  private func parseAnalysisResult(data: NSData) -> String {
    if let resp = try? NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as! NSDictionary {
      if resp["status"] as! String == "OK" {
        var keywords = [String]()
        if let keywordList = resp["imageKeywords"] as? [[String: AnyObject]] {
          for keyword in keywordList {
            var keywordString = "";
            if let text = keyword["text"] as? String {
              keywordString += text
            }
            keywordString += " - "
            if let score = keyword["score"] as? String {
              keywordString += score
            }
            keywords.append(keywordString)
          }
        }
        return keywords.joinWithSeparator("\n")
      }
    }
    return "Failed to get analysis results."
  }

  override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: NSBundle!) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)!

    let imageData: Signal<NSData?, NSError> = uploadSignal
      .map { () in
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseFiles = true
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

    // Display the selected picture.
    imageData.observeNext { data in
      self.imageView.image = NSImage(data: data!)
    }

    let analysisResults = imageData
      .flatMap(FlattenStrategy.Latest) { (data: NSData?) -> SignalProducer<(NSData, NSURLResponse), NSError> in
        // Must be non-nil after filtering.
        let URLRequest = self.imageAnalysisRequest(data!)
        return NSURLSession.sharedSession().rac_dataWithRequest(URLRequest)
      }
      .map({ (data: NSData, URLResponse: NSURLResponse) -> String in
        return self.parseAnalysisResult(data)
      })

    let textUpdates = SignalProducer(values: [imageData.map { _ in "Loading..." }, analysisResults]).flatten(.Merge)

    textUpdates.startWithNext { text in
      dispatch_async(dispatch_get_main_queue(), {
        self.infoView.documentView!.setString(text)
      })
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    // Configure the text info view.
    let textView = infoView.documentView as! NSTextView
    textView.editable = false
    textView.font = NSFont(name: "Menlo", size: 12)
  }

  override func viewDidDisappear() {
    // Clear the signal.
    uploadObserver.sendCompleted()
  }

  func splitView(splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
    return proposedMinimumPosition + 180
  }

}
