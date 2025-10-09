//
//  ResourceModel.swift
//  ImageDownloader
//
//  Model representing a downloadable image resource
//

@objc public enum ResourceState: Int {
    case unknown
    case downloading
    case available
    case failed
}

@objc public enum ResourceLatency: Int {
    case low
    case high
    
    var isHighLatency: Bool {
        return self == .high
    }
}


@objc public enum DownloadPriority: Int {
    case high = 1
//    case `default` = 2
    case low = 2
}
