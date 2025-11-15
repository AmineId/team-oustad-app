const fs = require('fs');
const path = require('path');

/**
 * Update version-metadata.json and pubspec.yaml with new version from semantic-release
 * Usage: node update-version-metadata.js <version> <release-notes-file>
 */

const [, , version, releaseNotesFile] = process.argv;

// Read release notes from file if provided
let releaseNotes = '';
if (releaseNotesFile && fs.existsSync(releaseNotesFile)) {
  releaseNotes = fs.readFileSync(releaseNotesFile, 'utf8');
}

if (!version) {
  console.error('❌ Version is required');
  process.exit(1);
}

// Parse version (format: 1.0.0 or 1.0.0-beta.1)
const versionMatch = version.match(/^(\d+)\.(\d+)\.(\d+)(?:-(.+))?$/);
if (!versionMatch) {
  console.error(`❌ Invalid version format: ${version}`);
  process.exit(1);
}

const [, major, minor, patch, prerelease] = versionMatch;
const isPrerelease = !!prerelease;

console.log(`📦 Updating version to: ${version}`);
console.log(`   Type: ${isPrerelease ? 'Prerelease (beta)' : 'Release'}`);

// ────────────────────────────────────────────────────────────────
// 1. Update version-metadata.json
// ────────────────────────────────────────────────────────────────

const metadataPath = path.join(__dirname, '..', 'version-metadata.json');
const metadata = JSON.parse(fs.readFileSync(metadataPath, 'utf8'));

// Increment version code
const oldVersionCode = metadata.version_code;
const newVersionCode = oldVersionCode + 1;

// Parse release notes from semantic-release format
const parseReleaseNotes = (notes) => {
  const sections = {
    new_features: [],
    improvements: [],
    bug_fixes: []
  };

  // Extract sections from markdown
  const featMatch = notes.match(/### ✨ New Features\n\n([\s\S]*?)(?=\n###|\n\n##|$)/);
  const fixMatch = notes.match(/### 🐛 Bug Fixes\n\n([\s\S]*?)(?=\n###|\n\n##|$)/);
  const perfMatch = notes.match(/### ⚡ Performance Improvements\n\n([\s\S]*?)(?=\n###|\n\n##|$)/);
  const refactorMatch = notes.match(/### ♻️ Code Refactoring\n\n([\s\S]*?)(?=\n###|\n\n##|$)/);

  if (featMatch) {
    sections.new_features = featMatch[1]
      .split('\n')
      .filter(line => line.trim().startsWith('*'))
      .map(line => line.replace(/^\*\s+/, '').trim());
  }

  if (fixMatch) {
    sections.bug_fixes = fixMatch[1]
      .split('\n')
      .filter(line => line.trim().startsWith('*'))
      .map(line => line.replace(/^\*\s+/, '').trim());
  }

  if (perfMatch || refactorMatch) {
    const perfLines = perfMatch ? perfMatch[1].split('\n').filter(line => line.trim().startsWith('*')) : [];
    const refactorLines = refactorMatch ? refactorMatch[1].split('\n').filter(line => line.trim().startsWith('*')) : [];
    sections.improvements = [...perfLines, ...refactorLines]
      .map(line => line.replace(/^\*\s+/, '').trim());
  }

  return sections;
};

const releaseNotesData = parseReleaseNotes(releaseNotes);

// Create simple changelog (first line of each section)
const changelog = [
  releaseNotesData.new_features.length > 0 ? `New features: ${releaseNotesData.new_features[0]}` : '',
  releaseNotesData.bug_fixes.length > 0 ? `Bug fixes: ${releaseNotesData.bug_fixes[0]}` : '',
  releaseNotesData.improvements.length > 0 ? `Improvements: ${releaseNotesData.improvements[0]}` : ''
].filter(Boolean).join('\n') || 'Version update';

// Update metadata
metadata.version_name = version;
metadata.version_code = newVersionCode;
metadata.changelog = changelog;
metadata.release_date = new Date().toISOString().split('T')[0];
metadata.build_info.build_date = new Date().toISOString();
metadata.build_info.environment = isPrerelease ? 'pprod' : 'prod';

// Update release notes if available
if (releaseNotesData.new_features.length > 0) {
  metadata.release_notes.new_features = releaseNotesData.new_features;
}
if (releaseNotesData.improvements.length > 0) {
  metadata.release_notes.improvements = releaseNotesData.improvements;
}
if (releaseNotesData.bug_fixes.length > 0) {
  metadata.release_notes.bug_fixes = releaseNotesData.bug_fixes;
}

// Save metadata
fs.writeFileSync(metadataPath, JSON.stringify(metadata, null, 2) + '\n');
console.log(`✅ version-metadata.json updated:`);
console.log(`   Version: ${metadata.version_name}`);
console.log(`   Build: ${oldVersionCode} → ${newVersionCode}`);

// ────────────────────────────────────────────────────────────────
// 2. Update pubspec.yaml
// ────────────────────────────────────────────────────────────────

const pubspecPath = path.join(__dirname, '..', 'pubspec.yaml');
let pubspecContent = fs.readFileSync(pubspecPath, 'utf8');

// Replace version line
pubspecContent = pubspecContent.replace(
  /^version:\s+.+$/m,
  `version: ${version}+${newVersionCode}`
);

fs.writeFileSync(pubspecPath, pubspecContent);
console.log(`✅ pubspec.yaml updated: ${version}+${newVersionCode}`);

console.log('');
console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
console.log('✅ Version files updated successfully!');
console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
