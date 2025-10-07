//
//  RetryPolicy.swift
//  ImageDownloader
//
//  Retry mechanism with exponential backoff for failed network requests
//

import Foundation

/// Policy for retrying failed network requests
public struct RetryPolicy {

    // MARK: - Properties

    /// Maximum number of retry attempts
    public let maxRetries: Int

    /// Base delay for the first retry attempt (in seconds)
    public let baseDelay: TimeInterval

    /// Multiplier for exponential backoff
    public let backoffMultiplier: Double

    /// Maximum delay cap (in seconds) to prevent extremely long delays
    public let maxDelay: TimeInterval

    /// Enable detailed logging for retry attempts (default: false)
    public let enableLogging: Bool

    // MARK: - Initialization

    public init(
        maxRetries: Int,
        baseDelay: TimeInterval,
        backoffMultiplier: Double = 2.0,
        maxDelay: TimeInterval = 60.0,
        enableLogging: Bool = false
    ) {
        self.maxRetries = maxRetries
        self.baseDelay = baseDelay
        self.backoffMultiplier = backoffMultiplier
        self.maxDelay = maxDelay
        self.enableLogging = enableLogging
    }

    // MARK: - Presets

    /// Default retry policy (3 retries, 1s base delay, 2x multiplier)
    public static let `default` = RetryPolicy(
        maxRetries: 3,
        baseDelay: 1.0,
        backoffMultiplier: 2.0,
        maxDelay: 30.0
    )

    /// Conservative retry policy (2 retries, 2s base delay, 3x multiplier)
    public static let conservative = RetryPolicy(
        maxRetries: 2,
        baseDelay: 2.0,
        backoffMultiplier: 3.0,
        maxDelay: 60.0
    )

    /// No retry policy (0 retries)
    public static let none = RetryPolicy(
        maxRetries: 0,
        baseDelay: 0.0,
        backoffMultiplier: 1.0,
        maxDelay: 0.0
    )
    
    // MARK: - Public Methods

    /// Calculate the delay for a given retry attempt
    /// - Parameter attempt: The retry attempt number (1-indexed)
    /// - Returns: The delay in seconds before the next retry
    public func delay(forAttempt attempt: Int) -> TimeInterval {
        guard attempt > 0 else { return 0 }

        // Calculate exponential backoff: baseDelay * (backoffMultiplier ^ (attempt - 1))
        let calculatedDelay = baseDelay * pow(backoffMultiplier, Double(attempt - 1))

        // Cap at maxDelay
        return min(calculatedDelay, maxDelay)
    }

    /// Determine if a retry should be attempted for the given error
    /// - Parameters:
    ///   - error: The error that occurred
    ///   - attempt: The current attempt number (0 = first attempt, 1 = first retry, etc.)
    ///   - url: Optional URL for logging context
    /// - Returns: Whether a retry should be attempted
    public func shouldRetry(for error: Error, attempt: Int, url: URL? = nil) -> Bool {
        guard attempt < maxRetries else {
            if enableLogging {
                print("[ImageDownloader] ❌ Max retries (\(maxRetries)) reached for \(url?.absoluteString ?? "unknown")")
            }
            return false
        }

        // Check if the error is retryable
        let shouldRetry = isRetryableError(error)

        if enableLogging {
            if shouldRetry {
                let delay = delay(forAttempt: attempt + 1)
                print("[ImageDownloader] 🔄 Retry \(attempt + 1)/\(maxRetries) for \(url?.absoluteString ?? "unknown") after \(String(format: "%.1f", delay))s - Error: \(error.localizedDescription)")
            } else {
                print("[ImageDownloader] ⚠️ Non-retryable error for \(url?.absoluteString ?? "unknown"): \(error.localizedDescription)")
            }
        }

        return shouldRetry
    }

    // MARK: - Private Methods

    /// Determine if an error is retryable
    private func isRetryableError(_ error: Error) -> Bool {
        let nsError = error as NSError

        // Don't retry cancellations or client errors
        if nsError.code == NSURLErrorCancelled ||
           nsError.code == NSUserCancelledError {
            return false
        }

        // Don't retry bad URLs or file not found
        if nsError.code == NSURLErrorBadURL ||
           nsError.code == NSURLErrorFileDoesNotExist {
            return false
        }

        // Retry network-related errors
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorTimedOut,
                 NSURLErrorCannotFindHost,
                 NSURLErrorCannotConnectToHost,
                 NSURLErrorNetworkConnectionLost,
                 NSURLErrorDNSLookupFailed,
                 NSURLErrorNotConnectedToInternet,
                 NSURLErrorInternationalRoamingOff,
                 NSURLErrorCallIsActive,
                 NSURLErrorDataNotAllowed:
                return true
            default:
                break
            }
        }

        // Check for HTTP status codes (if available)
        if let httpResponse = (error as NSError).userInfo[NSURLErrorFailingURLStringErrorKey] as? HTTPURLResponse {
            // Retry server errors (5xx) and rate limiting (429)
            if httpResponse.statusCode >= 500 || httpResponse.statusCode == 429 {
                return true
            }
        }

        // Default to not retrying unknown errors
        return false
    }
}

