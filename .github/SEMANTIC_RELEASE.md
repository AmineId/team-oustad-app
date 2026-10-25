# 🚀 Semantic Release with Conventional Commits

## 📝 Overview

Team Oustad uses **Semantic Release** with **Conventional Commits** for automatic versioning and deployment.

### Key Benefits
- ✅ **Automatic version bumping** based on commit messages
- ✅ **Automatic changelog generation** 
- ✅ **Automatic GitHub releases**
- ✅ **Automatic OTA deployment**
- ✅ **No manual version management**

## 🔧 Setup

### 1. Install Dependencies

```bash
npm install
```

This installs semantic-release and related packages (see `package.json`).

### 2. Configure GitHub Secrets

Navigate to **Settings → Secrets and variables → Actions** and add:

| Secret | Value | Description |
|--------|-------|-------------|
| `OTA_BEARER_TOKEN` | `eyJhbGciOiJIUzI1NiIs...` | JWT Bearer token for OTA API authentication |

**How to get the Bearer token:**
1. Login to your admin account via API or app
2. Copy the JWT token from the response
3. Add it as a secret in GitHub Actions
4. Tokens are long-lived but regenerate if needed

### 3. Create GitHub Environments

Navigate to **Settings → Environments** and create:

- **`production`** (requires reviewers, protected by `main` branch)
- **`beta`** (auto-deploy, protected by `staging` branch)

## 📋 Commit Message Format

Use **Conventional Commits** format:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Commit Types and Version Impact

| Type | Description | Version Bump | Example |
|------|-------------|--------------|---------|
| `feat` | New feature | **minor** (1.0.0 → 1.1.0) | `feat: add dark mode` |
| `fix` | Bug fix | **patch** (1.0.0 → 1.0.1) | `fix: resolve crash` |
| `perf` | Performance | **patch** | `perf: optimize loading` |
| `refactor` | Code refactor | **patch** | `refactor: simplify auth` |
| `feat!` or `BREAKING CHANGE:` | Breaking change | **major** (1.0.0 → 2.0.0) | `feat!: redesign API` |
| `docs` | Documentation | _no release_ | `docs: update README` |
| `style` | Code style | _no release_ | `style: format code` |
| `test` | Tests | _no release_ | `test: add unit tests` |
| `chore` | Maintenance | _no release_ | `chore: update deps` |
| `ci` | CI/CD | _no release_ | `ci: fix workflow` |

### Examples

```bash
# Feature (minor bump: 1.0.0 → 1.1.0)
git commit -m "feat: add biometric authentication"
git commit -m "feat(auth): implement social login"

# Bug fix (patch bump: 1.0.0 → 1.0.1)
git commit -m "fix: resolve memory leak in image cache"
git commit -m "fix(notifications): correct push token handling"

# Performance (patch bump)
git commit -m "perf: reduce app startup time by 30%"

# Breaking change (major bump: 1.0.0 → 2.0.0)
git commit -m "feat!: migrate to new API v2

BREAKING CHANGE: Old API endpoints are no longer supported."

# Multiple changes
git commit -m "feat: add offline mode

- Add local database sync
- Implement conflict resolution
- Add offline indicator"

# No release
git commit -m "docs: update contributing guide"
git commit -m "test: add integration tests"
git commit -m "chore: update dependencies"
```

## 🔄 Release Workflow

### Automatic Releases on Push

When you push to `main` or `staging`, semantic-release:

1. **Analyzes commits** since last release
2. **Determines next version** (major/minor/patch)
3. **Updates files:**
   - `version-metadata.json`
   - `pubspec.yaml`
   - `CHANGELOG.md`
4. **Builds APK** with correct Firebase config
5. **Creates GitHub Release** with generated notes
6. **Deploys to OTA server**

### Branch Strategy

```
feature/dark-mode
    ↓ PR
staging (beta releases: 1.0.0-beta.1, 1.0.0-beta.2)
    ↓ PR (after testing)
main (production releases: 1.0.0, 1.1.0, 2.0.0)
```

### Example Workflow

```bash
# 1. Create feature branch
git checkout -b feature/offline-mode

# 2. Make changes with conventional commits
git add .
git commit -m "feat: add offline data sync"

git add .
git commit -m "feat: implement conflict resolution"

git add .
git commit -m "test: add offline mode tests"

# 3. Push and create PR to staging
git push origin feature/offline-mode
# Create PR on GitHub → merge to staging

# 4. Automatic beta release
# → Analyzes commits: 2 features (minor bump)
# → Version: 1.0.0 → 1.1.0-beta.1
# → Builds APK with pprod Firebase config
# → Deploys to beta OTA server
# → Creates pre-release on GitHub

# 5. Test beta version in pprod environment

# 6. Create PR from staging to main

# 7. Automatic production release
# → Version: 1.1.0-beta.1 → 1.1.0
# → Builds APK with prod Firebase config
# → Deploys to production OTA server
# → Creates GitHub Release
# → Updates CHANGELOG.md
```

