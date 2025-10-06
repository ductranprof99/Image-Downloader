//
//  ImageCell.swift
//  UIKitDemo
//
//  Custom table view cell with progress tracking
//

import UIKit
import ImageDownloader
import ImageDownloaderUI

class ImageCell: UITableViewCell {
    static let identifier = "ImageCell"

    // MARK: - UI Components

    private let photoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray6
        imageView.layer.cornerRadius = 8
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .tertiaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.progressTintColor = .systemBlue
        progress.trackTintColor = .systemGray5
        return progress
    }()

    private let percentageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .systemBlue
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        contentView.addSubview(photoImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(statusLabel)
        contentView.addSubview(progressView)
        contentView.addSubview(percentageLabel)

        NSLayoutConstraint.activate([
            // Image view
            photoImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            photoImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            photoImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            photoImageView.widthAnchor.constraint(equalToConstant: 80),
            photoImageView.heightAnchor.constraint(equalToConstant: 80),

            // Title label
            titleLabel.leadingAnchor.constraint(equalTo: photoImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: photoImageView.topAnchor),

            // Subtitle label
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),

            // Status label
            statusLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            statusLabel.bottomAnchor.constraint(equalTo: photoImageView.bottomAnchor),

            // Progress view
            progressView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: percentageLabel.leadingAnchor, constant: -8),
            progressView.bottomAnchor.constraint(equalTo: statusLabel.topAnchor, constant: -8),

            // Percentage label
            percentageLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            percentageLabel.centerYAnchor.constraint(equalTo: progressView.centerYAnchor),
            percentageLabel.widthAnchor.constraint(equalToConstant: 50)
        ])
    }

    // MARK: - Configuration

    func configure(with item: ImageItem, config: ImageDownloaderConfigProtocol) {
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        statusLabel.text = "⏳ Loading..."
        progressView.progress = 0
        progressView.isHidden = false
        percentageLabel.isHidden = false
        percentageLabel.text = "0%"

        // Load image with progress tracking
        photoImageView.setImage(
            with: item.url,
            config: config,
            placeholder: UIImage(systemName: "photo.fill"),
            priority: item.imageType == .avatar ? .high : .low,
            onProgress: { [weak self] progress in
                DispatchQueue.main.async {
                    self?.progressView.progress = Float(progress)
                    self?.percentageLabel.text = "\(Int(progress * 100))%"

                    if progress >= 1.0 {
                        self?.progressView.isHidden = true
                        self?.percentageLabel.isHidden = true
                    }
                }
            },
            onCompletion: { [weak self] image, error, fromCache, fromStorage in
                DispatchQueue.main.async {
                    self?.progressView.isHidden = true
                    self?.percentageLabel.isHidden = true

                    if let error = error {
                        self?.statusLabel.text = "❌ Error: \(error.localizedDescription)"
                    } else if fromCache {
                        self?.statusLabel.text = "✅ From memory cache"
                    } else if fromStorage {
                        self?.statusLabel.text = "💾 From disk storage"
                    } else {
                        self?.statusLabel.text = "🌐 Downloaded from network"
                    }
                }
            }
        )
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        photoImageView.cancelImageLoading()
        photoImageView.image = nil
        titleLabel.text = nil
        subtitleLabel.text = nil
        statusLabel.text = nil
        progressView.progress = 0
        progressView.isHidden = true
        percentageLabel.isHidden = true
        percentageLabel.text = "0%"
    }
}
