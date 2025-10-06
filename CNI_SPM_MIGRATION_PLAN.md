# CNI Swift Package Manager Migration Plan

## Overview

This document outlines the plan to isolate the CNI (Custom Network Image) library as a standalone Swift Package, enabling reusability across multiple frameworks (UIKit, SwiftUI, ComponentKit, Objective-C) and supporting independent versioning.

## Why SPM First?

**Benefits:**
- ✅ Forces clean API boundaries and reduces coupling
- ✅ Enables independent versioning and release cycles
- ✅ Simplifies demo app creation (each framework as separate consumer)
- ✅ Improves testability with isolated test targets
- ✅ Supports CocoaPods/Carthage distribution in future
- ✅ Makes protocol-based adapter pattern (Task 1) implementation cleaner

**Timing:**
This should be done **before** implementing CNI_IMPROVEMENT_PLAN tasks, as the SPM structure will influence how we design the protocol adapters and configuration system.

---

## Current CNI Architecture

**Current Location:**
```
CKTest/
└── Helper/
    └── NetworkImage/
        └── CNI/
            ├── Manager/
            │   ├── CNIManager.h
            │   └── CNIManager.m
            ├── CacheAgent/
            │   ├── CNICacheAgent.h
            │   └── CNICacheAgent.m
            ├── NetworkAgent/
            │   ├── CNINetworkAgent.h
            │   └── CNINetworkAgent.m
            ├── StorageAgent/
            │   ├── CNIStorageAgent.h
            │   └── CNIStorageAgent.m
            ├── Observer/
            │   ├── CNIObserver.h
            │   └── CNIObserver.m
            └── Model/
                ├── CNIResourceModel.h
                └── CNIResourceModel.m
```

**Current Dependencies:**
- Foundation.framework
- UIKit.framework (for UIImage)
- No external dependencies

**Current Consumers:**
- `CustomNetworkImageView.h/.mm` (ComponentKit wrapper)
- ComponentKit-based UI components

---

## Proposed SPM Structure

### Repository Structure

```
CNI/
├── Package.swift
├── README.md
├── LICENSE
├── CHANGELOG.md
│
├── Sources/
│   ├── CNI/                          # Core library (framework-agnostic)
│   │   ├── Manager/
│   │   │   ├── CNIManager.h
│   │   │   └── CNIManager.m
│   │   ├── CacheAgent/
│   │   │   ├── CNICacheAgent.h
│   │   │   └── CNICacheAgent.m
│   │   ├── NetworkAgent/
│   │   │   ├── CNINetworkAgent.h
│   │   │   └── CNINetworkAgent.m
│   │   ├── StorageAgent/
│   │   │   ├── CNIStorageAgent.h
│   │   │   └── CNIStorageAgent.m
│   │   ├── Observer/
│   │   │   ├── CNIObserver.h
│   │   │   └── CNIObserver.m
│   │   ├── Model/
│   │   │   ├── CNIResourceModel.h
│   │   │   └── CNIResourceModel.m
│   │   └── include/
│   │       └── CNI.h                 # Umbrella header
│   │
│   ├── CNIUIKit/                     # UIKit adapter
│   │   ├── CNIImageView.h
│   │   ├── CNIImageView.m
│   │   └── UIImageView+CNI.h/.m
│   │
│   ├── CNIComponentKit/              # ComponentKit adapter
│   │   ├── CustomNetworkImageView.h
│   │   └── CustomNetworkImageView.mm
│   │
│   └── CNISwiftUI/                   # SwiftUI adapter (future)
│       └── CNIAsyncImage.swift
│
├── Tests/
│   ├── CNITests/                     # Core tests
│   │   ├── CNIManagerTests.m
│   │   ├── CNICacheAgentTests.m
│   │   └── CNINetworkAgentTests.m
│   └── CNIUIKitTests/                # Adapter tests
│       └── CNIImageViewTests.m
│
└── Examples/                         # Demo apps (separate from package)
    ├── CNI-UIKit-Demo/
    ├── CNI-SwiftUI-Demo/
    ├── CNI-ComponentKit-Demo/
    └── CNI-ObjC-Demo/
```

