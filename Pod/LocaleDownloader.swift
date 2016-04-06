//
//  LocaleDownloader.swift
//  Pods
//
//  Created by Nick Lee on 4/5/16.
//
//

import Foundation
import Alamofire

@objc public final class LocaleDownloader: NSObject {
    
    // MARK: Types
    
    public typealias Completion = (success: Bool, error: NSError?) -> ()
    
    // MARK: Singleton
    
    public static let sharedInstance = LocaleDownloader()
    
    // MARK: Public Properties
    
    public var remoteArchiveLocation: NSURL?
    public var updateInterval = Constants.DefaultUpdateInterval
    
    public private(set) var lastUpdated: NSDate {
        get {
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.synchronize()
            return (defaults.objectForKey(Constants.LastUpdatedDefaultsKey) as? NSDate) ?? NSDate.distantPast()
        }
        set {
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setObject(newValue, forKey: Constants.LastUpdatedDefaultsKey)
            defaults.synchronize()
        }
    }
    
    // MARK: Initialization
    
    private override init() {
        super.init()
    }
    
    // MARK: Downloading
    
    public func downloadLocalizationsIfNeeded(completion: Completion? = nil) {
        let interval = NSDate().timeIntervalSinceDate(lastUpdated)
        if interval < updateInterval || Constants.isSimulator {
            if Constants.isSimulator {
                print("Running on iOS Simulator -- not auto downloading localization data")
            }
            completion?(success: true, error: nil)
            return
        }
        downloadLocalizations(completion)
    }
    
    public func downloadLocalizations(completion: Completion? = nil) {
        guard let url = remoteArchiveLocation else {
            return
        }
        request(.GET, url).validate(statusCode: 200..<300).responseData { response in
            if let error = response.result.error {
                completion?(success: false, error: response.result.error)
                return
            }
            guard let zipData = response.data else {
                completion?(success: false, error: response.result.error)
                return
            }
            do {
                try self.processLocalizationData(zipData)
                self.lastUpdated = NSDate()
                completion?(success: true, error: nil)
            }
            catch let err as NSError {
                completion?(success: false, error: err)
            }
            catch {
                completion?(success: false, error: nil)
            }
        }
    }
 
    private func processLocalizationData(data: NSData) throws {
        try NSFileManager.defaultManager().createDirectoryAtPath(Constants.LibraryPath, withIntermediateDirectories: true, attributes: nil)
        let path = Constants.CachedLocalizationArchivePath
        guard data.writeToFile(path, atomically: true) else {
            throw LocaleKitError.FailedToWriteData
        }
        let fileURL = NSURL(fileURLWithPath: path)
        try Locale.sharedInstance.load(fileURL)
    }
    
}