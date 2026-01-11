# Swift Package Manager Setup Guide

This guide explains how to make your FlwKit package discoverable and usable via Swift Package Manager.

## Requirements for SPM Discovery

Swift Package Manager requires:
1. ✅ `Package.swift` in the repository root (you have this)
2. ✅ Valid git repository (you have this)
3. ❌ **At least one semantic version tag** (you need to create this)
4. ✅ Compatible swift-tools-version (fixed to 5.9)

## Step-by-Step Setup

### 1. Lower Swift Tools Version (Already Fixed)

The `Package.swift` has been updated to use `swift-tools-version: 5.9` instead of 6.2 for better compatibility.

### 2. Create and Push a Git Tag

SPM **requires** at least one semantic version tag to discover your package. Without tags, SPM returns 0 results.

**Create and push your first version tag:**

```bash
# Make sure all changes are committed
git add .
git commit -m "Prepare for SPM release"

# Create a version tag (use semantic versioning: MAJOR.MINOR.PATCH)
git tag 1.0.0

# Push the tag to GitHub
git push origin 1.0.0

# Also push your commits if you haven't already
git push origin main
```

**Alternative: Create tag via GitHub:**
1. Go to your GitHub repository: https://github.com/FlwKit/flwkit_ios
2. Click "Releases" → "Create a new release"
3. Choose a tag version (e.g., `1.0.0`)
4. Add release title and description
5. Click "Publish release"

### 3. Verify Package Structure

Ensure your repository structure looks like this:
```
flwkit_ios/
├── Package.swift          ← Must be in root
├── Sources/
│   └── FlwKit-ios/       ← Target name matches directory
│       ├── FlwKit.swift
│       ├── Analytics/
│       ├── Core/
│       ├── Networking/
│       └── UI/
└── README.md (optional)
```

### 4. Test Package Discovery

After pushing the tag, test in Xcode:

1. Open Xcode
2. Go to **File** → **Add Package Dependencies...**
3. Enter your repository URL: `https://github.com/FlwKit/flwkit_ios.git`
4. Click "Add Package"
5. You should now see version `1.0.0` available

If it still shows 0 results:
- Wait a few minutes (GitHub may need to index the tag)
- Verify the tag exists: `git ls-remote --tags origin`
- Check the repository URL is correct
- Ensure the repository is public

## Adding the Package to Your App

### In Xcode:

1. **File** → **Add Package Dependencies...**
2. Enter: `https://github.com/FlwKit/flwkit_ios.git`
3. Select version: `Up to Next Major Version` from `1.0.0`
4. Add to your target
5. Import: `import FlwKit_ios`

### In Package.swift (for SPM projects):

```swift
dependencies: [
    .package(url: "https://github.com/FlwKit/flwkit_ios.git", from: "1.0.0")
]
```

## Versioning Best Practices

Use [Semantic Versioning](https://semver.org/):
- **MAJOR** (1.0.0): Breaking changes
- **MINOR** (1.1.0): New features, backward compatible
- **PATCH** (1.0.1): Bug fixes, backward compatible

**Creating new versions:**
```bash
# For a patch release (bug fix)
git tag 1.0.1
git push origin 1.0.1

# For a minor release (new feature)
git tag 1.1.0
git push origin 1.1.0

# For a major release (breaking change)
git tag 2.0.0
git push origin 2.0.0
```

## Troubleshooting

### "No packages found" or "0 results"

**Causes:**
1. ❌ No git tags exist → **Solution:** Create and push a tag
2. ❌ Tag not pushed to remote → **Solution:** `git push origin --tags`
3. ❌ Repository is private → **Solution:** Make it public or use SSH/auth
4. ❌ Package.swift has errors → **Solution:** Check for syntax errors
5. ❌ swift-tools-version too high → **Solution:** Lower to 5.9 (already done)

### "Invalid Package" Error

- Check `Package.swift` syntax
- Ensure target name matches directory name (`FlwKit-ios`)
- Verify all source files are in correct locations

### Package Not Updating

- Clear Xcode's package cache: **File** → **Packages** → **Reset Package Caches**
- Delete `DerivedData` folder
- Try adding package again

## Quick Checklist

Before pushing to GitHub, ensure:
- [x] `Package.swift` is in repository root
- [x] `swift-tools-version` is compatible (5.9)
- [x] All source files are committed
- [x] Repository is pushed to GitHub
- [ ] **Create and push version tag (1.0.0)**
- [ ] Test package discovery in Xcode

## Next Steps

After setting up:
1. Create your first tag (1.0.0)
2. Push to GitHub
3. Test in Xcode
4. Update your integration guide with the GitHub URL
5. Consider adding a README.md with quick start instructions
