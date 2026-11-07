require 'xcodeproj'
project_path = "iLoveWorks.xcodeproj"
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Force turn off automatic generation to resolve conflict OR just set INFOPLIST_FILE
target.build_configurations.each do |config|
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'NO'
  config.build_settings['INFOPLIST_FILE'] = 'iLoveWorks/Info.plist'
end

project.save
