require 'xcodeproj'
project_path = "iLoveWorks.xcodeproj"
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

target.resources_build_phase.files.each do |file|
  path = file.file_ref.path rescue file.file_ref.name
  puts " - #{path}"
end
