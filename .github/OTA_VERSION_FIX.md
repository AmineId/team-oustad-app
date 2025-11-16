# OTA Version Synchronization Fix

## 🐛 Problem Description

### Issue
When updating the mobile app through the OTA (Over-The-Air) system, users reported that the installed app kept showing an old build number (e.g., build 5) even after downloading and installing newer versions from the server.

### Root Cause
The problem was caused by a version mismatch between:
1. **The APK's internal version** (embedded during build time from `pubspec.yaml`)
2. **The OTA server's metadata** (from `version-metadata.json`)

#### What Was Happening

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Developer pushes to main/staging                         │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│ 2. Semantic-Release runs                                     │
│    ├─ Analyzes commits                                       │
│    ├─ Determines next version (e.g., 1.0.0-beta.12)        │
│    ├─ Updates pubspec.yaml (version: 1.0.0-beta.12+14)     │
│    ├─ Updates version-metadata.json (version_code: 14)      │
│    └─ Creates commit with updated files                     │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│ 3. Build Job (THE PROBLEM WAS HERE) ❌                       │
│    ├─ Checkout code (ref: original commit)                  │
│    │  └─ pubspec.yaml still has OLD version (e.g., +13)    │
│    ├─ Build APK                                             │
│    │  └─ APK embedded with OLD version 1.0.0-beta.11+13    │
│    └─ Upload artifacts (APK + version-metadata.json)        │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│ 4. Deploy Job                                                │
│    ├─ Download APK (has OLD version 1.0.0-beta.11+13)      │
│    ├─ Download metadata (has NEW version 1.0.0-beta.12+14) │
│    └─ Upload to OTA server                                  │
│       ├─ APK: version_code = 13 (internal) ❌              │
│       └─ Metadata: version_code = 14 ❌                     │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│ 5. User downloads and installs                               │
│    ├─ OTA server says: "New version 14 available"           │
│    ├─ User downloads APK                                     │
│    ├─ Android installs APK                                   │
│    └─ Installed app shows version_code = 13 ❌              │
│       (Because APK was built with old version)               │
└──────────────────────────────────────────────────────────────┘
```

### Why This Happened

The build job was checking out the code using `ref: ${{ github.ref }}`, which refers to the commit that **triggered** the workflow. However, semantic-release creates a **new commit** with the updated version files. The build job wasn't seeing this new commit, so it built the APK with the old version.

## ✅ Solution Implemented

### Changes Made

#### 1. Workflow Enhancement (`.github/workflows/semantic-release.yml`)

##### A. Fetch Latest Semantic-Release Commit
```yaml
- name: 📥 Checkout updated code
  uses: actions/checkout@v4
  with:
    ref: ${{ github.ref }}
    fetch-depth: 0  # ✅ Fetch full history

- name: 🔄 Pull latest changes from semantic-release
  run: |
    git pull origin ${{ github.ref_name }}  # ✅ Get semantic-release commit
```

**Why**: Ensures the build job has the latest version files from semantic-release.

##### B. Pre-Build Version Verification
```yaml
- name: 🔍 Verify version before build
  run: |
    echo "📋 Version information before build:"
    echo "pubspec.yaml version:"
    grep "^version:" pubspec.yaml
    echo "version-metadata.json:"
    cat version-metadata.json | jq '{version_name, version_code}'
```

**Why**: Provides visibility into what versions will be embedded in the APK.

##### C. Post-Build Version Validation
```yaml
- name: 🔍 Extract and verify APK version
  run: |
    # Extract version from APK using aapt
    APK_VERSION_CODE=$(aapt dump badging "$APK_PATH" | grep "versionCode" ...)
    APK_VERSION_NAME=$(aapt dump badging "$APK_PATH" | grep "versionName" ...)
    
    # Compare with metadata
    EXPECTED_VERSION_CODE=$(jq -r '.version_code' version-metadata.json)
    
    # Fail if mismatch
    if [ "$APK_VERSION_CODE" != "$EXPECTED_VERSION_CODE" ]; then
      echo "❌ ERROR: Version code mismatch!"
      exit 1
    fi
```

**Why**: Catches version mismatches early, before deployment. Prevents deploying broken OTA updates.

##### D. Deploy-Time Verification
```yaml
- name: 🔍 Verify APK version before upload
  run: |
    APK_VERSION_CODE=$(aapt dump badging app-release.apk ...)
    echo "📦 APK to be uploaded:"
    echo "   Version Code: $APK_VERSION_CODE"
    echo "📋 Metadata to be uploaded:"
    cat version-metadata.json | jq '{version_name, version_code}'
