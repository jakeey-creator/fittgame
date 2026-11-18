#!/usr/bin/env ruby
# Erweitert das von Capacitor erzeugte Xcode-Projekt um das native Puls-Plugin und die watchOS-App.
# Einmalig ausgeführt und das Ergebnis eingecheckt; das Skript bleibt als Dokumentation und läuft
# gefahrlos erneut (bereits vorhandene Einträge werden übersprungen).
#   gem install xcodeproj && ruby scripts/add-watch-target.rb
require 'xcodeproj'
Encoding.default_external = Encoding::UTF_8

path = File.expand_path('../ios/App/App.xcodeproj', __dir__)
proj = Xcodeproj::Project.open(path)
app = proj.targets.find { |t| t.name == 'App' } or abort 'Target App nicht gefunden'
BUNDLE = 'com.jakeey.fittgame'

# --- Eine Stelle für die Bundle-ID (Watch-App muss mit der ID der iPhone-App beginnen) ---
proj.build_configurations.each { |c| c.build_settings['FITT_BUNDLE_ID'] ||= BUNDLE }

# --- iPhone-App: Plugin-Dateien + HealthKit-Berechtigung ---
app_group = proj.main_group['App'] or abort 'Gruppe App nicht gefunden'
%w[MainViewController.swift FittPulsePlugin.swift].each do |f|
  next if app_group.files.any? { |r| r.path == f }
  app.source_build_phase.add_file_reference(app_group.new_file(f))
end
app_group.new_file('App.entitlements') unless app_group.files.any? { |r| r.path == 'App.entitlements' }
app.build_configurations.each do |c|
  c.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'App/App.entitlements'
  c.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = '$(FITT_BUNDLE_ID)'
end

# --- watchOS-App ---
unless proj.targets.any? { |t| t.name == 'FittWatch' }
  watch = proj.new_target(:application, 'FittWatch', :watchos, '10.0', nil, :swift)
  group = proj.main_group.new_group('FittWatch', 'FittWatch')
  %w[FittWatchApp.swift WorkoutManager.swift ContentView.swift].each do |f|
    watch.source_build_phase.add_file_reference(group.new_file(f))
  end
  watch.resources_build_phase.add_file_reference(group.new_file('Assets.xcassets'))
  group.new_file('Info.plist')
  group.new_file('FittWatch.entitlements')

  watch.build_configurations.each do |c|
    c.build_settings.merge!(
      'PRODUCT_NAME' => '$(TARGET_NAME)',
      'PRODUCT_BUNDLE_IDENTIFIER' => '$(FITT_BUNDLE_ID).watchkitapp',
      'SDKROOT' => 'watchos',
      'WATCHOS_DEPLOYMENT_TARGET' => '10.0',
      'TARGETED_DEVICE_FAMILY' => '4',
      'SWIFT_VERSION' => '5.0',
      'MARKETING_VERSION' => '1.0',
      'CURRENT_PROJECT_VERSION' => '1',
      'CODE_SIGN_STYLE' => 'Automatic',
      'CODE_SIGN_ENTITLEMENTS' => 'FittWatch/FittWatch.entitlements',
      'GENERATE_INFOPLIST_FILE' => 'YES',
      'INFOPLIST_FILE' => 'FittWatch/Info.plist',
      'INFOPLIST_KEY_CFBundleDisplayName' => 'FITTGAME',
      'INFOPLIST_KEY_WKApplication' => 'YES',
      'INFOPLIST_KEY_WKCompanionAppBundleIdentifier' => '$(FITT_BUNDLE_ID)',
      'INFOPLIST_KEY_NSHealthShareUsageDescription' => 'FITTGAME misst deine Herzfrequenz während des Kurses und zeigt sie live im Spiel an.',
      'INFOPLIST_KEY_NSHealthUpdateUsageDescription' => 'FITTGAME speichert deine Kurse als Trainings in Apple Health.',
      'ASSETCATALOG_COMPILER_APPICON_NAME' => 'AppIcon',
      'ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME' => 'AccentColor',
      'ENABLE_PREVIEWS' => 'YES',
      'SKIP_INSTALL' => 'YES',
      'LD_RUNPATH_SEARCH_PATHS' => ['$(inherited)', '@executable_path/Frameworks']
    )
    c.build_settings.delete('IPHONEOS_DEPLOYMENT_TARGET')
  end

  # Watch-App in die iPhone-App einbetten
  app.add_dependency(watch)
  embed = app.new_copy_files_build_phase('Embed Watch Content')
  embed.dst_subfolder_spec = '16'
  embed.dst_path = '$(CONTENTS_FOLDER_PATH)/Watch'
  bf = embed.add_file_reference(watch.product_reference)
  bf.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
end

proj.save
puts 'Xcode-Projekt aktualisiert.'
