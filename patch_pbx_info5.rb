require 'xcodeproj'
project_path = "iLoveWorks.xcodeproj"
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Check all phases
target.build_phases.each do |phase|
  if phase.is_a?(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase) || phase.is_a?(Xcodeproj::Project::Object::PBXResourcesBuildPhase)
    phase.files.each do |file|
      if file.file_ref && file.file_ref.path
        if file.file_ref.path.include?("Info.plist") && !file.file_ref.path.include?("GoogleService-Info.plist") && !file.file_ref.path.include?("Fonts")
            puts "Removing duplicate Info.plist reference from phase: #{phase.display_name}"
            file.remove_from_project
        end
      end
    end
  end
end

project.save
