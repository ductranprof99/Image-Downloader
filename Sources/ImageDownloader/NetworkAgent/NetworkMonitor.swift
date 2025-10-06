//
//  NetworkMonitor.swift
//  ImageDownloader
//
//  Network reachability monitoring using NWPathMonitor
//

import Foundation
import Network

/// Monitors network reachability and connection type
@available(iOS 12.0, macOS 10.14, *)
public class NetworkMonitor {

    // MARK: - Singleton

    public static let shared = NetworkMonitor()

    // MARK: - Properties

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.imagedownloader.networkmonitor")

    /// Whether the network is currently reachable
    @available(iOS 12.0, macOS 10.14, *)
    public private(set) var isReachable: Bool = true

    /// Whether the current connection is WiFi
    @available(iOS 12.0, macOS 10.14, *)
    public private(set) var isWiFi: Bool = false

    /// Whether the current connection is cellular
    @available(iOS 12.0, macOS 10.14, *)
    public private(set) var isCellular: Bool = false

    /// Whether the current connection is expensive (cellular, hotspot, etc.)
    @available(iOS 12.0, macOS 10.14, *)
    public private(set) var isExpensive: Bool = false

    /// Callback for reachability changes
    public var onReachabilityChange: ((Bool) -> Void)?

    /// Callback for connection type changes
    public var onConnectionTypeChange: ((Bool, Bool) -> Void)?  // (isWiFi, isCellular)

    /// Whether monitoring is currently active
    private(set) var isMonitoring: Bool = false

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Start monitoring network status
    public func startMonitoring() {
        guard !isMonitoring else { return }

        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }

            let wasReachable = self.isReachable
            let wasWiFi = self.isWiFi
            let wasCellular = self.isCellular

            self.isReachable = path.status == .satisfied
            self.isWiFi = path.usesInterfaceType(.wifi)
            self.isCellular = path.usesInterfaceType(.cellular)
            self.isExpensive = path.isExpensive

            // Notify reachability change
            if wasReachable != self.isReachable {
                DispatchQueue.main.async {
                    self.onReachabilityChange?(self.isReachable)
                }
            }

            // Notify connection type change
            if wasWiFi != self.isWiFi || wasCellular != self.isCellular {
                DispatchQueue.main.async {
                    self.onConnectionTypeChange?(self.isWiFi, self.isCellular)
                }
            }
        }

        monitor.start(queue: queue)
        isMonitoring = true
    }

    /// Stop monitoring network status
    public func stopMonitoring() {
        guard isMonitoring else { return }

        monitor.cancel()
        isMonitoring = false
    }

    /// Get current network status description
    public var statusDescription: String {
        if !isReachable {
            return "No Connection"
        } else if isWiFi {
            return "WiFi"
        } else if isCellular {
            return "Cellular"
        } else {
            return "Connected"
        }
    }
}

// MARK: - Objective-C Compatibility

/// Objective-C compatible network monitor
@available(iOS 12.0, macOS 10.14, *)
@objc public class IDNetworkMonitor: NSObject {

    @objc public static let shared = IDNetworkMonitor()

    private let swiftMonitor = NetworkMonitor.shared

    @objc public var isReachable: Bool {
        return swiftMonitor.isReachable
    }

    @objc public var isWiFi: Bool {
        return swiftMonitor.isWiFi
    }

    @objc public var isCellular: Bool {
        return swiftMonitor.isCellular
    }

    @objc public var isExpensive: Bool {
        return swiftMonitor.isExpensive
    }

    @objc public var isMonitoring: Bool {
        return swiftMonitor.isMonitoring
    }

    @objc public var statusDescription: String {
        return swiftMonitor.statusDescription
    }

    private override init() {
        super.init()
    }

    @objc public func startMonitoring() {
        swiftMonitor.startMonitoring()
    }

    @objc public func stopMonitoring() {
        swiftMonitor.stopMonitoring()
    }

    @objc public func setReachabilityChangeHandler(_ handler: @escaping (Bool) -> Void) {
        swiftMonitor.onReachabilityChange = handler
    }

    @objc public func setConnectionTypeChangeHandler(_ handler: @escaping (Bool, Bool) -> Void) {
        swiftMonitor.onConnectionTypeChange = handler
    }
}
