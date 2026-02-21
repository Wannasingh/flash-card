require 'xcodeproj'

project_path = 'Flash-Card.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Find or create Configs group
configs_group = project.main_group.find_subpath('Configs', true)

# Find or add Debug.xcconfig
debug_xcconfig = configs_group.files.find { |f| f.path == 'Debug.xcconfig' || f.path == 'Configs/Debug.xcconfig' }
unless debug_xcconfig
  debug_xcconfig = configs_group.new_file('Configs/Debug.xcconfig')
end

# Find or add Release.xcconfig
release_xcconfig = configs_group.files.find { |f| f.path == 'Release.xcconfig' || f.path == 'Configs/Release.xcconfig' }
unless release_xcconfig
  release_xcconfig = configs_group.new_file('Configs/Release.xcconfig')
end

# Apply to Project Configurations
project.build_configurations.each do |config|
  if config.name == 'Debug'
    config.base_configuration_reference = debug_xcconfig
  elsif config.name == 'Release'
    config.base_configuration_reference = release_xcconfig
  end
end

# Apply to Target Configurations
target.build_configurations.each do |config|
  if config.name == 'Debug'
    config.base_configuration_reference = debug_xcconfig
  elsif config.name == 'Release'
    config.base_configuration_reference = release_xcconfig
  end
end

project.save
puts "Successfully linked xcconfig files to the Xcode project and target."
