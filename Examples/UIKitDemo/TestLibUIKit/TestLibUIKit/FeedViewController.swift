//
//  FeedViewController.swift
//  UIKitDemo
//
//  Main feed view controller demonstrating ImageDownloader
//

import UIKit
import ImageDownloader

class FeedViewController: UIViewController {

    // MARK: - Properties

    private var imageItems: [ImageItem] = []
    private var currentConfig: IDConfiguration = .fast

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

    private lazy var clearButton: UIBarButtonItem = {
        let menu = UIMenu(title: "", children: [
            UIAction(title: "Clear Memory Cache", image: UIImage(systemName: "memorychip"), handler: { [weak self] _ in
                self?.clearMemoryCache()
            }),
            UIAction(title: "Clear Disk Storage", image: UIImage(systemName: "internaldrive"), handler: { [weak self] _ in
                self?.clearDiskStorage()
            }),
            UIAction(title: "Clear Everything", image: UIImage(systemName: "trash"), attributes: .destructive, handler: { [weak self] _ in
                self?.clearEverything()
            })
        ])
        
        let button = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            menu: menu
        )
        return button
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
    
    private lazy var floatingButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .systemBlue
        button.tintColor = .white
        button.layer.cornerRadius = 28
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.25
        
        // Create a configuration for the button
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "internaldrive")
        config.imagePadding = 8
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        button.configuration = config
        
        button.addTarget(self, action: #selector(floatingButtonTapped), for: .touchUpInside)
        return button
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

        navigationItem.rightBarButtonItems = [clearButton, statsButton, configButton]

        view.addSubview(tableView)
        view.addSubview(floatingButton)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            floatingButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            floatingButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            floatingButton.widthAnchor.constraint(equalToConstant: 56),
            floatingButton.heightAnchor.constraint(equalToConstant: 56)
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

    private func clearMemoryCache() {
        ImageDownloaderManager.shared.clearAllCache()
        showToast(message: "Memory cache cleared")
        tableView.reloadData()
    }

    private func clearDiskStorage() {
        ImageDownloaderManager.shared.clearStorage { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    self?.showToast(message: "Disk storage cleared")
                    self?.tableView.reloadData()
                } else {
                    self?.showToast(message: "Failed to clear disk storage", isError: true)
                }
            }
        }
    }

    private func clearEverything() {
        ImageDownloaderManager.shared.hardReset()
        showToast(message: "All caches cleared")
        tableView.reloadData()
    }
    
    @objc private func floatingButtonTapped() {
        // Add a small scale animation
        UIView.animate(withDuration: 0.1, animations: {
            self.floatingButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.floatingButton.transform = .identity
            }
        }
        
        // Call clear disk storage
        clearDiskStorage()
    }

    private func showToast(message: String, isError: Bool = false) {
        let toast = UILabel()
        toast.text = message
        toast.textAlignment = .center
        toast.font = .systemFont(ofSize: 14, weight: .medium)
        toast.textColor = .white
        toast.backgroundColor = isError ? .systemRed : .systemGreen
        toast.alpha = 0
        toast.layer.cornerRadius = 10
        toast.clipsToBounds = true
        toast.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(toast)
        
        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            toast.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -40),
            toast.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
            toast.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 1.5, options: .curveEaseOut, animations: {
                toast.alpha = 0
            }) { _ in
                toast.removeFromSuperview()
            }
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
            self?.currentConfig = .fast
            self?.tableView.reloadData()
        })

        alert.addAction(UIAlertAction(title: "📶 Offline First", style: .default) { [weak self] _ in
            self?.currentConfig = .offlineFirst
            self?.tableView.reloadData()
        })

        alert.addAction(UIAlertAction(title: "🧠 Low Memory", style: .default) { [weak self] _ in
            self?.currentConfig = .lowMemory
            self?.tableView.reloadData()
        })

        alert.addAction(UIAlertAction(title: "⚙️ Default Config", style: .default) { [weak self] _ in
            self?.currentConfig = .default
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
                ImageDownloaderManager.shared.clearAllCache()
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            completion(true)
        }

        clearAction.image = UIImage(systemName: "trash")

        return UISwipeActionsConfiguration(actions: [clearAction])
    }
}
