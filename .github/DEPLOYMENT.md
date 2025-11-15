# GitHub Actions Secrets Configuration for OTA Deployment

## 🔐 Required Secrets

Add these secrets in: **Settings → Secrets and variables → Actions → New repository secret**

### OTA API Authentication

```
OTA_BEARER_TOKEN
```
- **Description**: JWT Bearer token for OTA API authentication
- **Value**: JWT token from admin/owner account (e.g., `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`)
- **How to get**: 
  1. Login via API: `POST /auth/login` with admin credentials
  2. Copy the `token` field from the response
  3. Token is long-lived but regenerate if expired
- **Security**: Keep this token secure and rotate periodically

## 📋 Environments Configuration

### Setup Environments

Go to: **Settings → Environments**

#### 1. Production Environment
- **Name**: `production`
- **Protection rules**:
  - ✅ Required reviewers (recommended)
  - ✅ Wait timer: 5 minutes (optional)
- **Deployment branches**: Only `main`

#### 2. Beta Environment
- **Name**: `beta`
- **Protection rules**: None (auto-deploy)
- **Deployment branches**: Only `staging`

## 🚀 Workflow Triggers

### Version Bump Workflow

**Actions → Update Version Metadata → Run workflow**

1. Go to GitHub Actions
2. Select "Update Version Metadata"
3. Click "Run workflow"
4. Fill in:
   - **Bump type**: patch/minor/major
   - **Changelog**: Description of changes
   - **Mandatory**: Is update required?
   - **New features**: Comma-separated list
   - **Improvements**: Comma-separated list
   - **Bug fixes**: Comma-separated list
5. Click "Run workflow"

This will:
- ✅ Increment version automatically
- ✅ Update `version-metadata.json`
- ✅ Update `pubspec.yaml`
- ✅ Create a Pull Request
- ✅ Generate release notes

### Automatic Triggers

1. **Production Release** (main branch)
   ```bash
   git push origin main
   ```
   - Builds production APK
   - Deploys to production OTA server
   - Creates GitHub Release
   - Version: `1.0.0` (from version-metadata.json)

2. **Beta Release** (staging branch)
   ```bash
   git push origin staging
   ```
   - Builds beta APK
   - Deploys to pre-production OTA server
   - Version: `1.0.0-beta` (auto-suffixed)

### Manual Trigger

Go to: **Actions → Android OTA Release → Run workflow**

Select:
- Branch: `main` or `staging`
- Environment: `production` or `beta`

## 📦 Version Management Workflow

### Standard Release Process (GitHub Actions)

```bash
# 1. Create new feature
git checkout -b feature/new-feature
# ... make changes ...
git push origin feature/new-feature

# 2. Use GitHub Actions to bump version
# Go to: Actions → Update Version Metadata → Run workflow
# - Bump type: patch
# - Changelog: "New feature beta"
# - Fill in release notes
# → Creates PR with version bump

# 3. Merge version bump PR
# Review and merge the auto-generated PR

# 4. Merge to staging for beta testing
git checkout staging
git merge main  # or merge the feature branch
git push origin staging
# → GitHub Actions builds and deploys to beta (pprod)

# 5. Test beta version
# Users with beta app get update notification

# 6. If stable, merge to main for production
git checkout main
git merge staging

# 7. Update version (remove -beta suffix if added by CI)
# Edit version-metadata.json if needed

# 8. Push to trigger production release
git push origin main
# → GitHub Actions builds, deploys, and creates GitHub Release

# 9. Create Git tag (optional, done by CI)
git tag v1.0.1
git push origin v1.0.1
```

## 🔄 CI/CD Pipeline Flow

```
┌─────────────────┐
│  Push to Branch │
└────────┬────────┘
         │
         ├─────────────────┬──────────────────┐
         │                 │                  │
    ┌────▼─────┐      ┌───▼────┐       ┌────▼────┐
    │   Main   │      │ Staging│       │ Manual  │
    │(Prod)    │      │ (Beta) │       │Dispatch │
    └────┬─────┘      └───┬────┘       └────┬────┘
         │                │                  │
         └────────────────┴──────────────────┘
                          │
              ┌───────────▼──────────┐
              │  Prepare Environment │
              │  - Detect branch     │
              │  - Read metadata     │
              │  - Set beta flag     │
              └───────────┬──────────┘
                          │
                  ┌───────▼────────┐
                  │  Build APK     │
                  │  - Setup tools │
                  │  - Configure   │
                  │  - Build       │
                  │  - Upload      │
                  └───────┬────────┘
                          │
                  ┌───────▼────────┐
                  │  Deploy OTA    │
                  │  - SSH to VPS  │
                  │  - Upload APK  │
                  │  - Run script  │
                  │  - Verify      │
                  └───────┬────────┘
                          │
         ┌────────────────┴────────────────┐
         │                                 │
    ┌────▼─────┐                  ┌───────▼────────┐
    │  Release │ (main only)      │   Notify       │
    │  - GitHub│                  │  - Summary     │
    │  - Tag   │                  │  - Links       │
    │  - Notes │                  │  - Status      │
    └──────────┘                  └────────────────┘
```