```

**Why**: Final safety check before uploading to OTA server.

#### 2. Release Notes Enhancement (`.releaserc.json`)

```json
{
  "prepareCmd": "echo '${nextRelease.notes}' > /tmp/release-notes.md && node scripts/update-version-metadata.js ${nextRelease.version} /tmp/release-notes.md"
}
```

**Why**: Ensures `version-metadata.json` gets detailed release notes with proper sections (new features, bug fixes, improvements).

### How It Works Now (Fixed Flow)

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Developer pushes to main/staging                         │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│ 2. Semantic-Release runs                                     │
│    ├─ Analyzes commits                                       │
│    ├─ Determines next version (e.g., 1.0.0-beta.12)        │
│    ├─ Writes release notes to /tmp/release-notes.md         │
│    ├─ Runs update-version-metadata.js                       │
│    │  ├─ Updates pubspec.yaml (1.0.0-beta.12+14)           │
│    │  └─ Updates version-metadata.json (version_code: 14)   │
│    └─ Creates commit "chore(release): 1.0.0-beta.12"       │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│ 3. Build Job ✅ FIXED                                        │
│    ├─ Checkout code (original commit)                       │
│    ├─ Git pull (fetch semantic-release commit) ✅ NEW       │
│    │  └─ Now has pubspec.yaml with NEW version (+14)       │
│    ├─ Show versions before build ✅ NEW                     │
│    │  └─ pubspec.yaml: 1.0.0-beta.12+14                    │
│    ├─ Build APK                                             │
│    │  └─ APK embedded with CORRECT version 1.0.0-beta.12+14│
│    ├─ Extract APK version with aapt ✅ NEW                  │
│    ├─ Validate APK version matches metadata ✅ NEW          │
│    │  └─ ✅ APK: 14 matches metadata: 14                    │
│    └─ Upload artifacts (APK + version-metadata.json)        │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│ 4. Deploy Job                                                │
│    ├─ Download APK (has version 1.0.0-beta.12+14)          │
│    ├─ Download metadata (has version 1.0.0-beta.12+14)     │
│    ├─ Show APK version ✅ NEW                               │
│    │  └─ ✅ APK: version_code = 14                          │
│    └─ Upload to OTA server                                  │
│       ├─ APK: version_code = 14 (internal) ✅              │
│       └─ Metadata: version_code = 14 ✅                     │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│ 5. User downloads and installs ✅                            │
│    ├─ OTA server says: "New version 14 available"           │
│    ├─ User downloads APK (version_code = 14)                │
│    ├─ Android installs APK                                   │
│    └─ Installed app shows version_code = 14 ✅              │
│       (APK was built with correct version)                   │
└──────────────────────────────────────────────────────────────┘
```

## 🧪 Testing the Fix

### Manual Testing

1. **Trigger a Release**
   ```bash
   # Make a feature commit
   git checkout staging
   git commit -m "feat: test OTA version fix"
   git push origin staging
   ```

2. **Monitor Workflow**
   - Go to GitHub Actions
   - Watch the "🚀 Release & Deploy" workflow
   - Check the build logs for version verification steps

3. **Verify Build Logs**
   Look for these new log sections:
   ```
   📋 Version information before build:
   pubspec.yaml version:
   version: 1.0.0-beta.12+14
   
   version-metadata.json:
   {
     "version_name": "1.0.0-beta.12",
     "version_code": 14
   }
   
   ✅ APK Version Information:
      Version Name: 1.0.0-beta.12
      Version Code: 14
   
   ✅ Version verification passed! APK matches metadata.
   ```

4. **Test OTA Update**
   - Install current version on device
   - Open app and check version
   - Trigger update check
   - Download and install update
   - Verify new version number appears

### Automated Checks

The workflow now includes automatic validation that will **fail the build** if:
- APK version code doesn't match metadata version code
- APK version name doesn't match metadata version name

This prevents deploying broken OTA updates.

## 🔍 Debugging

### If Build Fails with Version Mismatch

**Error Message:**
```
❌ ERROR: Version code mismatch!
   APK has version code 13 but metadata expects 14
```

**Possible Causes:**
1. Git pull failed (network issue)
2. Pubspec.yaml wasn't updated by semantic-release
3. Semantic-release didn't run (no commits warranted a release)

**Solution:**
1. Check the "🚀 Run semantic-release" step logs
2. Verify semantic-release created a commit
3. Check if git pull succeeded in build job
4. Manually verify pubspec.yaml was updated

### If OTA Still Shows Wrong Version

**Symptoms:**
- Build succeeds with matching versions
- But installed app shows old version

**Possible Causes:**
1. App is reading version from wrong source
2. Android caching old version info
3. App bundle vs APK confusion

**Solution:**
1. Completely uninstall old version
2. Clear app data and cache
3. Install fresh from OTA
4. Check `PackageInfo.fromPlatform()` in code

## 📊 Verification Checklist

After implementing this fix, verify:

- [ ] Semantic-release creates commit with updated versions
- [ ] Build job pulls latest commit after semantic-release
- [ ] Pre-build logs show correct version in pubspec.yaml
- [ ] Post-build logs show APK has correct version
- [ ] Version validation passes (no errors)
- [ ] Deploy logs show matching versions
- [ ] OTA server has correct metadata
- [ ] Downloaded APK has correct internal version
- [ ] Installed app shows correct version number

## 📚 Related Files

- `.github/workflows/semantic-release.yml` - Main CI/CD workflow
- `.releaserc.json` - Semantic-release configuration
- `scripts/update-version-metadata.js` - Version update script
- `version-metadata.json` - OTA metadata file
- `pubspec.yaml` - Flutter version file
- `android/app/build.gradle.kts` - Android build configuration

## 🎯 Key Takeaways

1. **Always verify versions**: Don't assume the APK has the version you expect
2. **Git pull after semantic-release**: Build jobs need the latest commit
3. **Extract and validate**: Use `aapt` to verify APK contents
4. **Fail fast**: Catch mismatches before deployment
5. **Log everything**: Make debugging easier with detailed logs

## 🚀 Next Steps

1. Monitor first few releases after this fix
2. Verify users receive correct version updates
3. Check OTA server logs for any anomalies
4. Consider adding version checks in the app itself
5. Document any edge cases discovered

---

**Fixed by:** GitHub Copilot Agent  
**Date:** 2025-11-16  
**Related Issue:** OTA version mismatch causing installed app to keep old build number
