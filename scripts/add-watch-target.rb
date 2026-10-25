#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Ajoute le target watchOS "TeamOustadWatch" au Runner.xcodeproj
# et l'embarque dans le target "Runner" (app iPhone).
#
# Requis en CI macOS : pas de Xcode local en dev (WSL/Windows).
# Idempotent : ne fait rien si le target existe déjà.
#
# Usage : ruby scripts/add-watch-target.rb
#
require 'xcodeproj'

PROJECT_PATH = 'ios/Runner.xcodeproj'
WATCH_NAME   = 'TeamOustadWatch'
DISPLAY_NAME = 'Team Oustad'
WATCH_BUNDLE = 'team.oustad.app.watchkitapp'
WATCH_DIR    = 'TeamOustadWatch'    # relatif à ios/
WATCHOS_MIN  = '7.0'

project = Xcodeproj::Project.open(PROJECT_PATH)

# Idempotent
if project.targets.any? { |t| t.name == WATCH_NAME }
  puts "✅ Target #{WATCH_NAME} existe déjà — rien à faire."
  exit 0
end

# ── 1. Créer le target watchOS app ───────────────────────────────────────────
watch_target = project.new_target(:application, WATCH_NAME, :watchos, WATCHOS_MIN)

# ── 2. Build settings ────────────────────────────────────────────────────────
watch_target.build_configurations.each do |cfg|
  s = cfg.build_settings
  s['PRODUCT_BUNDLE_IDENTIFIER']             = WATCH_BUNDLE
  s['WATCHOS_DEPLOYMENT_TARGET']             = WATCHOS_MIN
  s['SWIFT_VERSION']                         = '5.0'
  s['TARGETED_DEVICE_FAMILY']                = '4'
  s['PRODUCT_NAME']                          = WATCH_NAME
  s['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'YES'
  s['ENABLE_BITCODE']                        = 'NO'
  s['GENERATE_INFOPLIST_FILE']               = 'YES'
  s['INFOPLIST_KEY_CFBundleDisplayName']     = DISPLAY_NAME
  s['ASSETCATALOG_COMPILER_APPICON_NAME']    = 'AppIcon'
  s['INFOPLIST_KEY_WKApplication']           = 'YES'
  s['INFOPLIST_KEY_WKCompanionAppBundleIdentifier'] = 'team.oustad.app'
  s['INFOPLIST_KEY_UISupportedInterfaceOrientations'] = 'UIInterfaceOrientationPortrait'
  s['SDKROOT']                               = 'watchos'
  s['CODE_SIGN_STYLE']                       = 'Automatic'
  s['SWIFT_OPTIMIZATION_LEVEL']              = cfg.name == 'Debug' ? '-Onone' : '-O'
end

# ── 3. Groupes Xcode + fichiers source ───────────────────────────────────────
watch_group = project.main_group.new_group(WATCH_NAME, WATCH_DIR)
views_group = watch_group.new_group('Views', 'Views')

Dir.glob("ios/#{WATCH_DIR}/*.swift").sort.each do |path|
  ref = watch_group.new_reference(File.basename(path))
  watch_target.source_build_phase.add_file_reference(ref)
  puts "  + #{File.basename(path)}"
end

Dir.glob("ios/#{WATCH_DIR}/Views/*.swift").sort.each do |path|
  ref = views_group.new_reference(File.basename(path))
  watch_target.source_build_phase.add_file_reference(ref)
  puts "  + Views/#{File.basename(path)}"
end

# Icône de l'app montre (catalogue d'assets, icône watchOS 1024 unique)
assets_path = "ios/#{WATCH_DIR}/Assets.xcassets"
abort("❌ #{assets_path} introuvable") unless File.directory?(assets_path)
assets_ref = watch_group.new_reference('Assets.xcassets')
watch_target.resources_build_phase.add_file_reference(assets_ref)
puts '  + Assets.xcassets (AppIcon)'

# ── 4. Embarquer le Watch app dans Runner ────────────────────────────────────
runner = project.targets.find { |t| t.name == 'Runner' }
abort("❌ Target 'Runner' non trouvé") unless runner

embed_phase = project.new(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase)
embed_phase.name               = 'Embed Watch Content'
embed_phase.dst_subfolder_spec = '16'
embed_phase.dst_path           = '$(CONTENTS_FOLDER_PATH)/Watch'

build_file            = project.new(Xcodeproj::Project::Object::PBXBuildFile)
build_file.file_ref   = watch_target.product_reference
build_file.settings   = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
embed_phase.files    << build_file

# Insérer AVANT "Thin Binary" (phase Flutter) pour éviter le cycle de build Xcode 15/16 :
# copy → dépend de Thin Binary → dépend de Info.plist → dépend de copy (cycle)
thin_idx = runner.build_phases.index { |p| p.respond_to?(:name) && p.name == 'Thin Binary' }
if thin_idx
  runner.build_phases.insert(thin_idx, embed_phase)
else
  runner.build_phases << embed_phase
end

project.save
puts "✅ #{WATCH_NAME} ajouté et embarqué dans Runner → #{PROJECT_PATH}"
