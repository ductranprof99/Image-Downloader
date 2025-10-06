# CNI Project Context

## What is CNI?

**CNI (Custom Network Image)** is a production-ready iOS image loading library extracted from the `component-kit` project. It provides advanced caching, storage, and multi-framework support.

## Project Status

✅ **Phase 1 Complete - SPM Package Created**

The CNI library has been successfully isolated as a Swift Package Manager (SPM) package with the following structure:

```
CNI/
├── Package.swift                  # Multi-target SPM configuration
├── README.md                      # Full documentation
├── LICENSE                        # MIT License
├── CNI_SPM_MIGRATION_PLAN.md      # Migration plan documentation
├── CNI_IMPROVEMENT_PLAN.md        # Future improvements roadmap
├── PROJECT_CONTEXT.md             # This file
│
├── Sources/
│   ├── CNI/                       # Core library (framework-agnostic)
│   │   ├── Manager/               # CNIManager (coordinator)
│   │   ├── CacheAgent/            # Two-tier memory cache
│   │   ├── NetworkAgent/          # Download queue with concurrency control
│   │   ├── StorageAgent/          # Disk persistence
│   │   ├── Observer/              # Event notification system
│   │   ├── Model/                 # CNIResourceModel
│   │   └── include/CNI.h          # Umbrella header
│   │
│   ├── CNIUIKit/                  # UIKit adapter
│   │   ├── CNIImageView.h/.m      # UIImageView subclass with CNI
│   │   └── UIImageView+CNI.h/.m   # Convenience category
│   │
│   └── CNIComponentKit/           # ComponentKit adapter
│       ├── CustomNetworkImageView.h/.mm
│       └── ComponentImageDownloader.h/.mm
│
└── Tests/
    └── CNITests/                  # Unit tests (to be created)
```

## What We've Done

### 1. SPM Package Structure ✅
- Initialized Swift Package with `swift package init`
- Created multi-target `Package.swift`:
  - `CNI` (core library)
  - `CNIUIKit` (UIKit adapter)
  - `CNIComponentKit` (ComponentKit adapter)

### 2. Core CNI Migration ✅
- Copied all CNI source files from `component-kit/CKTest/Helper/NetworkImage/CNI/`
- Updated all imports to framework-style (`#import <CNI/CNIManager.h>`)
- Created umbrella header `CNI.h`
- All core files use consistent import style

### 3. Adapters Created ✅

**CNIUIKit:**
- `CNIImageView` - UIImageView subclass with built-in CNI loading
- `UIImageView+CNI` - Category for adding CNI to any UIImageView

**CNIComponentKit:**
- Migrated `CustomNetworkImageView` from component-kit
- Migrated `ComponentImageDownloader` bridge

### 4. Documentation ✅
- `README.md` - Complete API documentation with examples
- `LICENSE` - MIT License
- `CNI_SPM_MIGRATION_PLAN.md` - Detailed migration plan
- `CNI_IMPROVEMENT_PLAN.md` - Roadmap for v1.1+

### 5. Git Repository ✅
- Initialized git repo
- Initial commit with all files

## What's Next

### Immediate Next Steps

**Phase 2: Integrate with component-kit Project**

1. **Add CNI as Local SPM Dependency (Manual in Xcode)**
   - Open component-kit project in Xcode
   - Add local package from `/Users/macbook/Documents/Personal Work/CNI`
   - Select `CNI` and `CNIComponentKit` targets

2. **Update Imports in component-kit**
   - Change `#import "CustomNetworkImageView.h"` → `#import <CNIComponentKit/CustomNetworkImageView.h>`
   - Change `#import "CNIManager.h"` → `#import <CNI/CNIManager.h>`

3. **Remove Old CNI Files from component-kit**
   - Delete `CKTest/Helper/NetworkImage/CNI/` folder
   - Delete old `CustomNetworkImageView.h/.mm`
   - Delete old `ComponentImageDownloader.h/.mm`

4. **Test Integration**
   - Build component-kit project
   - Verify image loading works
   - Verify no crashes

See: `/Users/macbook/Documents/Personal Work/component-kit/CNI_INTEGRATION_GUIDE.md`

### Future Phases

