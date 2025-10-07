
struct LoadStats {
    let loadTime: TimeInterval
    let source: String
    let retryCount: Int

    var loadTimeString: String {
        String(format: "%.2fs", loadTime)
    }
}