---

## Package.swift Manifest

### Multi-Target Configuration

```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
  name: "CNI",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15)
  ],
  products: [
    // Core library (framework-agnostic)
    .library(
      name: "CNI",
      targets: ["CNI"]
    ),
    // UIKit adapter
    .library(
      name: "CNIUIKit",
      targets: ["CNIUIKit"]
    ),
    // ComponentKit adapter
    .library(
      name: "CNIComponentKit",
      targets: ["CNIComponentKit"]
    ),
    // SwiftUI adapter (future)
    .library(
      name: "CNISwiftUI",
      targets: ["CNISwiftUI"]
    )
  ],
  dependencies: [
    // ComponentKit dependency for CNIComponentKit target
    // Note: ComponentKit doesn't have official SPM support yet
    // May need to use local package or fork
  ],
  targets: [
    // Core CNI library (Objective-C)
    .target(
      name: "CNI",
      dependencies: [],
      path: "Sources/CNI",
      publicHeadersPath: "include",
      cSettings: [
        .headerSearchPath("."),
      ]
    ),

    // UIKit adapter
    .target(
      name: "CNIUIKit",
      dependencies: ["CNI"],
      path: "Sources/CNIUIKit"
    ),

    // ComponentKit adapter
    .target(
      name: "CNIComponentKit",
      dependencies: ["CNI"],
      path: "Sources/CNIComponentKit",
      cxxSettings: [
        .headerSearchPath("."),
      ]
    ),

    // SwiftUI adapter
    .target(
      name: "CNISwiftUI",
      dependencies: ["CNI"],
      path: "Sources/CNISwiftUI"
    ),

    // Tests
    .testTarget(
      name: "CNITests",
      dependencies: ["CNI"],
      path: "Tests/CNITests"
    ),
    .testTarget(
      name: "CNIUIKitTests",
      dependencies: ["CNIUIKit"],
      path: "Tests/CNIUIKitTests"
    )
  ],
  cLanguageStandard: .c11,
  cxxLanguageStandard: .cxx17
)
```

---

## Migration Steps

### Phase 1: Create SPM Package Structure (Week 1)

**Step 1.1: Initialize Package Repository**
```bash
mkdir CNI
cd CNI
swift package init --type library
git init
```

**Step 1.2: Organize Directory Structure**
- Create `Sources/CNI/` directory
- Create subdirectories: Manager, CacheAgent, NetworkAgent, StorageAgent, Observer, Model
- Create `Sources/CNI/include/` for public headers
- Create adapter directories: `Sources/CNIUIKit/`, `Sources/CNIComponentKit/`

**Step 1.3: Copy Core CNI Files**
```bash
# Copy from component-kit project to CNI package
cp -r CKTest/Helper/NetworkImage/CNI/Manager/* CNI/Sources/CNI/Manager/
cp -r CKTest/Helper/NetworkImage/CNI/CacheAgent/* CNI/Sources/CNI/CacheAgent/
cp -r CKTest/Helper/NetworkImage/CNI/NetworkAgent/* CNI/Sources/CNI/NetworkAgent/
cp -r CKTest/Helper/NetworkImage/CNI/StorageAgent/* CNI/Sources/CNI/StorageAgent/
cp -r CKTest/Helper/NetworkImage/CNI/Observer/* CNI/Sources/CNI/Observer/
cp -r CKTest/Helper/NetworkImage/CNI/Model/* CNI/Sources/CNI/Model/
```

**Step 1.4: Create Umbrella Header**
Create `Sources/CNI/include/CNI.h`:
```objc
//
//  CNI.h
//  CNI - Custom Network Image Library
//

#import <Foundation/Foundation.h>

// Manager
#import "CNIManager.h"

// Agents
#import "CNICacheAgent.h"
#import "CNINetworkAgent.h"
#import "CNIStorageAgent.h"

// Observer
#import "CNIObserver.h"

// Models
#import "CNIResourceModel.h"
```

