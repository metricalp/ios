import Foundation

public class Metricalp {
    static let shared = Metricalp()
    
    static let API_ENDPOINT = "https://event.metricalp.com"
    var attributes: [String: String]?
    
    private init() {}
    
    
    func getOSInfo()->String {
        let os = ProcessInfo.processInfo.operatingSystemVersion
        return String(os.majorVersion) + "." + String(os.minorVersion) + "." + String(os.patchVersion)
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
        } catch let error {
            return
        }
        
        
        // create dataTask using the session object to send data to the server
        let task = session.dataTask(with: request) { data, response, error in
            
            if let error = error {
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
    
    static func initMetricalp(attributes: [String: String], initialScreen: String?) -> Bool {
        if shared.attributes == nil {
            var attrs = attributes
            attrs["metr_collected_via"] = "ios"
            attrs["metr_os_detail"] = "iOS " + shared.getOSInfo()
            attrs["metr_app_detail"] = attrs["app"] ?? "(not-set)"
            shared.setAttributes(attrs)
            
            guard initialScreen != nil else {
                return true
            }
            return screenViewEvent(path: initialScreen!, eventAttributes: nil, overrideAttributes: nil)
        }
        return true
    }
    
    func getAttributes() -> [String: String]? {
        return attributes
    }
    
    func setAttributes(_ attributes: [String: String]?) {
        self.attributes = attributes
    }
    
    static func resetAttributes(_ attributes: [String: String]?) {
        shared.setAttributes(attributes)
    }
    
    static func updateAttributes(_ attributes: [String: String]?) {
        guard let attributes = attributes else { return }
        shared.attributes?.merge(attributes) { (_, new) in new }
    }
    
    static func getAllAttributes() -> [String: String]? {
        return shared.getAttributes()
    }
    
    static func sendEvent(type: String, eventAttributes: [String: String]?, overrideAttributes: [String: String]?) -> Bool {
        guard let instance = getAllAttributes() else { return false }
        var body = instance
        
        if let overrideAttributes = overrideAttributes {
            body.merge(overrideAttributes) { (_, new) in new }
        }
        
        guard let _ = body["tid"] else {
            fatalError("Metricalp: tid is missing in attributes")
        }
        
        if body["metr_bypass_ip"] != nil && body["metr_unique_identifier"] == nil {
            fatalError("Metricalp: when metr_bypass_ip is true, metr_unique_identifier must be set.")
        }
        
        if let eventAttributes = eventAttributes {
            body.merge(eventAttributes) { (_, new) in new }
            body["path"] = eventAttributes["path"] ?? "(not-set)"
        }
        
        body["type"] = type
        
        if body["metr_user_language"] == nil {
            body["metr_user_language"] = "unknown-unknown"
        }
        
        if body["metr_unique_identifier"] == nil {
            body["metr_unique_identifier"] = ""
        }
        
        let apiUrl = instance["endpoint"] ?? API_ENDPOINT
        body["apiUrl"] = apiUrl
        
        shared.postRequest(parameters: body, address: apiUrl)
        
        return true
    }
    
    static func screenViewEvent(path: String, eventAttributes: [String: String]?, overrideAttributes: [String: String]?) -> Bool {
        var attrs = ["path": path]
        if let eventAttributes = eventAttributes {
            attrs.merge(eventAttributes) { (_, new) in new }
        }
        return sendEvent(type: "screen_view", eventAttributes: attrs, overrideAttributes: overrideAttributes)
    }
    
    static func sessionExitEvent(path: String, eventAttributes: [String: String]?, overrideAttributes: [String: String]?) -> Bool {
        var attrs = ["path": path]
        if let eventAttributes = eventAttributes {
            attrs.merge(eventAttributes) { (_, new) in new }
        }
        return sendEvent(type: "session_exit", eventAttributes: attrs, overrideAttributes: overrideAttributes)
    }
    
    static func customEvent(type: String, eventAttributes: [String: String]?, overrideAttributes: [String: String]?) -> Bool {
        return sendEvent(type: type, eventAttributes: eventAttributes, overrideAttributes: overrideAttributes)
    }
}