**Phase 3: Demo Apps**
- Create `Examples/CNI-UIKit-Demo/`
- Create `Examples/CNI-ComponentKit-Demo/`
- Create `Examples/CNI-ObjC-Demo/`
- Showcase all CNI features

**Phase 4: Improvements (v1.1.0+)**

See `CNI_IMPROVEMENT_PLAN.md` for full details:

1. **Task 1: Protocol-Based Multi-Framework Adapter**
   - Design `CNIImageViewProtocol`
   - Create adapters for UIKit, SwiftUI, ComponentKit
   - Decouple core from framework-specific code

2. **Task 2: Configuration Inheritance System**
   - Global defaults
   - Per-request overrides
   - Runtime overrides
   - Builder pattern for easy configuration

3. **Task 3: Network Layer Improvements**
   - Retry mechanism with exponential backoff
   - Request deduplication
   - Custom headers/authentication
   - Bandwidth throttling
   - Progressive image loading
   - WebP/AVIF format support
   - Request interceptor pattern
   - Network reachability monitoring

## Architecture Overview

### Core Components

**CNIManager** (Coordinator)
- Singleton managing all CNI operations
- Coordinates between CacheAgent, StorageAgent, NetworkAgent
- Manages observer notifications
- Main public API

**CNICacheAgent** (Two-Tier Memory Cache)
- High priority cache (50 images default)
- Low priority cache (100 images default)
- Automatic eviction under memory pressure
- Thread-safe operations

**CNINetworkAgent** (Download Manager)
- Concurrent download queue (4 concurrent max default)
- Priority-based queuing
- Progress tracking
- Cancellation support

**CNIStorageAgent** (Disk Persistence)
- Saves images to Documents directory
- MD5-based file naming
- Async read/write operations
- Storage size tracking

**CNIObserver** (Event System)
- Observer pattern for global notifications
- Events: didStartLoading, didFinishLoading, didFailLoading
- Multiple observers supported

**CNIResourceModel** (State Management)
- Tracks resource state (pending, loading, cached, failed)
- MD5 identifier for URLs
- Priority management

### Adapter Pattern

```
User Code
    ↓
Adapter (UIKit/ComponentKit/SwiftUI)
    ↓
CNI Core (Framework-agnostic)
    ↓
CNIManager → CacheAgent/NetworkAgent/StorageAgent
```

## Current Limitations (To Be Fixed)

From `CNI_IMPROVEMENT_PLAN.md`:

**Good Sides:**
1. ✅ Clean layered architecture
2. ✅ Two-tier caching strategy
3. ✅ Observer pattern for event notifications
4. ✅ Priority-based download queue
5. ✅ Persistent storage support
6. ✅ Progress tracking
7. ✅ Thread-safe operations
8. ✅ MD5-based resource identification
9. ✅ Memory pressure handling
10. ✅ Request cancellation support

**Bad Sides (To Fix):**
1. ❌ Framework coupling (CustomNetworkImageView in core)
2. ❌ No retry mechanism
3. ❌ Request duplication (same URL multiple times)
4. ❌ Inflexible configuration (global only)
5. ❌ No custom headers/authentication
6. ❌ No bandwidth throttling
7. ❌ No progressive loading
8. ❌ Limited image formats (no WebP/AVIF)
9. ❌ No request interception
10. ❌ No network reachability monitoring
11. ❌ Singleton anti-pattern
12. ❌ No SwiftUI support
13. ❌ No error recovery strategies
14. ❌ Limited statistics/analytics
15. ❌ No unit tests

## Development Workflow

### When Working on CNI Package

1. **Open CNI in Xcode/VSCode:**
   ```bash
   cd "/Users/macbook/Documents/Personal Work/CNI"
   code .
   ```

2. **Make changes to source files**

3. **Test changes:**
   - Build package: `swift build`
   - Run tests: `swift test` (when tests exist)

4. **Commit changes:**
   ```bash
   git add .
   git commit -m "Description of changes"
   ```

### When Integrating Changes to component-kit

1. **component-kit will automatically pick up changes** (using local package)
2. **Build component-kit project** to verify
3. **If issues, check:**
   - Import statements are correct
   - Package is properly linked in Xcode
   - CNI package builds successfully

## File Organization

### CNI Package Files

