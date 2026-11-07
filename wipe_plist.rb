require 'xcodeproj'
project_path = "iLoveWorks.xcodeproj"
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Specifically remove the Info.plist duplicate copying which is causing the simulator target to fail
target.copy_files_build_phases.each do |phase|
  phase.files.each do |file|
    if file.file_ref.name == "Info.plist"
      puts "Removing from copy phase: #{file.file_ref.path}"
      file.remove_from_project
    end
  end
end

target.resources_build_phase.files.each do |file|
  next if file.file_ref.nil?
  if file.file_ref.path == "iLoveWorks/Info.plist" || file.file_ref.name == "Info.plist"
    puts "Removing from resources phase: #{file.file_ref.path}"
    file.remove_from_project
  end
end

# Check all phases just in case
target.build_phases.each do |phase|
  phase.files.each do |file|
    next if file.file_ref.nil?
    if file.file_ref.path == "iLoveWorks/Info.plist"
      puts "Removing from phase #{phase.display_name}: #{file.file_ref.path}"
      file.remove_from_project
    end
  end
end

project.save
