require 'xcodeproj'
project_path = 'Flash-Card.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

views_group = project.main_group.find_subpath(File.join('Flash-Card', 'Views'), true)
if views_group && !views_group.files.find { |f| f.path == 'OnboardingView.swift' }
  file_ref = views_group.new_reference('OnboardingView.swift')
  target.add_file_references([file_ref])
end

services_group = project.main_group.find_subpath(File.join('Flash-Card', 'Services'), true)
if services_group && !services_group.files.find { |f| f.path == 'StoreKitManager.swift' }
  file_ref2 = services_group.new_reference('StoreKitManager.swift')
  target.add_file_references([file_ref2])
end

project.save
