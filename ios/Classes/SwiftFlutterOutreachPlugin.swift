import Flutter
import UIKit
import MessageUI
import Alamofire
import AVFoundation
import Photos

enum MediaType {
    case IMAGE
    case VIDEO
}

struct MediaFile {
    let type: MediaType
    let data: Data?
    let url: URL?
    let fileName: String
}


public class SwiftFlutterOutreachPlugin: NSObject, FlutterPlugin, UINavigationControllerDelegate, MFMessageComposeViewControllerDelegate, URLSessionDelegate, URLSessionDataDelegate {
   
    
    var result: FlutterResult!
    var arguments = [String : Any]()
    var attachements = [MediaFile]() {
        didSet {
            if attachements.count == attachmentsCount {
                activeOutreach()
            }
        }
    }
    var urlsToShare = [String]()
    var textToShare = ""
    var urlSession: URLSession?
    var downloadTask: URLSessionDownloadTask!
    var buffer: NSMutableData = NSMutableData()
    var expectedContentLength = 0
    var attachmentsCount = 0
    var call: FlutterMethodCall!
    var token: String?

    
    lazy var progressView: UIProgressView! = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.center = (UIApplication.shared.keyWindow?.rootViewController?.view!.center)!
        progressView.trackTintColor = UIColor.lightGray
        progressView.tintColor = UIColor.blue
        return progressView
    }()
    
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_outreach", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterOutreachPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.call = call
        self.result = result
        urlSession = URLSession(configuration: .default, delegate:self, delegateQueue: .main)
        arguments = call.arguments as! [String :Any]
        token = arguments["access_token"] as? String
        textToShare = (arguments["message"] as? String) ?? ""
        if let urls = arguments["urls"] as? [String], urls.count > 0 {
            self.urlsToShare = urls
            attachmentsCount = urls.count
            UIApplication.shared.keyWindow?.rootViewController?.view.addSubview(progressView)
            downloadData()
        } else {
            switch call.method {
            case "sendSMS":
                sendSMS(arguments: arguments, result: result)
            case "sendInstantMessaging":
                sendToInstantMessaging(arguments: arguments, result: result)
            case "canSendSMS":
                result(MFMessageComposeViewController.canSendText())
            default:
                result(FlutterMethodNotImplemented)
            }
        }
      
    }
    
    public func activeOutreach() {
        switch call?.method {
        case "sendSMS":
            sendSMS(arguments: arguments, result: result)
        case "sendInstantMessaging":
            sendToInstantMessaging(arguments: arguments, result: result)
        case "canSendSMS":
            result(MFMessageComposeViewController.canSendText())
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    public func sendSMS(arguments: [String:Any], result: @escaping FlutterResult) {
        if(MFMessageComposeViewController.canSendText()) {
            self.result = result
            let controller = MFMessageComposeViewController()
            controller.body = textToShare
            controller.recipients = arguments["recipients"] as? [String]
            self.attachements.forEach({ mediaFile in
                if let data = mediaFile.data {
                    controller.addAttachmentData(data, typeIdentifier: "public.data", filename: mediaFile.fileName)
                }
            })
            controller.messageComposeDelegate = self
            DispatchQueue.main.async { [weak self] in
                self?.progressView.removeFromSuperview()
                UIApplication.shared.keyWindow?.rootViewController?.present(controller, animated: true,completion: nil)
            }
            
        } else {
            result( FlutterError(code: "device_not_supported", message: "You can't send text messages.", details: "A device may be unable to send messages if it does not support messaging or if it is not currently configured to send messages. This only applies to the ability to send text messages via iMessage, SMS, and MMS."
                                ) )
        }
    }
    
    public func sendToInstantMessaging(arguments: [String:Any], result: @escaping FlutterResult) {
        self.result = result
        self.progressView.removeFromSuperview()
        var items = [Any]()
        if self.urlsToShare.count > 0 {
            items.append(contentsOf: self.attachements.map({$0.data?.dataToFile(fileName: $0.fileName) as Any}))
        } else {
            items.append(textToShare)
        }
        let activityVC = UIActivityViewController(activityItems: items , applicationActivities: nil)
        activityVC.excludedActivityTypes = [ .airDrop, .addToReadingList, .assignToContact, .copyToPasteboard, .mail, .message, .postToTencentWeibo, .postToVimeo, .postToWeibo, .print ]
        UIApplication.shared.keyWindow?.rootViewController?.present(activityVC, animated: true,completion: nil)
    }
    
    
    public func downloadData() {
        if attachements.count < attachmentsCount, let url = URL(string: urlsToShare[attachements.count]) {
            var urlRequest = URLRequest(url: url)
            if let token = token {
                urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            let task = urlSession?.downloadTask(with: urlRequest)
            task?.resume()
        } else {
            
        }
        
    }
    
    func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    public func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        let map: [MessageComposeResult: String] = [
            MessageComposeResult.sent: "sent",
            MessageComposeResult.cancelled: "cancelled",
            MessageComposeResult.failed: "failed",
        ]
        if let callback = self.result {
            callback(map[result])
        }
        UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: true, completion: nil)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        buffer.append(data)
        let percentageDownloaded = Float(buffer.length) / Float(expectedContentLength)
        self.progressView.setProgress(percentageDownloaded, animated: true)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: (URLSession.ResponseDisposition) -> Void) {
        expectedContentLength = Int(response.expectedContentLength)
        completionHandler(URLSession.ResponseDisposition.allow)
        
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        self.progressView.setProgress(1.0, animated: true)
        guard let location = task.response?.url else { return }
        guard let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let destURL = documentsDirectoryURL.appendingPathComponent(location.lastPathComponent).path
        let data = try? Data(contentsOf: location)
        self.attachements.append(MediaFile(type: ["png", "jpg", "gif"].contains(where: {$0 == location.pathExtension.lowercased()}) ? .IMAGE : .VIDEO, data: data, url: URL(string: destURL), fileName: "\(self.randomString(length: 5)).\(location.pathExtension.lowercased())"))
        downloadData()
    }
}


extension Data {
    
    /// Get the current directory
    ///
    /// - Returns: the Current directory in NSURL
    func getDocumentsDirectory() -> NSString {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory as NSString
    }
    
    
    /// Data into file
    ///
    /// - Parameters:
    ///   - fileName: the Name of the file you want to write
    /// - Returns: Returns the URL where the new file is located in NSURL
    func dataToFile(fileName: String) -> NSURL? {
        
        // Make a constant from the data
        let data = self
        
        // Make the file path (with the filename) where the file will be loacated after it is created
        let filePath = getDocumentsDirectory().appendingPathComponent(fileName)
        
        do {
            // Write the file from data into the filepath (if there will be an error, the code jumps to the catch block below)
            try data.write(to: URL(fileURLWithPath: filePath))
            
            // Returns the URL where the new file is located in NSURL
            return NSURL(fileURLWithPath: filePath)
            
        } catch {
            // Prints the localized description of the error from the do block
            print("Error writing the file: \(error.localizedDescription)")
        }
        
        // Returns nil if there was an error in the do-catch -block
        return nil
        
    }
    
}
