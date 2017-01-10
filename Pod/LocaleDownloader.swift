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
    
    public typealias Completion = (_ success: Bool, _ error: Error?) -> ()
    
    // MARK: Singleton
    
    public static let sharedInstance = LocaleDownloader()
    
    // MARK: Public Properties
    
    public var remoteArchiveLocation: URL?
    public var updateInterval = Constants.DefaultUpdateInterval
    
    public fileprivate(set) var lastUpdated: Date {
        get {
            let defaults = UserDefaults.standard
            defaults.synchronize()
            return (defaults.object(forKey: Constants.LastUpdatedDefaultsKey) as? Date) ?? Date.distantPast
        }
        set {
            let defaults = UserDefaults.standard
            defaults.set(newValue, forKey: Constants.LastUpdatedDefaultsKey)
            defaults.synchronize()
        }
    }
    
    // MARK: Initialization
    
    fileprivate override init() {
        super.init()
    }
    
    // MARK: Downloading
    
    public func downloadLocalizationsIfNeeded(_ completion: Completion? = nil) {
        let interval = Date().timeIntervalSince(lastUpdated)
        if interval < updateInterval || Constants.isSimulator {
            if Constants.isSimulator {
                print("Running on iOS Simulator -- not auto downloading localization data")
            }
            completion?(true, nil)
            return
        }
        downloadLocalizations(completion)
    }
    
    public func downloadLocalizations(_ completion: Completion? = nil) {
        guard let url = remoteArchiveLocation else {
            return
        }
        request(url).validate(statusCode: 200..<300).responseData { response in
            if let error = response.result.error {
                completion?(false, response.result.error)
                return
            }
            guard let zipData = response.data else {
                completion?(false, response.result.error)
                return
            }
            do {
                try self.processLocalizationData(zipData)
                self.lastUpdated = Date()
                completion?(true, nil)
            }
            catch let err as NSError {
                completion?(false, err)
            }
            catch {
                completion?(false, nil)
            }
        }
    }
 
    fileprivate func processLocalizationData(_ data: Data) throws {
        try FileManager.default.createDirectory(atPath: Constants.LibraryPath, withIntermediateDirectories: true, attributes: nil)
        let path = Constants.CachedLocalizationArchivePath
        guard (try? data.write(to: URL(fileURLWithPath: path), options: [.atomic])) != nil else {
            throw LocaleKitError.failedToWriteData
        }
        let fileURL = URL(fileURLWithPath: path)
        try Locale.sharedInstance.load(fileURL)
    }
    
}