**Step 1.5: Update Import Paths**
- Change all imports from `#import "CNIManager.h"` to `#import <CNI/CNIManager.h>`
- Ensure all headers use angle brackets for framework-style imports

**Step 1.6: Create Package.swift**
- Use manifest design from above
- Configure targets for CNI core and adapters

### Phase 2: Extract Adapters (Week 1-2)

**Step 2.1: Move ComponentKit Adapter**
```bash
cp CKTest/Helper/NetworkImage/CustomNetworkImageView.h CNI/Sources/CNIComponentKit/
cp CKTest/Helper/NetworkImage/CustomNetworkImageView.mm CNI/Sources/CNIComponentKit/
```

**Step 2.2: Update CustomNetworkImageView Imports**
```objc
// Old
#import "CNIManager.h"

// New
#import <CNI/CNIManager.h>
```

**Step 2.3: Create UIKit Adapter (New)**
Create `Sources/CNIUIKit/CNIImageView.h`:
```objc
//
//  CNIImageView.h
//  CNIUIKit - UIKit adapter for CNI
//

#import <UIKit/UIKit.h>
#import <CNI/CNI.h>

NS_ASSUME_NONNULL_BEGIN

@interface CNIImageView : UIImageView

@property (nonatomic, copy, nullable) NSURL *imageURL;
@property (nonatomic, strong, nullable) UIImage *placeholderImage;
@property (nonatomic, assign) CNIResourcePriority priority;
@property (nonatomic, assign) BOOL shouldSaveToStorage;

- (void)loadImageFromURL:(NSURL *)URL;
- (void)loadImageFromURL:(NSURL *)URL
            placeholder:(nullable UIImage *)placeholder;
- (void)cancelLoading;

@end

NS_ASSUME_NONNULL_END
```

**Step 2.4: Create UIImageView Category (Convenience)**
Create `Sources/CNIUIKit/UIImageView+CNI.h`:
```objc
//
//  UIImageView+CNI.h
//  CNIUIKit
//

#import <UIKit/UIKit.h>
#import <CNI/CNI.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImageView (CNI)

- (void)cni_setImageWithURL:(NSURL *)URL;
- (void)cni_setImageWithURL:(NSURL *)URL
               placeholder:(nullable UIImage *)placeholder;
- (void)cni_setImageWithURL:(NSURL *)URL
               placeholder:(nullable UIImage *)placeholder
                  priority:(CNIResourcePriority)priority;

@end

NS_ASSUME_NONNULL_END
```

### Phase 3: Update component-kit Project (Week 2)

**Step 3.1: Add CNI as Local SPM Dependency**

In Xcode for `component-kit` project:
1. File → Add Packages
2. Select "Add Local..."
3. Choose CNI package directory
4. Select targets: `CNI`, `CNIComponentKit`

**Step 3.2: Update component-kit Imports**

In `component-kit` project files that use CNI:
```objc
// Old
#import "CustomNetworkImageView.h"
#import "CNIManager.h"

// New
#import <CNIComponentKit/CustomNetworkImageView.h>
#import <CNI/CNIManager.h>
```

**Step 3.3: Remove Old CNI Files**

Delete from `component-kit` project:
```
CKTest/Helper/NetworkImage/CNI/          # Delete entire directory
CKTest/Helper/NetworkImage/CustomNetworkImageView.h/.mm  # Now from SPM
```

**Step 3.4: Test Integration**
- Build component-kit project
- Run existing ComponentKit-based UI tests
- Verify image loading works as before

### Phase 4: Create Demo Apps (Week 3)

**Step 4.1: UIKit Demo App**
```bash
cd Examples
mkdir CNI-UIKit-Demo
cd CNI-UIKit-Demo
# Create new Xcode project (iOS App, UIKit)
```

Add CNI package dependency:
- Select CNIUIKit target
- Demonstrate basic image loading with CNIImageView
- Show configuration options

**Step 4.2: ComponentKit Demo App**
```bash
cd Examples
mkdir CNI-ComponentKit-Demo
# Copy minimal ComponentKit setup from component-kit project
```