## 🧪 Testing the Workflow

### Local Testing (Before Pushing)

```bash
# 1. Bump version locally
./bump-version.ps1 -Type patch -Changelog "Test release"

# 2. Build locally to verify
flutter build apk --release --dart-define=ENVIRONMENT=pprod

# 3. Check generated APK
ls -lh build/app/outputs/flutter-apk/

# 4. Verify version-metadata.json
cat version-metadata.json
```

### Test Beta Release

```bash
# Push to staging
git checkout staging
./bump-version.ps1 -Type patch -Changelog "Beta test"
git add .
git commit -m "Bump version for beta"
git push origin staging

# Monitor workflow
# Go to: Actions → Android OTA Release

# Verify deployment
curl https://app.team-oustad.com/android/version.json
```

## 📊 Monitoring Deployments

### GitHub Actions Dashboard

**Actions → Android OTA Release**

Check:
- ✅ Build status
- ✅ Deployment logs
- ✅ APK artifacts
- ✅ Release creation

### Server Verification

```bash
# Check deployed version
curl https://app.team-oustad.com/android/version.json

# Check APK availability
curl -I https://app.team-oustad.com/android/download

# Check server logs (SSH to server)
ssh root@51.178.41.135
pm2 logs teamfitness-preprod
tail -f /var/log/nginx/access.log
```

## 🆘 Troubleshooting

### Build Failures

**Error: Flutter SDK not found**
- Check `FLUTTER_VERSION` in workflow file
- Verify Flutter is properly cached

**Error: google-services.json missing**
- Ensure `google-services-pprod.json` and `google-services-prod.json` exist
- Check file paths in workflow

### Deployment Failures

**Error: Upload failed with status 401**
- Verify `OTA_BEARER_TOKEN` secret is correct and not expired
- Test token validity:
  ```bash
  curl -X GET https://app.team-oustad.com/auth/me \
    -H "Authorization: Bearer YOUR_TOKEN"
  ```
- If expired, regenerate token by logging in again

**Error: Upload failed with status 403**
- Check that the token belongs to an account with proper permissions (admin/owner)
- Verify the API endpoint is accessible from GitHub Actions
- Ensure the token hasn't been revoked

**Error: Upload failed with status 400**
- Check that all required fields are present in the upload
- Verify APK file is valid and not corrupted
- Check multipart/form-data formatting

### Version Mismatch

**Deployed version doesn't match expected**
- Check `version-metadata.json` was committed
- Verify pubspec.yaml was updated
- Wait a few seconds after deployment for API to update

## 🎯 Best Practices

1. **Always test in staging first**
   ```bash
   git checkout staging
   # test changes
   git checkout main
   git merge staging  # only after testing
   ```

2. **Use semantic versioning**
   - Major: Breaking changes (1.0.0 → 2.0.0)
   - Minor: New features (1.0.0 → 1.1.0)
   - Patch: Bug fixes (1.0.0 → 1.0.1)

3. **Write clear changelogs**
   ```bash
   ./bump-version.ps1 -Type patch -Changelog "
   - Fixed login issue
   - Improved performance
   - Updated dependencies
   "
   ```

4. **Monitor deployments**
   - Check GitHub Actions logs
   - Verify API responses
   - Test with real devices

5. **Keep secrets secure**
   - Never commit SSH keys
   - Rotate keys periodically
   - Use environment-specific secrets

## 🔗 Related Documentation

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [GitHub Environments](https://docs.github.com/en/actions/deployment/targeting-different-environments)
- [OTA Setup Guide](../ANDROID_OTA_SETUP_COMPLETE.md)
- [Version Management](../version-metadata.json)
