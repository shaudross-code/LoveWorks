require 'xcodeproj'
project_path = "App.xcodeproj"
project = Xcodeproj::Project.open(project_path)
project.targets.each do |target|
    target.build_configurations.each do |config|
        config.build_settings['SUPPORTED_PLATFORMS'] = "iphoneos iphonesimulator"
        config.build_settings['TARGETED_DEVICE_FAMILY'] = "1,2"
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = "15.0"
    end
end
project.save
