//
//  DetailViewController.swift
//  UIKitDemo
//
//  Detail view with large image and progress tracking
//

import UIKit
import ImageDownloader

class DetailViewController: UIViewController {

    // MARK: - Properties

    private let item: ImageItem
    private let config: IDConfiguration

    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.minimumZoomScale = 1.0
        scroll.maximumZoomScale = 4.0
        return scroll
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .systemBackground
        return imageView
    }()

    private let progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .bar)
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.progressTintColor = .systemBlue
        return progress
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let infoStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - Initialization

    init(item: ImageItem, config: IDConfiguration) {
        self.item = item
        self.config = config
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadImage()
    }

    // MARK: - Setup

    private func setupUI() {
        title = item.title
        view.backgroundColor = .systemBackground

        scrollView.delegate = self

        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        view.addSubview(infoStackView)

        infoStackView.addArrangedSubview(progressView)
        infoStackView.addArrangedSubview(statusLabel)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: infoStackView.topAnchor, constant: -16),

            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),

            infoStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            infoStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            infoStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),

            progressView.heightAnchor.constraint(equalToConstant: 4),
            progressView.widthAnchor.constraint(equalTo: infoStackView.widthAnchor)
        ])
    }

    private func loadImage() {
        statusLabel.text = "Loading..."
        progressView.progress = 0
        progressView.isHidden = false

        imageView.setImage(
            with: item.url,
            config: config,
            placeholder: UIImage(systemName: "photo.fill"),
            priority: .high,
            onProgress: { [weak self] progress in
                DispatchQueue.main.async {
                    self?.progressView.progress = Float(progress)
                    self?.statusLabel.text = "Loading \(Int(progress * 100))%"
                }
            },
            onCompletion: { [weak self] image, error, fromCache, fromStorage in
                DispatchQueue.main.async {
                    self?.progressView.isHidden = true

                    if let error = error {
                        self?.statusLabel.text = "Error: \(error.localizedDescription)"
                    } else if fromCache {
                        self?.statusLabel.text = "✅ Loaded from memory cache"
                    } else if fromStorage {
                        self?.statusLabel.text = "💾 Loaded from disk storage"
                    } else {
                        self?.statusLabel.text = "🌐 Downloaded from network"
                    }

                    if let image = image {
                        let size = image.size
                        let sizeText = "\(Int(size.width))×\(Int(size.height))"
                        self?.statusLabel.text = (self?.statusLabel.text ?? "") + " - \(sizeText)"
                    }
                }
            }
        )
    }
}

// MARK: - UIScrollViewDelegate

extension DetailViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}
