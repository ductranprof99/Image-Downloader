//
//  ExampleViewController.m
//  ImageDownloader Objective-C Demo
//
//  Example view controller demonstrating Objective-C usage
//

#import "ExampleViewController.h"
@import ImageDownloader;

@interface ExampleViewController ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIButton *loadButton;
@property (nonatomic, strong) UIButton *clearCacheButton;

@end

@implementation ExampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Objective-C Demo";
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    [self setupUI];
    [self configureImageDownloader];
}

- (void)setupUI {
    // Image view
    self.imageView = [[UIImageView alloc] init];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.backgroundColor = [UIColor systemGray6Color];
    self.imageView.layer.cornerRadius = 12;
    self.imageView.clipsToBounds = YES;
    self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.imageView];

    // Progress view
    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progressView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.progressView];

    // Status label
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.text = @"Ready to load";
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.font = [UIFont systemFontOfSize:14];
    self.statusLabel.textColor = [UIColor secondaryLabelColor];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.statusLabel];

    // Load button
    self.loadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.loadButton setTitle:@"Load Image" forState:UIControlStateNormal];
    [self.loadButton addTarget:self action:@selector(loadImageTapped) forControlEvents:UIControlEventTouchUpInside];
    self.loadButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.loadButton];

    // Clear cache button
    self.clearCacheButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.clearCacheButton setTitle:@"Clear Cache" forState:UIControlStateNormal];
    [self.clearCacheButton setTitleColor:[UIColor systemRedColor] forState:UIControlStateNormal];
    [self.clearCacheButton addTarget:self action:@selector(clearCacheTapped) forControlEvents:UIControlEventTouchUpInside];
    self.clearCacheButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.clearCacheButton];

    // Layout
    [NSLayoutConstraint activateConstraints:@[
        [self.imageView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:20],
        [self.imageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.imageView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [self.imageView.heightAnchor constraintEqualToConstant:300],

        [self.progressView.topAnchor constraintEqualToAnchor:self.imageView.bottomAnchor constant:20],
        [self.progressView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.progressView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],

        [self.statusLabel.topAnchor constraintEqualToAnchor:self.progressView.bottomAnchor constant:12],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],

        [self.loadButton.topAnchor constraintEqualToAnchor:self.statusLabel.bottomAnchor constant:30],
        [self.loadButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],

        [self.clearCacheButton.topAnchor constraintEqualToAnchor:self.loadButton.bottomAnchor constant:12],
        [self.clearCacheButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor]
    ]];
}

- (void)configureImageDownloader {
    // Create custom configuration
    IDConfiguration *config = [[IDConfiguration alloc] init];
    config.maxConcurrentDownloads = 6;
    config.timeout = 30;
    config.allowsCellularAccess = YES;
    config.maxRetries = 3;

    // Apply configuration (if needed for custom manager)
    // For this demo, we'll use the shared instance
}

- (void)loadImageTapped {
    NSURL *imageURL = [NSURL URLWithString:@"https://picsum.photos/600/400"];

    self.statusLabel.text = @"Loading...";
    self.progressView.progress = 0.0;
    self.loadButton.enabled = NO;

    // Method 1: Using UIImageView extension (Recommended)
    [self loadImageUsingUIImageViewExtension:imageURL];

    // Method 2: Using Manager directly
    // [self loadImageUsingManager:imageURL];
}

// MARK: - Loading Methods

/// Recommended: Using UIImageView extension
- (void)loadImageUsingUIImageViewExtension:(NSURL *)url {
    UIImage *placeholder = [UIImage systemImageNamed:@"photo"];

    [self.imageView setImageObjCWith:url
                         placeholder:placeholder
                            priority:ResourcePriorityHigh
                          completion:^(UIImage * _Nullable image, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.loadButton.enabled = YES;

            if (image) {
                self.statusLabel.text = @"✅ Image loaded successfully";
                self.statusLabel.textColor = [UIColor systemGreenColor];
            } else {
                self.statusLabel.text = [NSString stringWithFormat:@"❌ Error: %@", error.localizedDescription];
                self.statusLabel.textColor = [UIColor systemRedColor];
            }
        });
    }];
}

