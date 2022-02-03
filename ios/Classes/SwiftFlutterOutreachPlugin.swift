import Flutter
import UIKit
import MessageUI
import AVFoundation
import Photos

struct MediaFile {
    let data: Data?
    let url: URL?
    let fileName: String
}


public class SwiftFlutterOutreachPlugin: NSObject, FlutterPlugin, UINavigationControllerDelegate, MFMessageComposeViewControllerDelegate {
   
    
    var result: FlutterResult!
    var arguments = [String : Any]()
    var attachments = [MediaFile]() {
        didSet {
            if attachments.count == attachmentsCount, attachments.count > 0 {
                activeOutreach()
            }
        }
    }
    var urlsToShare = [[String : String]]()
    var currentUrl = [String : String]()
    var textToShare = ""
    var urlSession: URLSession?
    var downloadTask: URLSessionDownloadTask!
    var attachmentsCount = 0
    var call: FlutterMethodCall!
    var token: String?
    var loaderAlreadyInstanced = false
    var recipients = [String]()

    
    lazy var loaderView: ProgressLoader! = {
        loaderView = ProgressLoader(text: "Downloading ...")
        return loaderView
    }()
    
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_outreach", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterOutreachPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {

        loaderView.removeFromSuperview()

        self.call = call
        self.result = result
        arguments = call.arguments as! [String :Any]
        token = arguments["access_token"] as? String
        textToShare = (arguments["message"] as? String) ?? ""
        recipients = (arguments["recipients"] as? [String]) ?? []
        if let urls = arguments["urls"] as? [[String : String]], urls.count > 0 {
            attachments = []
            self.urlsToShare = urls
            attachmentsCount = urls.count
            currentUrl = urls[0]
            UIApplication.shared.keyWindow?.rootViewController?.view.addSubview(loaderView)
            downloadData()
        } else {
            switch call.method {
            case "sendSMS":
                sendSMS(arguments: arguments, result: result)
            case "sendEmail":
                sendEmail(arguments: arguments, result: result)
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
        case "sendEmail":
            sendEmail(arguments: arguments, result: result)
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
            
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.result = result
                let controller = MFMessageComposeViewController()
                controller.body = strongSelf.textToShare
                controller.recipients = arguments["recipients"] as? [String]
                strongSelf.attachments.forEach({ mediaFile in
                    if let data = mediaFile.data {
                        controller.addAttachmentData(data, typeIdentifier: "public.data", filename: mediaFile.fileName)
                    }
                })
                controller.messageComposeDelegate = self
                strongSelf.loaderView.removeFromSuperview()
                UIApplication.shared.keyWindow?.rootViewController?.present(controller, animated: true,completion: nil)
            }
            
        } else {
            result( FlutterError(code: "device_not_supported", message: "You can't send text messages.", details: "A device may be unable to send messages if it does not support messaging or if it is not currently configured to send messages. This only applies to the ability to send text messages via iMessage, SMS, and MMS."
                                ) )
        }
    }
    
    public func sendEmail(arguments: [String:Any], result: @escaping FlutterResult) {
        if(MFMailComposeViewController.canSendMail()) {
       
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.result = result
                let controller = MFMailComposeViewController()
                controller.setSubject(strongSelf.textToShare)
                controller.setToRecipients(arguments["recipients"] as? [String])
                strongSelf.attachments.forEach({ mediaFile in
                    if let data = mediaFile.data {
                        controller.addAttachmentData(data, mimeType: "public.data", fileName: mediaFile.fileName)
                    }
                })
                controller.mailComposeDelegate = strongSelf
                strongSelf.loaderView.removeFromSuperview()
                UIApplication.shared.keyWindow?.rootViewController?.present(controller, animated: true,completion: nil)
            }
            
        } else {
            result( FlutterError(code: "device_not_supported", message: "You can't send text messages.", details: "A device may be unable to send messages if it does not support messaging or if it is not currently configured to send messages. This only applies to the ability to send text messages via iMessage, SMS, and MMS."
                                ) )
        }
    }
    
    public func sendToInstantMessaging(arguments: [String:Any], result: @escaping FlutterResult) {
  
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.result = result
            var items = [Any]()
            if strongSelf.urlsToShare.count > 0 {
                items.append(contentsOf: strongSelf.attachments.map({$0.data?.dataToFile(fileName: $0.fileName) as Any}))
            } else {
                items.append(strongSelf.textToShare)
            }
            let activityVC = UIActivityViewController(activityItems: items , applicationActivities: nil)
            activityVC.excludedActivityTypes = [ .airDrop, .addToReadingList, .assignToContact, .copyToPasteboard, .mail, .message, .postToTencentWeibo, .postToVimeo, .postToWeibo, .print ]
            activityVC.completionWithItemsHandler = {(activityType, completed, returnedItems, error) in
                if !completed {
                    return
                }
                strongSelf.attachments.forEach { file in
                    if let url = file.url {
                        try? FileManager.default.removeItem(at: url)
                    }
                }
                result([
                    "outreachType" : strongSelf.getOutreachType(activityType) as Any,
                    "isSuccess" : completed
                ])
            }
            strongSelf.loaderView.removeFromSuperview()
            UIApplication.shared.keyWindow?.rootViewController?.present(activityVC, animated: true,completion: nil)
        }
      
    }
    
    func getOutreachType(_ activityType: UIActivity.ActivityType?) -> String? {
        guard let activityTypeStr = activityType?.rawValue.lowercased() else { return nil }
        if activityTypeStr.contains(".whatsapp.") {
            return "Whatsapp"
        }
        if activityTypeStr == "com.tencent.xin.sharetimeline" {
            return "WeChat"
        }
        if activityTypeStr.contains(".kakaotalk.") {
            return "Kakao"
        }
        if activityTypeStr.contains(".line.") || activityTypeStr.contains(".worksone.") {
            return "Line"
        }
        return nil
    }
    
    
    public func downloadData() {
        if attachments.count < attachmentsCount, let urlString = urlsToShare[attachments.count]["url"], let url = URL(string:urlString) {
            currentUrl = urlsToShare[attachments.count]
            var urlRequest = URLRequest(url: url)
            if let token = token {
                urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            URLSession.shared.downloadTask(with: urlRequest, completionHandler: { url, urlResponse, error in
                guard let location = url else { return }
                guard let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
                let destURL = documentsDirectoryURL.appendingPathComponent(location.lastPathComponent).path
                let data = try? Data(contentsOf: location)
                let fileName: String = self.currentUrl["fileName"] ?? ""
                self.attachments.append(MediaFile(data: data, url: URL(string: destURL), fileName: fileName))
                self.downloadData()
            }).resume()
        } else {
            
        }
        
    }
    
    
    public func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        self.result([
            "outreachType" : "SMS",
            "isSuccess" : result == .sent
        ])
        UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: true, completion: nil)
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


extension SwiftFlutterOutreachPlugin: MFMailComposeViewControllerDelegate {
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        switch result {
        case .failed:
            self.result([
                "outreachType" : "Email",
                "isSuccess" : false
            ])
        case .cancelled:
            self.result([
                "outreachType" : "Email",
                "isSuccess" : false
            ])
        case .sent:
            self.result([
                "outreachType" : "Email",
                "isSuccess" : true
            ])
        default:
            print("")
        }
        
        controller.dismiss(animated: true, completion: nil)
    }
}
