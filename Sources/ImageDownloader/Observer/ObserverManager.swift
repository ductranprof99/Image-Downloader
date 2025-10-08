//
//  ObserverManager.swift
//  ImageDownloader
//
//  Created by ductd on 6/10/25.
//

import Foundation

class ObserverManager {

    // MARK: - Properties

    // MARK: - Initialization

    public init() {}

    // MARK: - Public Methods

    func addObserver(_ observer: ImageDownloaderObserver) {
        
    }

    func removeObserver(_ observer: ImageDownloaderObserver) {
        
    }

    func notifyImageDidLoad(url: URL, fromCache: Bool, fromStorage: Bool) {
        
    }

    func notifyImageDidFail(url: URL, error: Error) {
        
    }

    func notifyDownloadProgress(url: URL, progress: CGFloat) {
        
    }

    func notifyWillStartDownloading(url: URL) {
      
    }
}
