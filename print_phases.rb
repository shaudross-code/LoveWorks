require 'xcodeproj'
project_path = "iLoveWorks.xcodeproj"
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

target.build_phases.each do |phase|
  puts "PHASE: #{phase.display_name} (#{phase.class})"
  phase.files.each do |file|
    path = file.file_ref.path rescue file.file_ref.name
    puts " - #{path}"
  end
end
