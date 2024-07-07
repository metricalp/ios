import Foundation

public class Metricalp {
    public static let shared = Metricalp()
    
    public static let API_ENDPOINT = "https://event.metricalp.com"
    var attributes: [String: String]?
    var screenDurationStartPoint = Metricalp.currentTimeInMilliSeconds()
    var currentScreen: String? = nil;
    
    private init() {}
    
    
    func getOSInfo()->String {
        let os = ProcessInfo.processInfo.operatingSystemVersion
        return String(os.majorVersion) + "." + String(os.minorVersion) + "." + String(os.patchVersion)
    }
    
    static func currentTimeInMilliSeconds()-> Int {
            let currentDate = Date()
            let since1970 = currentDate.timeIntervalSince1970
            return Int(since1970 * 1000)
    }
    
    func postRequest(parameters: [String: String], address: String) {
        // WHEN CLI TEST uncomment this
        // let runLoop = CFRunLoopGetCurrent()
        let url = URL(string: address)!
        
        // create the session object
        let session = URLSession.shared
        
        // now create the URLRequest object using the url object
        var request = URLRequest(url: url)
        request.httpMethod = "POST" //set http method as POST
        
        // add headers for the request
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            // convert parameters to Data and assign dictionary to httpBody of request
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch _ {
            return
        }
        
        
        // create dataTask using the session object to send data to the server
        let task = session.dataTask(with: request) { data, response, error in
            
            if let _ = error {
                return
            }
            
            // ensure there is valid response code returned from this HTTP response
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode)
            else {
                return
            }
            
        }
        
        // perform the task
        task.resume()
        // WHEN CLI TEST uncomment this
        // CFRunLoopRun()
    }
    
    public static func initMetricalp(attributes: [String: String], initialScreen: String?, eventAttributes: [String: String]?) {
        if shared.attributes == nil {
            var attrs = attributes
            attrs["metr_collected_via"] = "ios"
            attrs["metr_os_detail"] = "iOS " + shared.getOSInfo()
            attrs["metr_app_detail"] = attrs["app"] ?? "(not-set)"
            shared.setAttributes(attrs)
            
            guard initialScreen != nil else {
                return
            }
            screenViewEvent(path: initialScreen!, eventAttributes: eventAttributes, overrideAttributes: nil)
        }
    }
    
    func getAttributes() -> [String: String]? {
        return attributes
    }
    
    func setAttributes(_ attributes: [String: String]?) {
        self.attributes = attributes
    }
    
    public static func resetAttributes(_ attributes: [String: String]?) {
        shared.setAttributes(attributes)
    }
    
    public static func updateAttributes(_ attributes: [String: String]?) {
        guard let attributes = attributes else { return }
        shared.attributes?.merge(attributes) { (_, new) in new }
    }
    
    public static func getAllAttributes() -> [String: String]? {
        return shared.getAttributes()
    }
    
    public static func getCurrentScreen() -> String? {
        return shared.currentScreen
    }
    
    public static func setCurrentScreen(screen: String?) {
        shared.currentScreen = screen
    }
    
    public static func getScreenDurationStartPoint() -> Int {
        return shared.screenDurationStartPoint
    }
    
    public static func setScreenDurationStartPoint(duration: Int) {
        shared.screenDurationStartPoint = duration
    }
    
    public static func sendEvent(type: String, eventAttributes: [String: String]?, overrideAttributes: [String: String]?) {
        guard let instance = getAllAttributes() else { return }
        var body = instance
        
        if let overrideAttributes = overrideAttributes {
            body.merge(overrideAttributes) { (_, new) in new }
        }
        
        guard let _ = body["tid"] else {
            fatalError("Metricalp: tid is missing in attributes")
        }
        
        guard let _ = body["metr_unique_identifier"] else {
            fatalError("Metricalp: metr_unique_identifier is missing in attributes")
        }
        
        if let eventAttributes = eventAttributes {
            body.merge(eventAttributes) { (_, new) in new }
        }
        
        body["type"] = type
        
        if body["metr_user_language"] == nil {
            body["metr_user_language"] = "unknown-unknown"
        }
        
        if body["path"] == nil {
            body["path"] = "(not-set)"
        }
        
        if body["metr_bypass_ip"] == "disable" {
            body["metr_bypass_ip"] = nil
        } else {
            body["metr_bypass_ip"] = "enable"
        }
        
        let apiUrl = instance["endpoint"] ?? API_ENDPOINT
        body["apiUrl"] = apiUrl
        
        shared.postRequest(parameters: body, address: apiUrl)
        
    }
    
    public static func screenViewEvent(path: String, eventAttributes: [String: String]?, overrideAttributes: [String: String]?) {
        let prevScreen = Metricalp.getCurrentScreen()
        var attrs = ["path": path]
        
        var screenLeaveAttrs: [String: String] = [:]
        
        if (prevScreen != nil) {
            screenLeaveAttrs["leave_from_path"] = prevScreen
            screenLeaveAttrs["leave_from_duration"] = String(Metricalp.currentTimeInMilliSeconds() - Metricalp.getScreenDurationStartPoint())
        }
        
        attrs.merge(screenLeaveAttrs) { (_, new) in new }
        
        if let eventAttributes = eventAttributes {
            attrs.merge(eventAttributes) { (_, new) in new }
        }
        
        Metricalp.setCurrentScreen(screen: path)
        Metricalp.setScreenDurationStartPoint(duration: Metricalp.currentTimeInMilliSeconds())
        
        sendEvent(type: "screen_view", eventAttributes: attrs, overrideAttributes: overrideAttributes)
    }
    
    public static func appLeaveEvent(eventAttributes: [String: String]?, overrideAttributes: [String: String]?) {
        var attrs: [String: String] = [:]
        let prevPath = Metricalp.getCurrentScreen()
        if (prevPath == nil) {
            return
        }
        let screenDuration = Metricalp.currentTimeInMilliSeconds() - Metricalp.getScreenDurationStartPoint()
        Metricalp.setScreenDurationStartPoint(duration: Metricalp.currentTimeInMilliSeconds())
        Metricalp.setCurrentScreen(screen: nil)
        
        attrs["path"] = prevPath
        attrs["screen_duration"] = String(screenDuration)
        
        if let eventAttributes = eventAttributes {
            attrs.merge(eventAttributes) { (_, new) in new }
        }
        sendEvent(type: "screen_leave", eventAttributes: attrs, overrideAttributes: overrideAttributes)
    }
    
    // Deprecated no more manual session exit event triggers
    public static func sessionExitEvent(path: String, eventAttributes: [String: String]?, overrideAttributes: [String: String]?) {
        var attrs = ["path": path]
        if let eventAttributes = eventAttributes {
            attrs.merge(eventAttributes) { (_, new) in new }
        }
        sendEvent(type: "session_exit", eventAttributes: attrs, overrideAttributes: overrideAttributes)
    }
    
    public static func customEvent(type: String, eventAttributes: [String: String]?, overrideAttributes: [String: String]?) {
        sendEvent(type: type, eventAttributes: eventAttributes, overrideAttributes: overrideAttributes)
    }
}
