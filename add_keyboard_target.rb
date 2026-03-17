require 'xcodeproj'

project_path = 'VOXMOD.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Verify if target exists
if project.targets.find { |t| t.name == 'VOXMODKeyboard' }
  puts "Target VOXMODKeyboard already exists"
  exit 0
end

main_target = project.targets.find { |t| t.name == 'VOXMOD' }
if main_target.nil?
  puts "Main target VOXMOD not found"
  exit 1
end

# Create group for extension if not exists
group = project.main_group.find_subpath('VOXMODKeyboard', true)
group.set_source_tree('<group>')
group.set_path('VOXMODKeyboard')

# Add swift files and Info.plist to group
vc_ref = group.new_reference('KeyboardViewController.swift')
view_ref = group.new_reference('KeyboardView.swift')
info_plist_ref = group.new_reference('Info.plist')

# Create target
ext_target = project.new_target(
  :app_extension,
  'VOXMODKeyboard',
  :ios,
  '17.0',
  project.products_group,
  'en'
)

# Common Build settings
ext_target.build_configurations.each do |config|
  config.build_settings['INFOPLIST_FILE'] = 'VOXMODKeyboard/Info.plist'
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.spazorlabs.VOXMOD.VOXMODKeyboard'
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  config.build_settings['MARKETING_VERSION'] = '1.0'
  config.build_settings['CURRENT_PROJECT_VERSION'] = '1'
end

# Compile sources phase
ext_target.source_build_phase.add_file_reference(vc_ref)
ext_target.source_build_phase.add_file_reference(view_ref)

# Add dependencies to main target
main_target.add_dependency(ext_target)

# Add embed app extensions phase to main target
embed_phase = main_target.new_copy_files_build_phase('Embed App Extensions')
embed_phase.dst_subfolder_spec = '13' # Plugins folder
ext_product_ref = ext_target.product_reference
build_file = embed_phase.add_file_reference(ext_product_ref)
build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }

project.save
puts "Successfully added VOXMODKeyboard target"
