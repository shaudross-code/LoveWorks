require 'xcodeproj'
project_path = "iLoveWorks.xcodeproj"
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Just purge ALL Info.plist files from the build phases except GoogleService
target.build_phases.each do |phase|
  phase.files.each do |file|
    if file.file_ref && file.file_ref.name == "Info.plist"
      file.remove_from_project
    elsif file.file_ref && file.file_ref.path && file.file_ref.path.end_with?("Info.plist") && !file.file_ref.path.end_with?("GoogleService-Info.plist")
      file.remove_from_project
    end
  end
end
project.save