**Package Configuration:**
- `Package.swift` - SPM manifest with multi-target configuration
- `.gitignore` - Excludes build artifacts

**Documentation:**
- `README.md` - Public API documentation
- `LICENSE` - MIT License
- `CNI_SPM_MIGRATION_PLAN.md` - How we migrated to SPM
- `CNI_IMPROVEMENT_PLAN.md` - Future improvements
- `PROJECT_CONTEXT.md` - This file (project overview)

**Source Code:**
- `Sources/CNI/` - Core library (10 files)
- `Sources/CNIUIKit/` - UIKit adapter (4 files)
- `Sources/CNIComponentKit/` - ComponentKit adapter (4 files)

**Tests:**
- `Tests/CNITests/` - Unit tests (to be created)

## Key Design Decisions

### 1. Swift Package Manager (SPM)
**Why:** Standard package manager for Swift/iOS, enables multi-framework support, forces clean boundaries

**Benefits:**
- Reusable across projects
- Independent versioning
- Clean dependency management
- Forces good architecture

### 2. Multi-Target Structure
**Why:** Separates core logic from framework-specific adapters

**Benefits:**
- Core library is framework-agnostic
- UIKit users only import CNIUIKit
- ComponentKit users only import CNIComponentKit
- Easy to add SwiftUI adapter later

### 3. Framework-Style Imports
**Why:** Required for SPM packages, clearer module boundaries

**Before:**
```objc
#import "CNIManager.h"
```

**After:**
```objc
#import <CNI/CNIManager.h>
```

### 4. Adapter Pattern
**Why:** Decouples core CNI from UI frameworks

**Benefits:**
- Same core works with UIKit, ComponentKit, SwiftUI
- Easy to test core independently
- Clear separation of concerns

## Important Files to Reference

When working on CNI, frequently reference:

1. **README.md** - Public API and usage examples
2. **CNI_IMPROVEMENT_PLAN.md** - What to build next
3. **CNI_SPM_MIGRATION_PLAN.md** - How we got here
4. **Package.swift** - Target configuration

## Common Tasks

### Add New Feature to Core

1. Add files to `Sources/CNI/`
2. Update `Sources/CNI/include/CNI.h` if adding new public header
3. Update `README.md` with usage examples
4. Add tests to `Tests/CNITests/`

### Add New Adapter

1. Create directory `Sources/CNI{FrameworkName}/`
2. Add target to `Package.swift`:
   ```swift
   .target(
     name: "CNI{FrameworkName}",
     dependencies: ["CNI"],
     path: "Sources/CNI{FrameworkName}"
   )
   ```
3. Add product to `Package.swift`
4. Update `README.md` with usage examples

### Test Changes Locally

```bash
cd "/Users/macbook/Documents/Personal Work/CNI"

# Build package
swift build

# Run tests (when they exist)
swift test

# Check for issues
swift package diagnose
```

## Resources

**Original Project:**
- Location: `/Users/macbook/Documents/Personal Work/component-kit`
- Integration Guide: `component-kit/CNI_INTEGRATION_GUIDE.md`

**CNI Package:**
- Location: `/Users/macbook/Documents/Personal Work/CNI`
- Git Status: Initialized with initial commit

**Documentation:**
- All .md files in CNI root directory
- Inline code documentation in headers

## Next Session Checklist

When opening CNI in a new session:

1. ✅ Read `PROJECT_CONTEXT.md` (this file)
2. ✅ Check `README.md` for current API
3. ✅ Review `CNI_IMPROVEMENT_PLAN.md` for roadmap
4. ✅ Check git status: `git status`
5. ✅ See what's next in roadmap

## Questions?

If you (or another AI assistant) need to understand:

- **What is CNI?** → Read this file and README.md
- **How to use CNI?** → Read README.md
- **How did we get here?** → Read CNI_SPM_MIGRATION_PLAN.md
- **What's next?** → Read CNI_IMPROVEMENT_PLAN.md
- **How to integrate?** → Read component-kit/CNI_INTEGRATION_GUIDE.md

---

**Document Version:** 1.0
**Created:** 2025-10-05
**Last Updated:** 2025-10-05
**Status:** Phase 1 Complete - SPM Package Created ✅
