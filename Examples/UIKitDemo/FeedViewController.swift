//
//  FeedViewController.swift
//  UIKitDemo
//
//  Main feed view controller demonstrating ImageDownloader
//

import UIKit
import ImageDownloader
import ImageDownloaderUI

class FeedViewController: UIViewController {

    // MARK: - Properties

    private var imageItems: [ImageItem] = []
    private var currentConfig: ImageDownloaderConfigProtocol = FastConfig.shared

    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.delegate = self
        table.dataSource = self
        table.register(ImageCell.self, forCellReuseIdentifier: ImageCell.identifier)
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 104
        table.translatesAutoresizingMaskIntoConstraints = false
        table.refreshControl = refreshControl
        return table
    }()

    private lazy var refreshControl: UIRefreshControl = {
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        return refresh
    }()

    private lazy var statsButton: UIBarButtonItem = {
        UIBarButtonItem(
            image: UIImage(systemName: "chart.bar"),
            style: .plain,
            target: self,
            action: #selector(showStats)
        )
    }()

    private lazy var configButton: UIBarButtonItem = {
        UIBarButtonItem(
            title: "Config",
            style: .plain,
            target: self,
            action: #selector(showConfigPicker)
        )
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
    }

    // MARK: - Setup

    private func setupUI() {
        title = "Image Feed"
        view.backgroundColor = .systemBackground

        navigationItem.rightBarButtonItems = [statsButton, configButton]

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadData() {
        imageItems = ImageItem.generateSampleData(count: 50)
        tableView.reloadData()
    }

    // MARK: - Actions

    @objc private func handleRefresh() {
        // Clear cache and reload
        ImageDownloaderManager.shared.clearAllCache()
        loadData()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.refreshControl.endRefreshing()
        }
    }

    @objc private func showStats() {
        let highCacheCount = ImageDownloaderManager.shared.cacheSizeHigh()
        let lowCacheCount = ImageDownloaderManager.shared.cacheSizeLow()
        let storageBytes = ImageDownloaderManager.shared.storageSizeBytes()
        let storageMB = Double(storageBytes) / 1_048_576

        let message = """
        📊 Cache Statistics

        High Priority Cache: \(highCacheCount) images
        Low Priority Cache: \(lowCacheCount) images
        Total Cached: \(highCacheCount + lowCacheCount) images

        Disk Storage: \(String(format: "%.2f", storageMB)) MB
        """

        let alert = UIAlertController(
            title: "Statistics",
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Clear Cache", style: .destructive) { _ in
            ImageDownloaderManager.shared.clearAllCache()
            self.showStats()
        })

        alert.addAction(UIAlertAction(title: "Clear Low Priority", style: .default) { _ in
            ImageDownloaderManager.shared.clearLowPriorityCache()
            self.showStats()
        })

        alert.addAction(UIAlertAction(title: "OK", style: .cancel))

        present(alert, animated: true)
    }

    @objc private func showConfigPicker() {
        let alert = UIAlertController(
            title: "Select Configuration",
            message: "Choose image loading configuration",
            preferredStyle: .actionSheet
        )

        alert.addAction(UIAlertAction(title: "⚡️ Fast Config (Default)", style: .default) { [weak self] _ in
            self?.currentConfig = FastConfig.shared
            self?.tableView.reloadData()
        })

        alert.addAction(UIAlertAction(title: "📶 Offline First", style: .default) { [weak self] _ in
            self?.currentConfig = OfflineFirstConfig.shared
            self?.tableView.reloadData()
        })

        alert.addAction(UIAlertAction(title: "🧠 Low Memory", style: .default) { [weak self] _ in
            self?.currentConfig = LowMemoryConfig.shared
            self?.tableView.reloadData()
        })

        alert.addAction(UIAlertAction(title: "⚙️ Default Config", style: .default) { [weak self] _ in
            self?.currentConfig = DefaultConfig.shared
            self?.tableView.reloadData()
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = configButton
        }

        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension FeedViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return imageItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ImageCell.identifier,
            for: indexPath
        ) as? ImageCell else {
            return UITableViewCell()
        }

        let item = imageItems[indexPath.row]
        cell.configure(with: item, config: currentConfig)

        return cell
    }
}

// MARK: - UITableViewDelegate

extension FeedViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item = imageItems[indexPath.row]
        let detailVC = DetailViewController(item: item, config: currentConfig)
        navigationController?.pushViewController(detailVC, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let clearAction = UIContextualAction(style: .destructive, title: "Clear Cache") { [weak self] _, _, completion in
            let item = self?.imageItems[indexPath.row]
            if let url = item?.url {
                ImageDownloaderManager.shared.clearCache(for: url)
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            completion(true)
        }

        clearAction.image = UIImage(systemName: "trash")

        return UISwipeActionsConfiguration(actions: [clearAction])
    }
}
