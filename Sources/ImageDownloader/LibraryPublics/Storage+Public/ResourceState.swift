//
//  ResourceModel.swift
//  ImageDownloader
//
//  Model representing a downloadable image resource
//

public enum ResourceState {
    case unknown
    case downloading
    case available
    case failed
}

@objc public enum ResourcePriority: Int {
    case low
    case high
}

