import Flutter
import UIKit
import MessageUI
import AVFoundation
import Photos
import UIKit
import LinkPresentation

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
        attachments = []
        self.urlsToShare = []
        attachmentsCount = 0
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
                controller.setMessageBody(strongSelf.textToShare, isHTML: false)
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
            var items = [ShareableItem]()
            if strongSelf.urlsToShare.count > 0 {
                strongSelf.attachments.forEach { file in
                    // if let url = file.url {
                    //     try? FileManager.default.removeItem(at: url)
                    // }
                    if let data = file.data {
                        if let image = UIImage(data:data) {
                            items.append(ShareableItem(image: image, title: strongSelf.textToShare))
                        }
                    }
                }
            } else {
                items.append(ShareableItem(image: nil, title: strongSelf.textToShare))
                // if let image = UIImage(named: "boucheron_diamond.jpg",
                //                         in: Bundle(for: FlutterOutreachPlugin.self),
                //                         compatibleWith: nil) {
                //     items.append(ShareableItem(image: image, title: strongSelf.textToShare))
                // }
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


final class ShareableItem: NSObject, UIActivityItemSource {
    private let image: UIImage?
    private let title: String?

    init(image: UIImage?, title: String?) {
        self.image = image
        self.title = title
        super.init()
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return image ?? "";
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return image
    }
    
    @available(iOS 13.0, *)
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        
        let metadata = LPLinkMetadata()
        metadata.title = title
        if let img = image {
            metadata.iconProvider = NSItemProvider(object: img)
            let size = img.fileSize()
            let type = img.fileType()
            let subtitleString = "\(type.uppercased()) File · \(size)"
            metadata.originalURL = URL(fileURLWithPath: subtitleString)
        }
        return metadata
    }
}

extension UIImage {
    func fileType() -> String {
        guard let data = self.jpegData(compressionQuality: 1), data.count > 8 else { return "Unknown" }
        
        var header = [UInt8](repeating: 0, count: 8)
        data.copyBytes(to: &header, count: 8)
        
        switch header {
        case [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]: // PNG: 89 50 4E 47 0D 0A 1A 0A
            return "png"
        case [0xFF, 0xD8, 0xFF]: // JPEG: FF D8 FF
            return "jpg"
        default:
            return "unknown"
        }
    }
    
    func fileSize() -> String {
        guard let imageData = self.jpegData(compressionQuality: 1) else { return "Unknown" }
        let size = Double(imageData.count) // in bytes
        if size < 1024 {
            return String(format: "%.2f bytes", size)
        } else if size < 1024 * 1024 {
            return String(format: "%.2f KB", size/1024.0)
        } else {
            return String(format: "%.2f MB", size/(1024.0*1024.0))
        }
    }
}
