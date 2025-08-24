import Foundation

@available(macOS 13.0, *)
public enum BundleHelper {
    public static func setupBundle() {
        let bundleIdentifier = "com.notify.cli"
        
        if Bundle.main.bundleIdentifier == nil {
            if let bundleIdentifierKey = kCFBundleIdentifierKey as String? {
                Bundle.main.object(forInfoDictionaryKey: bundleIdentifierKey)
            }
            
            let dummyBundleIdentifier = ProcessInfo.processInfo.processName.isEmpty 
                ? bundleIdentifier 
                : "com.notify.\(ProcessInfo.processInfo.processName)"
            
            if let mainBundleURL = Bundle.main.bundleURL.absoluteString.removingPercentEncoding {
                setenv("CFBundleIdentifier", dummyBundleIdentifier, 1)
                setenv("CFBundleExecutable", ProcessInfo.processInfo.processName, 1)
                setenv("CFBundleName", ProcessInfo.processInfo.processName, 1)
            }
        }
    }
}