Add CNI package dependency:
- Select CNIComponentKit target
- Demonstrate CustomNetworkImageView in ComponentKit hierarchy
- Show different image types and priorities

**Step 4.3: Objective-C Demo App**
```bash
cd Examples
mkdir CNI-ObjC-Demo
# Create new Xcode project (iOS App, Storyboard, Objective-C)
```

Add CNI package dependency:
- Use both CNI core directly and CNIUIKit adapter
- Demonstrate manual CNIManager usage
- Show UIImageView category usage

**Step 4.4: SwiftUI Demo App (Placeholder)**
```bash
cd Examples
mkdir CNI-SwiftUI-Demo
# Create new Xcode project (iOS App, SwiftUI)
```

Add CNI package dependency:
- Create basic CNIAsyncImage wrapper (placeholder)
- Document future implementation needs

---

## Backward Compatibility Strategy

### For Existing component-kit Project

**Option 1: Direct SPM Migration (Recommended)**
- Update all imports to framework-style
- Use local SPM package during development
- Publish CNI to GitHub when stable

**Option 2: Dual Support Period**
- Keep old CNI files temporarily
- Use `#if` preprocessor to support both import styles
- Gradually migrate over 2-3 sprints

### For Future Projects

New projects will:
```swift
// In Package.swift
dependencies: [
  .package(url: "https://github.com/yourorg/CNI.git", from: "1.0.0")
]
```

And import:
```objc
#import <CNI/CNI.h>
#import <CNIUIKit/CNIImageView.h>
```

---

## Testing Strategy

### Core CNI Tests

**CNIManagerTests.m:**
- Test singleton access
- Test request queuing
- Test priority handling
- Test observer notifications

**CNICacheAgentTests.m:**
- Test two-tier caching
- Test memory pressure handling
- Test cache invalidation

**CNINetworkAgentTests.m:**
- Test concurrent download limits
- Test download cancellation
- Test progress callbacks
- Test error handling

### Adapter Tests

**CNIUIKitTests:**
- Test CNIImageView loading
- Test placeholder handling
- Test category methods

**CNIComponentKitTests:**
- Test CustomNetworkImageView integration
- Test attribute updates
- Test view reuse

### Integration Tests

**Demo App Tests:**
- Each demo app should have UI tests
- Test image loading in real scenarios
- Test memory usage under stress

---

## Release Strategy

### Version 1.0.0 (Initial SPM Release)

**Includes:**
- ✅ Core CNI library (stable API from current implementation)
- ✅ CNIUIKit adapter (new)
- ✅ CNIComponentKit adapter (migrated)
- ✅ Basic tests
- ✅ README with installation instructions
- ✅ Demo apps for UIKit, ComponentKit, Objective-C

**Does NOT include (future versions):**
- ❌ Protocol-based adapter system (v1.1.0)
- ❌ Configuration inheritance (v1.1.0)
- ❌ Network improvements (v1.2.0+)
- ❌ SwiftUI adapter (v1.3.0)

### Version 1.1.0 (Improved Architecture)

Implement CNI_IMPROVEMENT_PLAN Task 1 & 2:
- Protocol-based multi-framework adapter
- Configuration inheritance system

### Version 1.2.0+ (Network Enhancements)

Implement CNI_IMPROVEMENT_PLAN Task 3:
- Retry mechanism
- Request deduplication
- Custom headers/authentication
- Progressive loading
- WebP/AVIF support

---

## ComponentKit SPM Dependency Challenge

**Issue:**
ComponentKit does not have official Swift Package Manager support.

**Solutions:**

**Option 1: Local ComponentKit Package (Recommended for Demo)**
```bash
# Create local ComponentKit SPM wrapper
mkdir ComponentKit-SPM
cd ComponentKit-SPM
# Copy ComponentKit source
# Create Package.swift manifest
```

Then in CNI Package.swift:
```swift
dependencies: [
  .package(path: "../ComponentKit-SPM")
]
```

