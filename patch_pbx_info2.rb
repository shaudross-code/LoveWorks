require 'xcodeproj'
project_path = "iLoveWorks.xcodeproj"
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Just remove the explicit Info.plist file reference entirely (Xcode automatically processes it based on INFOPLIST_FILE build setting)
file_ref = project.main_group.find_subpath("iLoveWorks/Info.plist")
if file_ref
  # Remove from any build phases first
  target.build_phases.each do |phase|
    phase.remove_file_reference(file_ref)
  end
end

project.save
