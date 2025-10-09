//
//  SessionDelegate.swift
//  ImageDownloader
//
//  URLSession delegate for handling authentication challenges
//

import Foundation

/// Shared URLSession delegate for handling authentication challenges
internal final class SessionDelegate: NSObject, URLSessionDelegate {

    static let shared = SessionDelegate()

    private override init() {
        super.init()
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        completionHandler(.performDefaultHandling, nil)
    }
}