**Option 2: Git Submodule + Manual Linking**
- Add ComponentKit as git submodule
- Use `.binaryTarget` in Package.swift
- Manually link ComponentKit framework

**Option 3: CNIComponentKit as Optional**
- Mark CNIComponentKit target as optional
- Only build if ComponentKit is available
- Document manual setup steps

**For component-kit Project:**
Continue using CocoaPods/manual ComponentKit integration. CNI package only provides the adapter source.

---

## File Mapping Reference

### Current → SPM Package

| Current Location | SPM Location |
|-----------------|--------------|
| `CKTest/Helper/NetworkImage/CNI/Manager/CNIManager.h` | `Sources/CNI/Manager/CNIManager.h` |
| `CKTest/Helper/NetworkImage/CNI/CacheAgent/CNICacheAgent.h` | `Sources/CNI/CacheAgent/CNICacheAgent.h` |
| `CKTest/Helper/NetworkImage/CNI/NetworkAgent/CNINetworkAgent.h` | `Sources/CNI/NetworkAgent/CNINetworkAgent.h` |
| `CKTest/Helper/NetworkImage/CNI/StorageAgent/CNIStorageAgent.h` | `Sources/CNI/StorageAgent/CNIStorageAgent.h` |
| `CKTest/Helper/NetworkImage/CNI/Observer/CNIObserver.h` | `Sources/CNI/Observer/CNIObserver.h` |
| `CKTest/Helper/NetworkImage/CNI/Model/CNIResourceModel.h` | `Sources/CNI/Model/CNIResourceModel.h` |
| `CKTest/Helper/NetworkImage/CustomNetworkImageView.h` | `Sources/CNIComponentKit/CustomNetworkImageView.h` |

### New Files Created

| SPM Location | Purpose |
|--------------|---------|
| `Sources/CNI/include/CNI.h` | Umbrella header |
| `Sources/CNIUIKit/CNIImageView.h/.m` | UIKit adapter |
| `Sources/CNIUIKit/UIImageView+CNI.h/.m` | Convenience category |
| `Sources/CNISwiftUI/CNIAsyncImage.swift` | SwiftUI adapter (future) |
| `Tests/CNITests/*.m` | Unit tests |
| `Examples/CNI-UIKit-Demo/` | UIKit demo app |
| `Examples/CNI-ComponentKit-Demo/` | ComponentKit demo app |
| `Examples/CNI-ObjC-Demo/` | Objective-C demo app |

---

## Timeline Summary

| Phase | Duration | Deliverables |
|-------|----------|--------------|
| Phase 1: SPM Setup | Week 1 | Package structure, core CNI migrated, Package.swift |
| Phase 2: Adapters | Week 1-2 | CNIComponentKit migrated, CNIUIKit created |
| Phase 3: Integration | Week 2 | component-kit project updated, old files removed |
| Phase 4: Demo Apps | Week 3 | UIKit/ComponentKit/ObjC demos working |
| **Total** | **3 weeks** | **CNI v1.0.0 ready** |

After SPM migration, implement CNI_IMPROVEMENT_PLAN tasks in subsequent releases.

---

## Next Steps

1. **Review this plan** - Approve SPM structure and migration approach
2. **Create CNI repository** - Initialize git repo, add README/LICENSE
3. **Execute Phase 1** - Set up package structure and migrate core files
4. **Test integration** - Verify component-kit project works with SPM CNI
5. **Build demos** - Create showcase apps for each framework
6. **Implement improvements** - Follow CNI_IMPROVEMENT_PLAN.md with new SPM structure

## Questions to Resolve

1. **Repository hosting:** GitHub public/private? Organization account?
2. **Versioning scheme:** Semantic versioning 1.0.0? Include pre-releases (0.9.0-beta)?
3. **ComponentKit dependency:** How to handle in SPM? Use local package wrapper?
4. **License:** MIT? Apache 2.0? Proprietary?
5. **CI/CD:** GitHub Actions for automated testing?

---

**Document Version:** 1.0
**Created:** 2025-10-05
**Author:** CNI Development Team
