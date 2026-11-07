require 'xcodeproj'
project_path = "iLoveWorks.xcodeproj"
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Fix the duplicate Info.plist error (INFOPLIST_FILE is set properly, it doesn't need to be in the Compile Sources/Resources phase)
target.resources_build_phase.files.each do |file|
    if file.file_ref && (file.file_ref.name == "Info.plist" || file.file_ref.path.include?("Info.plist"))
        unless file.file_ref.name == "GoogleService-Info.plist" || file.file_ref.path.include?("GoogleService-Info.plist") || file.file_ref.path.include?("Fonts/Info.plist")
            puts "Removing duplicate Info.plist from resources bundle"
            file.remove_from_project
        end
    end
end
project.save