/// Alternative: Using ImageDownloaderManager directly
- (void)loadImageUsingManager:(NSURL *)url {
    ImageDownloaderManager *manager = [ImageDownloaderManager shared];

    __weak typeof(self) weakSelf = self;

    [manager requestImageObjCAt:url
                       priority:ResourcePriorityHigh
                       progress:^(CGFloat progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.progressView.progress = (float)progress;
            weakSelf.statusLabel.text = [NSString stringWithFormat:@"Loading... %.0f%%", progress * 100];
        });
    } completion:^(UIImage * _Nullable image, NSError * _Nullable error, BOOL fromCache, BOOL fromStorage) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.loadButton.enabled = YES;

            if (image) {
                weakSelf.imageView.image = image;

                NSString *source = fromCache ? @"cache" : (fromStorage ? @"storage" : @"network");
                weakSelf.statusLabel.text = [NSString stringWithFormat:@"✅ Loaded from %@", source];
                weakSelf.statusLabel.textColor = [UIColor systemGreenColor];
            } else {
                weakSelf.statusLabel.text = [NSString stringWithFormat:@"❌ Error: %@", error.localizedDescription];
                weakSelf.statusLabel.textColor = [UIColor systemRedColor];
            }
        });
    }];
}

- (void)clearCacheTapped {
    ImageDownloaderManager *manager = [ImageDownloaderManager shared];
    [manager clearAllCache];

    self.imageView.image = nil;
    self.statusLabel.text = @"Cache cleared";
    self.statusLabel.textColor = [UIColor secondaryLabelColor];
    self.progressView.progress = 0.0;
}

// MARK: - Advanced Usage Examples

/// Example: Check if image is cached
- (void)checkIfImageIsCached {
    NSURL *url = [NSURL URLWithString:@"https://example.com/image.jpg"];
    ImageDownloaderManager *manager = [ImageDownloaderManager shared];

    BOOL isCached = [manager isCachedObjCWithUrl:url];
    if (isCached) {
        NSLog(@"Image is cached");
        UIImage *cachedImage = [manager getCachedImageObjCFor:url];
        // Use cached image
    }
}

/// Example: Custom configuration
- (void)useCustomConfiguration {
    // Fast configuration
    IDConfiguration *fastConfig = [IDConfiguration fastConfiguration];

    // Low memory configuration
    IDConfiguration *lowMemConfig = [IDConfiguration lowMemoryConfiguration];

    // Custom configuration
    IDConfiguration *customConfig = [[IDConfiguration alloc] init];
    customConfig.maxConcurrentDownloads = 8;
    customConfig.timeout = 60;
    customConfig.highPriorityLimit = 100;
    customConfig.lowPriorityLimit = 200;

    // Add custom headers
    customConfig.customHeaders = @{
        @"User-Agent": @"MyApp/1.0",
        @"X-API-Key": @"your-api-key"
    };
}

/// Example: JPEG compression
- (void)useJPEGCompression {
    IDJPEGCompressionProvider *jpeg = [[IDJPEGCompressionProvider alloc] initWithQuality:0.8];
    NSLog(@"Using compression: %@", jpeg.name);
}

/// Example: Domain hierarchical storage
- (void)useDomainHierarchicalStorage {
    IDDomainHierarchicalPathProvider *pathProvider = [[IDDomainHierarchicalPathProvider alloc] init];

    NSURL *url = [NSURL URLWithString:@"https://example.com/image.jpg"];
    NSString *path = [pathProvider pathFor:url identifier:@"abc123"];
    NSLog(@"Storage path: %@", path);
}

/// Example: Statistics
- (void)getStatistics {
    ImageDownloaderManager *manager = [ImageDownloaderManager shared];

    NSInteger highCacheCount = [manager cacheSizeHigh];
    NSInteger lowCacheCount = [manager cacheSizeLow];
    NSUInteger storageBytes = [manager storageSizeBytes];
    NSInteger activeDownloads = [manager activeDownloadsCount];

    NSLog(@"Cache: %ld high, %ld low", (long)highCacheCount, (long)lowCacheCount);
    NSLog(@"Storage: %lu bytes", (unsigned long)storageBytes);
    NSLog(@"Active downloads: %ld", (long)activeDownloads);
}

@end
