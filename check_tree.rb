require 'xcodeproj'
project_path = "iLoveWorks.xcodeproj"
project = Xcodeproj::Project.open(project_path)

def print_group(group, indent = "")
  group.children.each do |child|
    puts "#{indent}- #{child.name || child.path} (#{child.class})"
    if child.is_a?(Xcodeproj::Project::Object::PBXGroup)
      print_group(child, indent + "  ")
    end
  end
end

print_group(project.main_group)
