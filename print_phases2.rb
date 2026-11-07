require 'xcodeproj'
project_path = "iLoveWorks.xcodeproj"
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

target.build_phases.each do |phase|
  puts "PHASE: #{phase.display_name} (#{phase.class})"
  phase.files.each do |file|
    if file.file_ref
      name = file.file_ref.display_name rescue "unknown"
      path = file.file_ref.path rescue "unknown"
      puts " - name:#{name} path:#{path}"
    else
      puts " - NULL FILE REF #{file.inspect}"
    end
  end
end