## 📊 Version Examples

Given current version `1.2.3`:

| Commits Since Last Release | New Version | Reasoning |
|-----------------------------|-------------|-----------|
| `fix: bug` | 1.2.4 | Patch bump (fix) |
| `feat: feature` | 1.3.0 | Minor bump (feat) |
| `feat!: breaking` | 2.0.0 | Major bump (breaking) |
| `fix: bug` + `feat: feature` | 1.3.0 | Highest applies (minor) |
| `fix: bug` + `feat!: breaking` | 2.0.0 | Highest applies (major) |
| `docs: update` + `style: format` | _no release_ | No release types |
| _no commits_ | _no release_ | Nothing to release |

## 🔍 Preview Next Release

Before merging, check what version will be released:

### Local Dry Run

```bash
# Install dependencies
npm install

# Run semantic-release in dry-run mode
npm run release:dry

# Example output:
# [semantic-release] › ℹ  Analysis of 3 commits complete: minor release
# [semantic-release] › ℹ  The next release version is 1.1.0
```

### GitHub Actions Preview

When you push to a branch, the workflow shows what would be released in the logs.

## 📝 Files Modified by Semantic Release

### Automatic Updates

Semantic-release automatically updates these files:

1. **`version-metadata.json`** - Version, build number, release notes
2. **`pubspec.yaml`** - Flutter version
3. **`CHANGELOG.md`** - Generated changelog with grouped commits

### Commit Created

After a successful release, semantic-release creates a commit:

```
chore(release): 1.1.0 [skip ci]

## [1.1.0](compare/v1.0.0...v1.1.0) (2024-11-15)

### ✨ New Features
* add offline mode support
* implement biometric authentication

### 🐛 Bug Fixes  
* resolve memory leak in cache
```

This commit is automatically pushed to the branch with `[skip ci]` to prevent infinite loops.

## 🆘 Troubleshooting

### No Release Created

**Problem:** Workflow runs but no release is created.

**Cause:** No relevant commits (only `docs`, `style`, `test`, `chore`, etc.)

**Solution:** Ensure at least one commit uses `feat`, `fix`, `perf`, or `refactor`.

### Wrong Version Bump

**Problem:** Expected minor bump but got patch.

**Cause:** Used `fix:` instead of `feat:`

**Solution:** 
- Use `feat:` for new features (minor bump)
- Use `fix:` for bug fixes (patch bump)
- Use `feat!:` or `BREAKING CHANGE:` for breaking changes (major bump)

### Secrets Not Found

**Problem:** `Error: OTA_BEARER_TOKEN secret not found`

**Cause:** Secret not configured in GitHub.

**Solution:** Add the Bearer token in **Settings → Secrets and variables → Actions**.

### APK Not Found for Deployment

**Problem:** Deploy job fails with "artifact not found".

**Cause:** Build failed or artifact name mismatch.

**Solution:** Check build logs in release job.

## 📚 Configuration Files

### `.releaserc.json`

Semantic Release configuration:
- Commit analysis rules
- Changelog generation
- Version file updates
- GitHub Release creation

### `scripts/update-version-metadata.js`

Node.js script that updates:
- `version-metadata.json` with new version
- `pubspec.yaml` with Flutter version
- Parses release notes from semantic-release output

### `.github/workflows/semantic-release.yml`

GitHub Actions workflow that:
- Runs semantic-release
- Builds APK
- Deploys to OTA server

## 📖 Resources

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Semantic Versioning](https://semver.org/)
- [Semantic Release Docs](https://semantic-release.gitbook.io/)
- [CONTRIBUTING.md](../CONTRIBUTING.md) - Detailed commit guidelines

## 🎯 Quick Reference

### Common Commands

```bash
# Preview next release
npm run release:dry

# Force release (local testing only)
npm run release

# Check commit format
git log --oneline --pretty=format:"%s"
```

### Commit Template

```bash
# ~/.gitmessage
# <type>(<scope>): <subject>
#
# <body>
#
# <footer>

# Types: feat, fix, docs, style, refactor, perf, test, chore, ci
# Scope: auth, ui, api, database, etc.
# Breaking: Add ! after type or add BREAKING CHANGE: in footer
```

Set as default template:
```bash
git config --global commit.template ~/.gitmessage
```

## 🚀 Next Steps

1. ✅ Install npm dependencies: `npm install`
2. ✅ Configure GitHub secrets
3. ✅ Create GitHub environments
4. ✅ Read `CONTRIBUTING.md` for detailed guidelines
5. ✅ Start using conventional commits
6. ✅ Push to `staging` to test beta release
7. ✅ Merge to `main` for production release
