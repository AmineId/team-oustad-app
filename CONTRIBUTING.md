# 🤝 Contributing to Team Oustad

## 📋 Conventional Commits

We use [Conventional Commits](https://www.conventionalcommits.org/) for automatic versioning and changelog generation.

### Commit Message Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types

| Type | Description | Version Bump |
|------|-------------|--------------|
| `feat` | New feature | **minor** (1.0.0 → 1.1.0) |
| `fix` | Bug fix | **patch** (1.0.0 → 1.0.1) |
| `perf` | Performance improvement | **patch** |
| `refactor` | Code refactoring | **patch** |
| `docs` | Documentation only | _no release_ |
| `style` | Code style changes | _no release_ |
| `test` | Tests | _no release_ |
| `chore` | Maintenance | _no release_ |
| `ci` | CI/CD changes | _no release_ |
| `build` | Build system | _no release_ |

### Breaking Changes

Add `!` after type or `BREAKING CHANGE:` in footer for **major** version bump (1.0.0 → 2.0.0)

```bash
feat!: redesign authentication flow

BREAKING CHANGE: removed legacy login method
```

## ✍️ Commit Examples

### Features

```bash
# New feature (minor bump)
git commit -m "feat: add dark mode support"
git commit -m "feat(auth): implement biometric login"

# Breaking change (major bump)
git commit -m "feat!: redesign API structure"
```

### Bug Fixes

```bash
# Bug fix (patch bump)
git commit -m "fix: resolve login crash on Android 13"
git commit -m "fix(notifications): correct push token handling"
```

### Performance

```bash
# Performance improvement (patch bump)
git commit -m "perf: optimize image loading"
git commit -m "perf(database): add query caching"
```

### Refactoring

```bash
# Code refactoring (patch bump)
git commit -m "refactor: simplify auth service"
git commit -m "refactor(ui): extract reusable components"
```

### Other Changes

```bash
# Documentation (no release)
git commit -m "docs: update API documentation"

# Code style (no release)
git commit -m "style: format code with dart fmt"

# Tests (no release)
git commit -m "test: add unit tests for auth service"

# CI/CD (no release)
git commit -m "ci: update GitHub Actions workflow"
```

## 🔄 Release Workflow

### Automatic Releases

Semantic Release runs automatically on push to `main` or `staging`:

1. **Analyzes commits** since last release
2. **Determines version** based on commit types
3. **Updates version files** (version-metadata.json, pubspec.yaml)
4. **Generates changelog** (CHANGELOG.md)
5. **Creates GitHub Release** with notes
6. **Builds and uploads APK**
7. **Deploys to OTA server**

### Branch Strategy

- **`main`** → Production releases (1.0.0, 1.0.1, 1.1.0, ...)
- **`staging`** → Beta releases (1.0.0-beta.1, 1.0.0-beta.2, ...)
- **`feature/*`** → Development branches

### Example Workflow

```bash
# 1. Create feature branch
git checkout -b feature/dark-mode

# 2. Make changes with conventional commits
git commit -m "feat: add dark mode toggle in settings"
git commit -m "feat: implement dark theme colors"
git commit -m "test: add dark mode tests"

# 3. Push and create PR
git push origin feature/dark-mode
# Create PR on GitHub

# 4. Merge to staging for beta testing
# → Auto-releases 1.0.0-beta.1
# → Deploys to pprod OTA

# 5. Test beta version

# 6. Merge to main for production
# → Auto-releases 1.1.0 (feat = minor bump)
# → Deploys to prod OTA
# → Creates GitHub Release
```

## 🎯 Best Practices

### ✅ Good Commits

```bash
feat: add offline support
fix: resolve memory leak in image cache
perf: reduce app startup time by 30%
refactor: extract API client into separate service
```

### ❌ Bad Commits

```bash
update stuff
fix bug
wip
changes
```

### Multi-line Commits

```bash
git commit -m "feat: add user profile page

- Add profile photo upload
- Display user statistics
- Add edit profile form
- Implement data validation"
```

### Breaking Changes

```bash
git commit -m "feat!: migrate to new API v2

BREAKING CHANGE: API endpoints have changed.
Old endpoints (/api/v1/*) are no longer supported.
Update client code to use new endpoints (/api/v2/*)."
```

## 📊 Version Examples

Given current version `1.2.3`:

| Commits | New Version | Reason |
|---------|-------------|--------|
| `fix: bug` | 1.2.4 | Patch bump |
| `feat: feature` | 1.3.0 | Minor bump |
| `feat!: breaking` | 2.0.0 | Major bump |
| `fix:` + `feat:` | 1.3.0 | Highest (minor) |
| `docs:` + `style:` | _no release_ | No release types |

## 🔍 Checking What Will Be Released

```bash
# Run semantic-release in dry-run mode
npx semantic-release --dry-run --no-ci

# Or check on GitHub Actions before merging
# The workflow shows what version will be released
```

## 📚 Resources

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Semantic Versioning](https://semver.org/)
- [Angular Commit Guidelines](https://github.com/angular/angular/blob/main/CONTRIBUTING.md#commit)
- [Semantic Release Docs](https://semantic-release.gitbook.io/)

## 🆘 Need Help?

Open an issue or ask in the team chat!
