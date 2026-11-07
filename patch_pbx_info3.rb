require 'xcodeproj'
project_path = "iLoveWorks.xcodeproj"
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Remove from copy phase specifically
target.copy_files_build_phases.each do |phase|
    phase.files.each do |file|
        if file.file_ref && file.file_ref.name == "Info.plist"
            file.remove_from_project
        end
    end
end
target.resources_build_phase.files.each do |file|
    if file.file_ref && file.file_ref.name == "Info.plist"
        file.remove_from_project
    end
end
project.save
